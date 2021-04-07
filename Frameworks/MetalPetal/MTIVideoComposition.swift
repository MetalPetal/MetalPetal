//
//  VideoProcessing.swift
//  MetalPetal
//
//  Created by Yu Ao on 2019/12/19.
//

import Foundation
import AVFoundation

#if SWIFT_PACKAGE
import MetalPetalObjectiveC.Core
#endif

extension MTIImage {
    public func applyingAssetTrackTransform(_ transform: CGAffineTransform) -> MTIImage {
        let transformFilter = MTITransformFilter()
        transformFilter.inputImage = self
        var transform = transform
        transform.tx = 0
        transform.ty = 0
        transformFilter.transform = CATransform3DMakeAffineTransform(transform.inverted())
        transformFilter.viewport = transformFilter.minimumEnclosingViewport
        return transformFilter.outputImage!
    }
}

public protocol MTIAsyncVideoCompositionRequest {
    func sourceFrame(byTrackID trackID: CMPersistentTrackID) -> CVPixelBuffer?
    var renderContext: AVVideoCompositionRenderContext { get }
    var compositionTime: CMTime { get }
    func finish(_ result: Result<CVPixelBuffer, Error>)
}

public protocol MTITrackedAsyncVideoCompositionRequest: MTIAsyncVideoCompositionRequest {
    var isCancelled: Bool { get }
}

extension AVAsynchronousVideoCompositionRequest: MTIAsyncVideoCompositionRequest {
    public func finish(_ result: Result<CVPixelBuffer, Error>) {
        switch result {
        case .failure(let error):
            self.finish(with: error)
        case .success(let pixelBuffer):
            self.finish(withComposedVideoFrame: pixelBuffer)
        }
    }
}

public class MTIAsyncVideoCompositionRequestHandler {
    
    public enum Error: Swift.Error {
        case cannotGenerateOutputPixelBuffer
        case noSourceFrame
    }
    
    public struct Request {
        /// The track's preferred transform is applied.
        public let sourceImages: [CMPersistentTrackID: MTIImage]
        public let compositionTime: CMTime
        public let renderSize: CGSize
        
        public var anySourceImage: MTIImage {
            return sourceImages.first!.value
        }
    }
    
    private let tracks: [AVAssetTrack]
    private let context: MTIContext
    private let filter: (Request) throws -> MTIImage
    private let queue: DispatchQueue?
    
    @available(*, deprecated, message: "Use init(context:tracks:on:filter:) instead.")
    public init(context: MTIContext, tracks: [AVAssetTrack], queue: DispatchQueue = .main, filter: @escaping (Request) throws -> MTIImage) {
        assert(tracks.count > 0)
        self.tracks = tracks
        self.context = context
        self.filter = filter
        self.queue = queue
    }
    
    /// Initialize a new `MTIAsyncVideoCompositionRequestHandler` object that can handle `AVAsynchronousVideoCompositionRequest` on the specified `queue` using `filter`.
    /// If the `queue` is nil.
    public init(context: MTIContext, tracks: [AVAssetTrack], on queue: DispatchQueue?, filter: @escaping (Request) throws -> MTIImage) {
        assert(tracks.count > 0)
        self.tracks = tracks
        self.context = context
        self.filter = filter
        self.queue = queue
    }
    
    private let transformFilter = MTITransformFilter()
    
    private func makeTransformedSourceImage(from request: MTIAsyncVideoCompositionRequest, track: AVAssetTrack) -> MTIImage? {
        guard let pixelBuffer = request.sourceFrame(byTrackID: track.trackID) else {
            return nil
        }
        assert(request.renderContext.renderTransform.isIdentity == true)
        let image = MTIImage(cvPixelBuffer: pixelBuffer, alphaType: .alphaIsOne)
        if track.preferredTransform.isIdentity {
            return image
        }
        transformFilter.inputImage = image
        var transform = track.preferredTransform
        transform.tx = 0
        transform.ty = 0
        transformFilter.transform = CATransform3DMakeAffineTransform(transform.inverted())
        transformFilter.viewport = transformFilter.minimumEnclosingViewport
        return transformFilter.outputImage
    }
    
    private func enqueue(_ operation: @escaping () -> Void) {
        if let queue = self.queue {
            queue.async(execute: operation)
        } else {
            operation()
        }
    }
    
    public func handle(request: MTIAsyncVideoCompositionRequest) {
        if (request as? MTITrackedAsyncVideoCompositionRequest)?.isCancelled == true { return }
        
        let sourceFrames = self.tracks.reduce(into: [CMPersistentTrackID: MTIImage]()) { (frames, track) in
            if let image = self.makeTransformedSourceImage(from: request, track: track) {
                frames[track.trackID] = image
            }
        }
        guard sourceFrames.count > 0 else {
            self.enqueue { request.finish(.failure(Error.noSourceFrame)) }
            return
        }
        guard let pixelBuffer = request.renderContext.newPixelBuffer() else {
            self.enqueue { request.finish(.failure(Error.cannotGenerateOutputPixelBuffer)) }
            return
        }
        self.enqueue {
            do {
                if (request as? MTITrackedAsyncVideoCompositionRequest)?.isCancelled == true { return }
                
                let mtiRequest = Request(sourceImages: sourceFrames, compositionTime: request.compositionTime, renderSize: request.renderContext.size)
                let image = try self.filter(mtiRequest)
                
                if (request as? MTITrackedAsyncVideoCompositionRequest)?.isCancelled == true { return }
                
                try self.context.render(image, to: pixelBuffer)
                
                request.finish(.success(pixelBuffer))
            } catch {
                request.finish(.failure(error))
            }
        }
    }
}


public class MTIVideoComposition {
    
    public enum Error: Swift.Error {
        case unsupportedInstruction
    }
    
    private class Compositor: NSObject, AVVideoCompositing {
        
        class VideoCompositionRequest: Hashable, MTITrackedAsyncVideoCompositionRequest {
            
            private let internalRequest: AVAsynchronousVideoCompositionRequest
            private var completionHandler: (() -> Void)?
            private var _isCancelled: Bool = false
            private let stateLock = MTILockCreate()
            
            func hash(into hasher: inout Hasher) {
                hasher.combine(internalRequest)
            }
            
            static func ==(lhs: VideoCompositionRequest, rhs: VideoCompositionRequest) -> Bool {
                return lhs.internalRequest === rhs.internalRequest
            }
            
            fileprivate init(request: AVAsynchronousVideoCompositionRequest) {
                internalRequest = request
            }
            
            fileprivate func onCompletion(_ completion: @escaping () -> Void) {
                completionHandler = completion
            }
                        
            func sourceFrame(byTrackID trackID: CMPersistentTrackID) -> CVPixelBuffer? {
                internalRequest.sourceFrame(byTrackID: trackID)
            }
            
            var renderContext: AVVideoCompositionRenderContext { internalRequest.renderContext }
            
            var compositionTime: CMTime { internalRequest.compositionTime }
            
            func finish(_ result: Result<CVPixelBuffer, Swift.Error>) {
                stateLock.lock()
                if !_isCancelled {
                    internalRequest.finish(result)
                    let completion = completionHandler
                    completionHandler = nil
                    stateLock.unlock()
                    completion?()
                } else {
                    stateLock.unlock()
                }
            }
            
            fileprivate func cancel() {
                stateLock.lock()
                defer {
                    stateLock.unlock()
                }
                internalRequest.finishCancelledRequest()
                _isCancelled = true
                completionHandler = nil
            }
            
            var isCancelled: Bool {
                stateLock.lock()
                defer {
                    stateLock.unlock()
                }
                return _isCancelled
            }
        }
        
        class Instruction: NSObject, AVVideoCompositionInstructionProtocol {
            
            typealias Handler = (_ request: VideoCompositionRequest) -> Void
            
            let timeRange: CMTimeRange
            
            let enablePostProcessing: Bool = false
            
            let containsTweening: Bool = true
            
            let requiredSourceTrackIDs: [NSValue]? = nil
            
            let passthroughTrackID: CMPersistentTrackID = kCMPersistentTrackID_Invalid
            
            let handler: Handler
            
            init(handler: @escaping Handler, timeRange: CMTimeRange) {
                self.handler = handler
                self.timeRange = timeRange
            }
        }
        
        let sourcePixelBufferAttributes: [String : Any]? = [kCVPixelBufferPixelFormatTypeKey as String: [kCVPixelFormatType_420YpCbCr8BiPlanarFullRange, kCVPixelFormatType_32BGRA, kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange]]
        
        let requiredPixelBufferAttributesForRenderContext: [String : Any] = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        
        private var pendingRequests: Set<VideoCompositionRequest> = []
        private let pendingRequestsLock = MTILockCreate()
        
        func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {
            
        }
        
        func startRequest(_ asyncVideoCompositionRequest: AVAsynchronousVideoCompositionRequest) {
            guard let instruction = asyncVideoCompositionRequest.videoCompositionInstruction as? Instruction else {
                assertionFailure()
                asyncVideoCompositionRequest.finish(with: Error.unsupportedInstruction)
                return
            }
            let request = VideoCompositionRequest(request: asyncVideoCompositionRequest)
            request.onCompletion { [unowned request, weak self] in
                guard let strongSelf = self else { return }
                strongSelf.pendingRequestsLock.lock()
                strongSelf.pendingRequests.remove(request)
                strongSelf.pendingRequestsLock.unlock()
            }
            pendingRequestsLock.lock()
            pendingRequests.insert(request)
            pendingRequestsLock.unlock()
            
            instruction.handler(request)
        }
        
        func cancelAllPendingVideoCompositionRequests() {
            pendingRequestsLock.lock()
            for request in pendingRequests {
                request.cancel()
            }
            pendingRequests = []
            pendingRequestsLock.unlock()
        }
    }
    
    public let asset: AVAsset
    
    @available(iOS 11.0, macOS 10.13, *)
    public var sourceTrackIDForFrameTiming: CMPersistentTrackID {
        get { self.videoComposition.sourceTrackIDForFrameTiming }
        set { self.videoComposition.sourceTrackIDForFrameTiming = newValue }
    }
    
    public var frameDuration: CMTime {
        get { self.videoComposition.frameDuration }
        set { self.videoComposition.frameDuration = newValue }
    }
    
    public var renderSize: CGSize {
        get { self.videoComposition.renderSize }
        set { self.videoComposition.renderSize = newValue }
    }
    
    @available(iOS 11, macOS 10.14, *)
    public var renderScale: Float {
        get { self.videoComposition.renderScale }
        set { self.videoComposition.renderScale = newValue }
    }
    
    private let videoComposition: AVMutableVideoComposition
    
    public func makeAVVideoComposition() -> AVVideoComposition {
        return self.videoComposition.copy() as! AVVideoComposition
    }
    
    public init(asset: AVAsset, context: MTIContext, queue: DispatchQueue?, filter: @escaping (MTIAsyncVideoCompositionRequestHandler.Request) throws -> MTIImage) {
        self.asset = asset.copy() as! AVAsset
        self.videoComposition = AVMutableVideoComposition(propertiesOf: self.asset)
        if let presentationVideoSize = self.asset.presentationVideoSize {
            self.renderSize = presentationVideoSize
        }
        self.videoComposition.customVideoCompositorClass = Compositor.self
        let handler = MTIAsyncVideoCompositionRequestHandler(context: context, tracks: asset.tracks(withMediaType: .video), on: queue, filter: filter)
        self.videoComposition.instructions = [Compositor.Instruction(handler: { request in
            handler.handle(request: request)
        }, timeRange: CMTimeRange(start: .zero, duration: CMTime(value: CMTimeValue.max, timescale: 48000)))]
    }
}

extension AVAsset {
    fileprivate var presentationVideoSize: CGSize? {
        if let videoTrack = self.tracks(withMediaType: AVMediaType.video).first {
            let size = videoTrack.naturalSize.applying(videoTrack.preferredTransform)
            return CGSize(width: abs(size.width), height: abs(size.height))
        }
        return nil
    }
}