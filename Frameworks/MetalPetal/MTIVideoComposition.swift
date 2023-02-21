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

public protocol MTIVideoCompositionRequest {
    func sourceFrame(byTrackID trackID: CMPersistentTrackID) -> CVPixelBuffer?
    
    var renderContext: AVVideoCompositionRenderContext { get }
    
    var compositionTime: CMTime { get }
    
    /// Whether the track transform is applied to the source frame.
    var isTrackTransformApplied: Bool { get }
}

public protocol MTIMutableVideoCompositionRequest: MTIVideoCompositionRequest {
    func finish(_ result: Result<CVPixelBuffer, Error>)
}

public protocol MTITrackedVideoCompositionRequest: MTIVideoCompositionRequest {
    /// Whether the request is cancelled. The implementation must be thread-safe.
    var isCancelled: Bool { get }
}

extension AVAsynchronousVideoCompositionRequest: MTIMutableVideoCompositionRequest {
    
    public var isTrackTransformApplied: Bool {
        return false
    }
    
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
    }
    
    public struct Request {
        /// The track's preferred transform is applied.
        public let sourceImages: [CMPersistentTrackID: MTIImage]
        public let compositionTime: CMTime
        public let renderSize: CGSize
        
        public var anySourceImage: MTIImage? {
            return sourceImages.first?.value
        }
    }
    
    private struct Track {
        let id: CMPersistentTrackID
        let preferredTransform: CGAffineTransform
        init(track: AVAssetTrack) {
            self.id = track.trackID
            self.preferredTransform = track.preferredTransform
        }
    }
    
    private let tracks: [Track]
    private let context: MTIContext
    private let filter: (Request) throws -> MTIImage
    private let queue: DispatchQueue?
    
    @available(*, deprecated, message: "Use init(context:tracks:on:filter:) instead.")
    public init(context: MTIContext, tracks: [AVAssetTrack], queue: DispatchQueue = .main, filter: @escaping (Request) throws -> MTIImage) {
        assert(tracks.count > 0)
        self.tracks = tracks.map(Track.init(track:))
        self.context = context
        self.filter = filter
        self.queue = queue
    }
    
    /// Initialize a new `MTIAsyncVideoCompositionRequestHandler` object that can handle `MTIMutableVideoCompositionRequest` on the specified `queue` using `filter`.
    /// If the `queue` is nil, the `filter` block runs directly on the queue where `handle(request:)` is called.
    public init(context: MTIContext, tracks: [AVAssetTrack], on queue: DispatchQueue?, filter: @escaping (Request) throws -> MTIImage) {
        assert(tracks.count > 0)
        self.tracks = tracks.map(Track.init(track:))
        self.context = context
        self.filter = filter
        self.queue = queue
    }
    
    private static func makeTransformedSourceImage(from request: MTIMutableVideoCompositionRequest, track: Track) -> MTIImage? {
        guard let pixelBuffer = request.sourceFrame(byTrackID: track.id) else {
            return nil
        }
        assert(request.renderContext.renderTransform.isIdentity == true)
        let image = MTIImage(cvPixelBuffer: pixelBuffer, alphaType: .alphaIsOne)
        if request.isTrackTransformApplied || track.preferredTransform.isIdentity {
            return image
        }
        var trackTransform = track.preferredTransform
        trackTransform.tx = 0
        trackTransform.ty = 0
        let transform = CATransform3DMakeAffineTransform(trackTransform.inverted())
        return MTITransformFilterApplyTransformToImage(image, transform, 0, 1, MTITransformFilter.minimumEnclosingViewport(for: image, transform: transform, fieldOfView: 0), .unspecified)
    }
    
    private func enqueue(_ operation: @escaping () -> Void) {
        if let queue = self.queue {
            queue.async(execute: operation)
        } else {
            operation()
        }
    }
    
    public func handle(request: MTIMutableVideoCompositionRequest) {
        if (request as? MTITrackedVideoCompositionRequest)?.isCancelled == true { return }
        
        let sourceFrames = self.tracks.reduce(into: [CMPersistentTrackID: MTIImage]()) { (frames, track) in
            if let image = MTIAsyncVideoCompositionRequestHandler.makeTransformedSourceImage(from: request, track: track) {
                frames[track.id] = image
            }
        }
        guard let pixelBuffer = request.renderContext.newPixelBuffer() else {
            self.enqueue { request.finish(.failure(Error.cannotGenerateOutputPixelBuffer)) }
            return
        }
        self.enqueue {
            autoreleasepool {
                do {
                    if (request as? MTITrackedVideoCompositionRequest)?.isCancelled == true { return }
                    
                    let mtiRequest = Request(sourceImages: sourceFrames, compositionTime: request.compositionTime, renderSize: request.renderContext.size)
                    let image = try self.filter(mtiRequest)
                    
                    if (request as? MTITrackedVideoCompositionRequest)?.isCancelled == true { return }
                    
                    try self.context.render(image, to: pixelBuffer)
                    
                    request.finish(.success(pixelBuffer))
                } catch {
                    request.finish(.failure(error))
                }
            }
        }
    }
}


public class MTIVideoComposition {
    
    public enum Error: Swift.Error {
        case unsupportedInstruction
    }
    
    private class Compositor: NSObject, AVVideoCompositing {
        
        class VideoCompositionRequest: Hashable, MTIMutableVideoCompositionRequest, MTITrackedVideoCompositionRequest {
            
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
            
            var isTrackTransformApplied: Bool { return false }
            
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
    
    @available(iOS 11.0, macOS 10.14, *)
    public var renderScale: Float {
        get { self.videoComposition.renderScale }
        set { self.videoComposition.renderScale = newValue }
    }
    
    public var colorPrimaries: String? {
        get { self.videoComposition.colorPrimaries }
        set { self.videoComposition.colorPrimaries = newValue }
    }
    
    public var colorYCbCrMatrix: String? {
        get { self.videoComposition.colorYCbCrMatrix }
        set { self.videoComposition.colorYCbCrMatrix = newValue }
    }
    
    public var colorTransferFunction: String? {
        get { self.videoComposition.colorTransferFunction }
        set { self.videoComposition.colorTransferFunction = newValue }
    }
    
    private let videoComposition: AVMutableVideoComposition
    
    public func makeAVVideoComposition() -> AVVideoComposition {
        return self.videoComposition.copy() as! AVVideoComposition
    }
    
    /// Creates a new instance of `MTIVideoComposition` with values and instructions suitable for presenting and processing the video tracks of the specified asset according to its temporal and geometric properties and those of its tracks.
    ///
    /// For best performance, ensure that the duration and tracks properties of the asset are already loaded before invoking this method.
    ///
    /// The created `MTIVideoComposition` will have the following values for its properties:
    /// - If the asset has exactly one video track, the original timing of the source video track will be used. If the asset has more than one video track, and the nominal frame rate of any of video tracks is known, the reciprocal of the greatest known nominalFrameRate will be used as the value of frameDuration. Otherwise, a default framerate of 30fps is used.
    /// - If the specified asset is an instance of AVComposition, the renderSize will be set to the naturalSize of the AVComposition; otherwise the renderSize will be set to a value that encompasses all of the asset's video tracks.
    /// - A renderScale of 1.0.
    public init(asset inputAsset: AVAsset, context: MTIContext, queue: DispatchQueue?, filter: @escaping (MTIAsyncVideoCompositionRequestHandler.Request) throws -> MTIImage) {
        asset = inputAsset.copy() as! AVAsset
        videoComposition = AVMutableVideoComposition(propertiesOf: asset)
        let videoTracks = asset.tracks(withMediaType: .video)
        
        /// AVMutableVideoComposition's renderSize property is buggy with some assets. Calculate the renderSize here based on the documentation of `AVMutableVideoComposition(propertiesOf:)`
        if let composition = asset as? AVComposition {
            videoComposition.renderSize = composition.naturalSize
        } else {
            var renderSize: CGSize = .zero
            for videoTrack in videoTracks {
                let size = videoTrack.naturalSize.applying(videoTrack.preferredTransform)
                renderSize.width = max(renderSize.width, abs(size.width))
                renderSize.height = max(renderSize.height, abs(size.height))
            }
            videoComposition.renderSize = renderSize
        }
        
        videoComposition.customVideoCompositorClass = Compositor.self
        let handler = MTIAsyncVideoCompositionRequestHandler(context: context, tracks: videoTracks, on: queue, filter: filter)
        videoComposition.instructions = [Compositor.Instruction(handler: handler.handle(request:), timeRange: CMTimeRange(start: .zero, duration: CMTime(value: CMTimeValue.max, timescale: 48000)))]
    }
}
