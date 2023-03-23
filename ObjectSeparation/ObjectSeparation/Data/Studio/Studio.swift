//
//  Studio.swift
//  ObjectSeparation
//
//  Created by Horus on 2023/03/04.
//

import AVFoundation
import UIKit
import Photos

enum StudioError: Error {
    case captureSessionInstantiate
    case cannotSetLayerConnection
    case cannotFindAudioDataOutput
    case cannotFindVideoDataOutput
    case cannotFindCamera
}

enum SessionError: Error {
    case cannotAddVideoDeviceInput
    case cannotAddVideoDataOutput
    case cannotAddVideoConnection
    case cannotAddPreviewLayerConnection
    case cannotAddAudioDeviceInput
    case cannotAddAudioDataOutput
    case cannotAddAudioConnection
    case cannotFindVideoConnection
}

enum DeviceError: Error {
    case cannotFindCamera
    case cannotSetupVideoDeviceInput
    case cannotFindVideoDeviceInput
    case cannotFindAudioDeviceInput
    case cannotFindMicrophone
    case cannotSetupAudioDeviceinput
    case cannotFindVideoDeviceInputPort
    case cannotFindAudioDeviceInputPort
}

enum AssetWriterError: Error {
    case assetWriterInstantiate
    case cannotFindAssetWriter
    case cannotFindVideoSetting
    case cannotFindAudioSetting
    case cannotFindVideoTransform
}

enum PhotoLibraryError: Error {
    case cannotCleanUpMovieFile
    case cannotFindBackgroundRecordingID
    case notAuthorized
}

protocol StudioConfigurable {
    func startCaptureSession(on sessionQueue: DispatchQueue, with layer: AVCaptureVideoPreviewLayer, completion: @escaping (Result<Bool, Error>) -> Void)
    func configureCamera(with dataOutputQueue: DispatchQueue, videoPreviewLayer: AVCaptureVideoPreviewLayer, sessionQueue: DispatchQueue, completion: @escaping (Result<Bool, Error>) -> Void)
    func configureMicrophone(with dataOutputQueue: DispatchQueue, sessionQueue: DispatchQueue, completion: @escaping (Result<Bool, Error>) -> Void)
    func startRecording(completion: @escaping (Result<Bool, Error>) -> Void)
    func stopRecording(completion: @escaping (Result<URL, Error>) -> Void)
}

final class DefaultStudio: NSObject, StudioConfigurable {
    
    private var captureSession: AVCaptureSession?
    private var camera: AVCaptureDevice?
    private var microphone: AVCaptureDevice?
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var audioDeviceInput: AVCaptureDeviceInput?
    private var videoDataOutput: AVCaptureVideoDataOutput?
    private var audioDataOutput: AVCaptureAudioDataOutput?
    private var videoTransform: CGAffineTransform?
    private var videoSettings: [String: NSObject]?
    private var audioSettings: [String: NSObject]?
    private var videoPixelFormat: [String: Any]?
    private var assetWriter: AVAssetWriter?
    private var videoAssetWriterInput: AVAssetWriterInput?
    private var audioAssetWriterInput: AVAssetWriterInput?
    private var backgroundRecordingID: UIBackgroundTaskIdentifier?
    private var isRecording: Bool = false
    
    override init() {
        self.captureSession = nil
        self.camera = nil
        self.microphone = nil
        self.videoDeviceInput = nil
        self.audioDeviceInput = nil
        self.videoDataOutput = nil
        self.audioDataOutput = nil
        self.videoTransform = nil
        self.videoSettings = nil
        self.audioSettings = nil
        self.videoPixelFormat = nil
        self.assetWriter = nil
        self.videoAssetWriterInput = nil
        self.audioAssetWriterInput = nil
        self.backgroundRecordingID = nil
    }
    
    func startCaptureSession(on sessionQueue: DispatchQueue, with videoPreviewLayer: AVCaptureVideoPreviewLayer, completion: @escaping (Result<Bool, Error>) -> Void) {
        sessionQueue.async {
            do {
                try self.startCaptureSession()
                try self.setCaptureSession(for: videoPreviewLayer)
                completion(.success(true))
            } catch let error {
                completion(.failure(error))
            }
        }
    }
    
    func configureCamera(with dataOutputQueue: DispatchQueue, videoPreviewLayer: AVCaptureVideoPreviewLayer, sessionQueue: DispatchQueue, completion: @escaping (Result<Bool, Error>) -> Void) {
        sessionQueue.async {
            guard let captureSession = self.captureSession else { return }
            captureSession.beginConfiguration()
            defer {
                captureSession.commitConfiguration()
            }
            do {
                try self.configureVideoDeviceInput()
                try self.addVideoDeviceInput()
                try self.addVideoDataOutput()
                try self.setVideoSampleBufferDelegate(on: dataOutputQueue)
                try self.addVideoConnection()
                try self.addConnection(to: videoPreviewLayer)
                completion(.success(true))
            } catch let error {
                completion(.failure(error))
            }
        }
    }
    
    func configureMicrophone(with dataOutputQueue: DispatchQueue, sessionQueue: DispatchQueue, completion: @escaping (Result<Bool, Error>) -> Void) {
        sessionQueue.async {
            guard let captureSession = self.captureSession else { return }
            captureSession.beginConfiguration()
            defer {
                captureSession.commitConfiguration()
            }
            do {
                try self.configureAudioDeviceInput()
                try self.addAudioDeviceInput()
                try self.addAudioDataOutput()
                try self.setAudioSampleBufferDelegate(on: dataOutputQueue)
                try self.addAudioConnection()
                completion(.success(true))
            } catch let error {
                completion(.failure(error))
            }
        }
    }
    
    func startRecording(completion: @escaping (Result<Bool, Error>) -> Void) {
        do {
            try createVideoSettings()
            try createAudioSettings()
            try createVideoTransform()
            try startRecord()
            completion(.success(true))
        } catch let error {
            completion(.failure(error))
        }
    }
    
    func stopRecording(completion: @escaping (Result<URL, Error>) -> Void) {
        do {
            try stopRecord { url in
                completion(.success(url))
            }
        } catch let error {
            completion(.failure(error))
        }
    }
    
}

// MARK: - Session
extension DefaultStudio {
    private func startCaptureSession() throws {
        captureSession = AVCaptureSession()
        guard let captureSession = captureSession else { throw StudioError.captureSessionInstantiate }
        captureSession.startRunning()
    }
    
    private func setCaptureSession(for layer: AVCaptureVideoPreviewLayer) throws {
        guard let captureSession = captureSession else { throw StudioError.captureSessionInstantiate }
        layer.setSessionWithNoConnection(captureSession)
    }
}

// MARK: - Video
extension DefaultStudio {
    private func configureVideoDeviceInput() throws {
        do {
            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { throw DeviceError.cannotFindCamera }
            self.camera = camera
            videoDeviceInput = try AVCaptureDeviceInput(device: camera)
        } catch {
            throw DeviceError.cannotSetupVideoDeviceInput
        }
    }
    
    private func addVideoDeviceInput() throws {
        guard let videoDeviceInput = videoDeviceInput else { throw DeviceError.cannotFindVideoDeviceInput }
        guard let captureSession = captureSession else { throw StudioError.captureSessionInstantiate }
        if captureSession.canAddInput(videoDeviceInput) {
            captureSession.addInputWithNoConnections(videoDeviceInput)
        } else {
            throw SessionError.cannotAddVideoDeviceInput
        }
    }
    
    private func addVideoDataOutput() throws {
        videoDataOutput = AVCaptureVideoDataOutput()
        guard let captureSession = captureSession else { throw StudioError.captureSessionInstantiate }
        guard let videoDataOutput = videoDataOutput else { throw StudioError.cannotFindVideoDataOutput }
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutputWithNoConnections(videoDataOutput)
        } else {
            throw SessionError.cannotAddVideoDataOutput
        }
    }
    
    private func setVideoSampleBufferDelegate(on dataOutputQueue: DispatchQueue) throws {
        guard let videoDataOutput = videoDataOutput else { throw StudioError.cannotFindVideoDataOutput }
        if videoDataOutput.availableVideoPixelFormatTypes.contains(kCVPixelFormatType_Lossy_32BGRA) {
            videoPixelFormat = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_Lossy_32BGRA)]
        } else if videoDataOutput.availableVideoPixelFormatTypes.contains(kCVPixelFormatType_Lossless_32BGRA) {
            videoPixelFormat = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_Lossless_32BGRA)]
        } else {
            videoPixelFormat = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        }
        videoDataOutput.videoSettings = videoPixelFormat
        videoDataOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)
    }
    
    private func addVideoConnection() throws {
        guard let camera = camera else { throw DeviceError.cannotFindCamera }
        guard let videoDeviceInput = videoDeviceInput else { throw DeviceError.cannotFindVideoDeviceInput }
        guard let videoDeviceInputPort = videoDeviceInput.ports(for: .video, sourceDeviceType: camera.deviceType, sourceDevicePosition: camera.position).first else { throw DeviceError.cannotFindVideoDeviceInputPort }
        guard let videoDataOutput = videoDataOutput else { throw StudioError.cannotFindVideoDataOutput }
        let videoDataOutputConnection = AVCaptureConnection(inputPorts: [videoDeviceInputPort], output: videoDataOutput)
        
        guard let captureSession = captureSession else { throw StudioError.captureSessionInstantiate }
        
        if captureSession.canAddConnection(videoDataOutputConnection) {
            captureSession.addConnection(videoDataOutputConnection)
        } else {
            throw SessionError.cannotAddVideoConnection
        }
        
        videoDataOutputConnection.videoOrientation = .portrait
    }
    
    private func addConnection(to videoPreviewLayer: AVCaptureVideoPreviewLayer) throws {
        guard let videoDeviceInput = videoDeviceInput else { throw DeviceError.cannotFindVideoDeviceInput }
        guard let camera = camera else { throw DeviceError.cannotFindCamera }
        guard let videoPort = videoDeviceInput.ports(for: .video,
                                                          sourceDeviceType: camera.deviceType,
                                                               sourceDevicePosition: camera.position).first else { throw DeviceError.cannotFindVideoDeviceInputPort }
        let videoPreviewLayerConnection = AVCaptureConnection(inputPort: videoPort, videoPreviewLayer: videoPreviewLayer)
        guard let captureSession = captureSession else { throw StudioError.captureSessionInstantiate }
        if captureSession.canAddConnection(videoPreviewLayerConnection) {
            captureSession.addConnection(videoPreviewLayerConnection)
        } else {
            throw SessionError.cannotAddPreviewLayerConnection
        }
    }
}

// MARK: - Audio
extension DefaultStudio {
    private func configureAudioDeviceInput() throws {
        do {
            guard let microphone = AVCaptureDevice.default(for: .audio) else { throw DeviceError.cannotFindMicrophone }
            self.microphone = microphone
            audioDeviceInput = try AVCaptureDeviceInput(device: microphone)
        } catch {
            throw DeviceError.cannotSetupAudioDeviceinput
        }
    }
    
    private func addAudioDeviceInput() throws {
        guard let audioDeviceInput = audioDeviceInput else { throw DeviceError.cannotFindAudioDeviceInput }
        guard let captureSession = captureSession else { throw StudioError.captureSessionInstantiate }
        if captureSession.canAddInput(audioDeviceInput) {
            captureSession.addInputWithNoConnections(audioDeviceInput)
        } else {
            throw SessionError.cannotAddAudioDeviceInput
        }
    }
    
    private func addAudioDataOutput() throws {
        audioDataOutput = AVCaptureAudioDataOutput()
        guard let captureSession = captureSession else { throw StudioError.captureSessionInstantiate }
        guard let audioDataOutput = audioDataOutput else { throw StudioError.cannotFindAudioDataOutput }
        if captureSession.canAddOutput(audioDataOutput) {
            captureSession.addOutputWithNoConnections(audioDataOutput)
        } else {
            throw SessionError.cannotAddAudioDataOutput
        }
    }
    
    private func setAudioSampleBufferDelegate(on dataOutputQueue: DispatchQueue) throws {
        guard let audioDataOutput = audioDataOutput else { throw StudioError.cannotFindAudioDataOutput }
        audioDataOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)
    }
    
    private func addAudioConnection() throws {
        guard let audioDeviceInput = audioDeviceInput else { throw DeviceError.cannotFindAudioDeviceInput }
        guard let microphone = microphone else { throw DeviceError.cannotFindMicrophone }
        guard let audioDeviceInputPort = audioDeviceInput.ports(for: .audio,
                                                                 sourceDeviceType: microphone.deviceType,
                                                                 sourceDevicePosition: .back).first else {
            throw DeviceError.cannotFindAudioDeviceInputPort
        }
        guard let audioDataOutput = audioDataOutput else { throw StudioError.cannotFindAudioDataOutput }
        let audioDataOutputConnection = AVCaptureConnection(inputPorts: [audioDeviceInputPort], output: audioDataOutput)
        
        guard let captureSession = captureSession else { throw StudioError.captureSessionInstantiate }
        if captureSession.canAddConnection(audioDataOutputConnection) {
            captureSession.addConnection(audioDataOutputConnection)
        } else {
            throw SessionError.cannotAddAudioConnection
        }
    }
    
}

// MARK: - Settings
extension DefaultStudio {
    private func createAudioSettings() throws {
        guard let audioDataOutput = audioDataOutput else { throw StudioError.cannotFindAudioDataOutput }
        guard let audioSettings = audioDataOutput.recommendedAudioSettingsForAssetWriter(writingTo: .mov) as? [String: NSObject] else { throw AssetWriterError.cannotFindAudioSetting }

        self.audioSettings = audioSettings
    }
    
    private func createVideoSettings() throws {
        guard let videoDataOutput = videoDataOutput else { throw StudioError.cannotFindVideoDataOutput }
        guard let videoSettings = videoDataOutput.recommendedVideoSettingsForAssetWriter(writingTo: .mov) as? [String: NSObject] else { throw AssetWriterError.cannotFindVideoSetting }

        self.videoSettings = videoSettings
    }
}

extension DefaultStudio: AVCaptureVideoDataOutputSampleBufferDelegate & AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        processVideoSampleBuffer(sampleBuffer)
        processsAudioSampleBuffer(sampleBuffer)
    }

    private func processVideoSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
            let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else {
                return
        }
        guard let videoSampleBuffer = createVideoSampleBufferWithPixelBuffer(pixelBuffer,
                                                                             formatDescription: formatDescription,
                                                                             presentationTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer)) else {
            print("Error: Unable to create sample buffer from pixelbuffer")
            return
        }
        
        recordVideo(sampleBuffer: videoSampleBuffer)
    }

    private func processsAudioSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        recordAudio(sampleBuffer: sampleBuffer)
    }
    
    private func createVideoSampleBufferWithPixelBuffer(_ pixelBuffer: CVPixelBuffer, formatDescription: CMFormatDescription, presentationTime: CMTime) -> CMSampleBuffer? {
        var sampleBuffer: CMSampleBuffer?
        var timingInfo = CMSampleTimingInfo(duration: .invalid, presentationTimeStamp: presentationTime, decodeTimeStamp: .invalid)
        
        let error = CMSampleBufferCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                     imageBuffer: pixelBuffer,
                                                     dataReady: true,
                                                     makeDataReadyCallback: nil,
                                                     refcon: nil,
                                                     formatDescription: formatDescription,
                                                     sampleTiming: &timingInfo,
                                                     sampleBufferOut: &sampleBuffer)
        if sampleBuffer == nil {
            print("Error: Sample buffer creation failed (error code: \(error))")
        }
        
        return sampleBuffer
    }
}

// MARK: - Transform
extension DefaultStudio {
    private func createVideoTransform() throws {
        guard let videoDataOutput = videoDataOutput else { throw StudioError.cannotFindVideoDataOutput }
        guard let videoConnection = videoDataOutput.connection(with: .video) else { throw SessionError.cannotFindVideoConnection }
        
        let deviceOrientation = UIDevice.current.orientation
        let videoOrientation = AVCaptureVideoOrientation(deviceOrientation: deviceOrientation) ?? .portrait
        
        let cameraTransform = videoConnection.videoOrientationTransform(relativeTo: videoOrientation)

        self.videoTransform = cameraTransform
    }
}

// MARK: - Asset writer
extension DefaultStudio {
    private func startRecord() throws {
        let outputFileName = NSUUID().uuidString
        let outputFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(outputFileName).appendingPathExtension("MOV")
        guard let assetWriter = try? AVAssetWriter(url: outputFileURL, fileType: .mov) else { throw AssetWriterError.assetWriterInstantiate }
        
        let assetWriterAudioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
        assetWriterAudioInput.expectsMediaDataInRealTime = true
        assetWriter.add(assetWriterAudioInput)
        
        let assetWriterVideoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        assetWriterVideoInput.expectsMediaDataInRealTime = true
        guard let videoTransform = videoTransform else { throw AssetWriterError.cannotFindVideoTransform }
        assetWriterVideoInput.transform = videoTransform
        assetWriter.add(assetWriterVideoInput)
        
        self.assetWriter = assetWriter
        self.videoAssetWriterInput = assetWriterAudioInput
        self.audioAssetWriterInput = assetWriterVideoInput
        
        isRecording = true
    }
    
    private func stopRecord(completion: @escaping (URL) -> Void) throws {
        guard let assetWriter = assetWriter else { throw AssetWriterError.cannotFindAssetWriter }
        
        self.isRecording = false
        self.assetWriter = nil
        
        assetWriter.finishWriting {
            completion(assetWriter.outputURL)
        }
    }
    
    private func recordVideo(sampleBuffer: CMSampleBuffer) {
        guard isRecording, let assetWriter = assetWriter else { return }
        
        if assetWriter.status == .unknown {
            assetWriter.startWriting()
            assetWriter.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
        } else if assetWriter.status == .writing {
            if let input = videoAssetWriterInput,
                input.isReadyForMoreMediaData {
                input.append(sampleBuffer)
            }
        }
    }
    
    private func recordAudio(sampleBuffer: CMSampleBuffer) {
        guard isRecording, let assetWriter = assetWriter, assetWriter.status == .writing, let input = audioAssetWriterInput, input.isReadyForMoreMediaData else { return }
        input.append(sampleBuffer)
    }
}

// MARK: Save
extension DefaultStudio {
    private func saveMovieToPhotoLibrary(_ movieURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    let options = PHAssetResourceCreationOptions()
                    options.shouldMoveFile = true
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    creationRequest.addResource(with: .video, fileURL: movieURL, options: options)
                }, completionHandler: { success, error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        if FileManager.default.fileExists(atPath: movieURL.path) {
                            do {
                                try FileManager.default.removeItem(atPath: movieURL.path)
                            } catch {
                                completion(.failure(PhotoLibraryError.cannotCleanUpMovieFile))
                            }
                        }
                        
                        if let currentBackgroundRecordingID = self.backgroundRecordingID {
                            self.backgroundRecordingID = UIBackgroundTaskIdentifier.invalid
                            if currentBackgroundRecordingID != UIBackgroundTaskIdentifier.invalid {
                                UIApplication.shared.endBackgroundTask(currentBackgroundRecordingID)
                            }
                        } else {
                            completion(.failure(PhotoLibraryError.cannotFindBackgroundRecordingID))
                        }
                    }
                })
            } else {
                completion(.failure(PhotoLibraryError.notAuthorized))
            }
        }
    }
}
