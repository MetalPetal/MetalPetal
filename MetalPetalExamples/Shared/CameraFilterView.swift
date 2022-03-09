//
//  CameraFilterView.swift
//  MetalPetalDemo
//
//  Created by YuAo on 2021/4/3.
//

import Foundation
import SwiftUI
import MetalPetal
import VideoIO
import VideoToolbox
import AVKit

class CapturePipeline: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    struct Face {
        var bounds: CGRect
    }
    
    enum Effect: String, Identifiable, CaseIterable {
        case none = "No Filter"
        case grayscale = "Gray Scale"
        case colorHalftone = "Color Halftone"
        case colorGrading = "Color Grading (Color Lookup)"
        case instant = "CIPhotoEffectInstant"
        case bloom = "CIBloom"
        
        #if os(iOS)
        case faceTrackingPixellate = "Face Tracking Pixellate"
        #endif
        
        var id: String { rawValue }
        
        typealias Filter = (MTIImage, [Face]) -> MTIImage
        
        func makeFilter() -> Filter {
            switch self {
            case .none:
                return { image, faces in image }
            case .grayscale:
                return { image, faces in image.adjusting(saturation: 0) }
            case .colorHalftone:
                let filter = MTIColorHalftoneFilter()
                filter.scale = 16
                return { image, faces in
                    filter.inputImage = image
                    return filter.outputImage!
                }
            case .colorGrading:
                let filter = MTIColorLookupFilter()
                filter.inputColorLookupTable = DemoImages.colorLookupTable
                return { image, faces in
                    filter.inputImage = image
                    return filter.outputImage!
                }
            case .instant:
                let filter = MTICoreImageUnaryFilter()
                filter.filter = CIFilter(name: "CIPhotoEffectInstant")
                return { image, faces in
                    filter.inputImage = image
                    return filter.outputImage!
                }
            case .bloom:
                return { image, faces in
                    MTICoreImageKernel.image(byProcessing: [image], using: { inputs in
                        let extent = inputs[0].extent
                        return inputs[0].clampedToExtent().applyingFilter("CIBloom").cropped(to: extent)
                    }, outputDimensions: image.dimensions)
                }
            #if os(iOS)
            case .faceTrackingPixellate:
                return { image, faces in
                    let kernel = MTIPixellateFilter.kernel()
                    var renderCommands: [MTIRenderCommand] = []
                    renderCommands.append(MTIRenderCommand(kernel: .passthrough, geometry: MTIVertices.fullViewportSquare, images: [image], parameters: [:]))
                    for face in faces {
                        let normalizedX = Float(face.bounds.origin.x / image.size.width)
                        let normalizedY = Float(face.bounds.origin.y / image.size.height)
                        let normalizedWidth = Float(face.bounds.width / image.size.width)
                        let normalizedHeight = Float(face.bounds.height / image.size.height)
                        let vertices = MTIVertices(vertices: [
                            MTIVertex(x: normalizedX * 2 - 1, y: (1.0 - normalizedY - normalizedHeight) * 2 - 1, z: 0, w: 1, u: normalizedX, v: normalizedY + normalizedHeight),
                            MTIVertex(x: (normalizedX + normalizedWidth) * 2 - 1, y: (1.0 - normalizedY - normalizedHeight) * 2 - 1, z: 0, w: 1, u: normalizedX + normalizedWidth, v: normalizedY + normalizedHeight),
                            MTIVertex(x: normalizedX * 2 - 1, y: (1.0 - normalizedY) * 2 - 1, z: 0, w: 1, u: normalizedX, v: normalizedY),
                            MTIVertex(x: (normalizedX + normalizedWidth) * 2 - 1, y: (1.0 - normalizedY) * 2 - 1, z: 0, w: 1, u: normalizedX + normalizedWidth, v: normalizedY),
                        ], primitiveType: .triangleStrip)
                        let faceRenderCommand = MTIRenderCommand(kernel: kernel, geometry: vertices, images: [image], parameters: ["scale": SIMD2<Float>(30, 30)])
                        renderCommands.append(faceRenderCommand)
                    }
                    return MTIRenderCommand.images(byPerforming: renderCommands, outputDescriptors: [MTIRenderPassOutputDescriptor(dimensions: image.dimensions, pixelFormat: .unspecified)])[0]
                }
            #endif
            }
        }
    }
    
    struct State {
        var isRecording: Bool = false
        var isVideoMirrored: Bool = true
    }
    
    @Published private var stateChangeCount: Int = 0
    
    private var _state: State = State()
    
    private let stateLock = MTILockCreate()
    
    private(set) var state: State {
        get {
            stateLock.lock()
            defer {
                stateLock.unlock()
            }
            return _state
        }
        set {
            stateLock.lock()
            defer {
                stateLock.unlock()
             
                //ensure that the state update happens on main thread.
                dispatchPrecondition(condition: .onQueue(.main))
                stateChangeCount += 1
            }
            _state = newValue
        }
    }
    
    @Published var previewImage: CGImage?
    
    private let renderContext = try! MTIContext(device: MTLCreateSystemDefaultDevice()!)
    
    private let queue: DispatchQueue = DispatchQueue(label: "org.metalpetal.capture")
    
    private let camera: Camera = {
        var configurator = Camera.Configurator()
        #if os(iOS)
        let interfaceOrientation = UIApplication.shared.windows.first(where: { $0.windowScene != nil })?.windowScene?.interfaceOrientation
        #endif
        configurator.videoConnectionConfigurator = { camera, connection in
            #if os(iOS)
            switch interfaceOrientation {
            case .landscapeLeft:
                connection.videoOrientation = .landscapeLeft
            case .landscapeRight:
                connection.videoOrientation = .landscapeRight
            case .portraitUpsideDown:
                connection.videoOrientation = .portraitUpsideDown
            default:
                connection.videoOrientation = .portrait
            }
            #else
            connection.videoOrientation = .portrait
            #endif
        }
        return Camera(captureSessionPreset: .hd1280x720, defaultCameraPosition: .front, configurator: configurator)
    }()
    
    private let imageRenderer = PixelBufferPoolBackedImageRenderer()
    
    private var filter: Effect.Filter = { image, faces in image }
    
    private var faces: [Face] = []
    
    private var isMetadataOutputEnabled: Bool = false
    
    private var recorder: MovieRecorder?
    
    @Published var effect: Effect = .none {
        didSet {
            let filter = effect.makeFilter()
            let currentEffect = effect
            queue.async {
                #if os(iOS)
                if currentEffect == .faceTrackingPixellate && !self.isMetadataOutputEnabled {
                    self.camera.stopRunningCaptureSession()
                    try? self.camera.enableMetadataOutput(for: [.face], on: self.queue, delegate: self)
                    self.camera.startRunningCaptureSession()
                    self.isMetadataOutputEnabled = true
                }
                #endif
                self.filter = filter
            }
        }
    }
    
    override init() {
        super.init()
        try? self.camera.enableVideoDataOutput(on: queue, delegate: self)
        try? self.camera.enableAudioDataOutput(on: queue, delegate: self)
        self.camera.videoDataOutput?.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
    }
    
    func startRunningCaptureSession() {
        queue.async {
            self.camera.startRunningCaptureSession()
        }
    }
    
    func stopRunningCaptureSession() {
        queue.async {
            self.camera.stopRunningCaptureSession()
        }
    }
    
    func startRecording() throws {
        let sessionID = UUID()
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(sessionID.uuidString).mp4")
        // record audio when permission is given
        let hasAudio = self.camera.audioDataOutput != nil
        let recorder = try MovieRecorder(url: url, configuration: MovieRecorder.Configuration(hasAudio: hasAudio))
        state.isRecording = true
        queue.async {
            self.recorder = recorder
        }
    }
    
    func stopRecording(completion: @escaping (Result<URL, Error>) -> Void) {
        if let recorder = recorder {
            recorder.stopRecording(completion: { error in
                self.state.isRecording = false
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(recorder.url))
                }
            })
            queue.async {
                self.recorder = nil
            }
        }
    }
    
    func toggleVideoMirrored() {
        self.state.isVideoMirrored = !self.state.isVideoMirrored
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let formatDescription = sampleBuffer.formatDescription else {
            return
        }
        switch formatDescription.mediaType {
        case .audio:
            do {
                try self.recorder?.appendSampleBuffer(sampleBuffer)
            } catch {
                print(error)
            }
        case .video:
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            do {
                let image = MTIImage(cvPixelBuffer: pixelBuffer, alphaType: .alphaIsOne)
                let filterOutputImage = self.filter(image, faces)
                let outputImage = self.state.isVideoMirrored ? filterOutputImage.oriented(.upMirrored) : filterOutputImage
                let renderOutput = try self.imageRenderer.render(outputImage, using: renderContext)
                try self.recorder?.appendSampleBuffer(SampleBufferUtilities.makeSampleBufferByReplacingImageBuffer(of: sampleBuffer, with: renderOutput.pixelBuffer)!)
                DispatchQueue.main.async {
                    self.previewImage = renderOutput.cgImage
                }
            } catch {
                print(error)
            }
        default:
            break
        }
    }
}

#if os(iOS)

extension CapturePipeline: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        var faces = [Face]()
        for faceMetadataObject in metadataObjects.compactMap({ $0 as? AVMetadataFaceObject}) {
            if let rect = self.camera.videoDataOutput?.outputRectConverted(fromMetadataOutputRect: faceMetadataObject.bounds) {
                faces.append(Face(bounds: rect.insetBy(dx: -rect.width/4, dy: -rect.height/4)))
            }
        }
        self.faces = faces
    }
}

#endif


struct CameraFilterView: View {
    @StateObject private var capturePipeline = CapturePipeline()
    
    @State private var isRecordButtonEnabled: Bool = true
    @State private var isVideoPlayerPresented: Bool = false
    
    @State private var error: Error?
    @State private var videoPlayer: AVPlayer?
    
    var body: some View {
        ZStack {
            VStack {
                Group {
                    if let cgImage = capturePipeline.previewImage {
                        Image(cgImage: cgImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        cameraUnavailableView
                    }
                }
                .overlay(controlsView)
                
                Button(capturePipeline.state.isRecording ? "Stop Recording" : "Start Recording", action: {
                    if capturePipeline.state.isRecording {
                        isRecordButtonEnabled = false
                        capturePipeline.stopRecording(completion: { result in
                            isRecordButtonEnabled = true
                            switch result {
                            case .success(let url):
                                videoPlayer = AVPlayer(url: url)
                                isVideoPlayerPresented = true
                            case .failure(let error):
                                showError(error)
                            }
                        })
                    } else {
                        videoPlayer = nil
                        isVideoPlayerPresented = false
                        do {
                            try capturePipeline.startRecording()
                        } catch {
                            showError(error)
                        }
                    }
                })
                .disabled(!isRecordButtonEnabled)
                .roundedRectangleButtonStyle()
                .largeControlSize()
                .padding()
            }
            
            if let error = self.error {
                Text(error.localizedDescription)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10)
                                    .foregroundColor(Color.black.opacity(0.7)))
            }
        }
        .onAppear(perform: {
            capturePipeline.startRunningCaptureSession()
        })
        .onDisappear(perform: {
            capturePipeline.stopRunningCaptureSession()
        })
        .sheet(isPresented: $isVideoPlayerPresented, content: {
            if let player = videoPlayer {
                VideoPlayer(player: player).onAppear(perform: {
                    player.play()
                })
                .frame(minHeight: 480)
                .overlay(videoPlayerOverlay)
            }
        })
        .toolbar(content: { Spacer() })
        .inlineNavigationBarTitle("Camera")
    }
    
    private func showError(_ error: Error) {
        withAnimation {
            isRecordButtonEnabled = false
            self.error = error
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
            withAnimation {
                isRecordButtonEnabled = true
                self.error = nil
            }
        })
    }
    
    private var videoPlayerOverlay: some View {
        VStack {
            HStack {
                Button("Dismiss", action: {
                    isVideoPlayerPresented = false
                }).roundedRectangleButtonStyle()
                Spacer()
            }
            Spacer()
        }.padding()
    }
    
    private var controlsView: some View {
        VStack(alignment: .trailing) {
            HStack {
                Spacer()
                
                Picker(selection: $capturePipeline.effect, label: Text(effectPickerLabel), content: {
                    ForEach(CapturePipeline.Effect.allCases) { effect in
                        Text(effect.rawValue).tag(effect)
                    }
                })
                .scaledToFit()
                .pickerStyle(MenuPickerStyle())
                .roundedRectangleButtonStyle()
                .largeControlSize()
                .animation(.none)
                
                Button(action: { [capturePipeline] in
                    capturePipeline.toggleVideoMirrored()
                }, label: { Image(systemName: "arrow.left.and.right.righttriangle.left.righttriangle.right")})
                .roundedRectangleButtonStyle()
                .largeControlSize()
            }.padding()
            Spacer()
        }
    }
    
    private var effectPickerLabel: String {
        #if os(iOS)
        return capturePipeline.effect.rawValue
        #else
        return ""
        #endif
    }
    
    private var cameraUnavailableView: some View {
        Rectangle()
            .foregroundColor(Color.gray.opacity(0.5))
            .aspectRatio(CGSize(width: 1, height: 1), contentMode: .fit)
            .overlay(Image(systemName: "video.fill").font(.system(size: 32))
                        .foregroundColor(Color.white.opacity(0.5)))
    }
}

struct CameraFilterView_Previews: PreviewProvider {
    static var previews: some View {
        CameraFilterView()
    }
}
