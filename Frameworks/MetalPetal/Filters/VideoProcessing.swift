//
//  VideoProcessing.swift
//  MetalPetal
//
//  Created by Yu Ao on 2019/12/19.
//

import Foundation
import AVFoundation

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
    private let queue: DispatchQueue
    
    public init(context: MTIContext, tracks: [AVAssetTrack], queue: DispatchQueue = .main, filter: @escaping (Request) throws -> MTIImage) {
        assert(tracks.count > 0)
        self.tracks = tracks
        self.context = context
        self.filter = filter
        self.queue = queue
    }
    
    private let transformFilter = MTITransformFilter()
    
    private func makeTransformedSourceImage(from request: AVAsynchronousVideoCompositionRequest, track: AVAssetTrack) -> MTIImage? {
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
    
    public func handle(request: AVAsynchronousVideoCompositionRequest) {
        let sourceFrames = self.tracks.reduce(into: [CMPersistentTrackID: MTIImage]()) { (frames, track) in
            if let image = self.makeTransformedSourceImage(from: request, track: track) {
                frames[track.trackID] = image
            }
        }
        if sourceFrames.count == 0 {
            self.queue.async {
                request.finish(with: Error.noSourceFrame)
            }
            return
        }
        if let pixelBuffer = request.renderContext.newPixelBuffer() {
            self.queue.async {
                do {
                    let mtiRequest = Request(sourceImages: sourceFrames, compositionTime: request.compositionTime, renderSize: request.renderContext.size)
                    let image = try self.filter(mtiRequest)
                    try self.context.render(image, to: pixelBuffer)
                    request.finish(withComposedVideoFrame: pixelBuffer)
                } catch {
                    request.finish(with: error)
                }
            }
        } else {
            self.queue.async {
                request.finish(with: Error.cannotGenerateOutputPixelBuffer)
            }
        }
    }
}
