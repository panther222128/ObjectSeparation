//
//  Studio.swift
//  ObjectSeparated
//
//  Created by Horus on 2023/03/19.
//

import AVFoundation
import UIKit
import Photos

enum StudioError: Error {
    case captureSessionInstantiate
    case cannotSetLayerConnection
    case cannotFindAudioDataOutput
    case cannotFindAudioSetting
    case cannotFindVideoDataOutput
    case cannotFindVideoSetting
    case cannotFindCamera
    case cannotFindVideoDeviceInput
    case cannotFindVideoDeviceInputPort
    case cannotFindAudioDeviceInput
    case cannotFindAudioDeviceInputPort
    case cannotFindVideoTransform
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
    
    private let deviceProvider: DeviceProvidable
    private let assetWriter: AssetWriter
    private var captureSession: AVCaptureSession?
    private var videoDataOutput: AVCaptureVideoDataOutput?
    private var audioDataOutput: AVCaptureAudioDataOutput?
    private var videoPixelFormat: [String: Any]?
    private var backgroundRecordingID: UIBackgroundTaskIdentifier?
    
    init(deviceProvider: DeviceProvidable, assetWriter: AssetWriter) {
        self.deviceProvider = deviceProvider
        self.assetWriter = assetWriter
        self.captureSession = nil
        self.videoDataOutput = nil
        self.audioDataOutput = nil
        self.videoPixelFormat = nil
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
                try self.deviceProvider.setupVideoDeviceInput(to: captureSession)
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
                try self.deviceProvider.setupAudioDeviceInput(to: captureSession)
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
            guard let videoDataOutput = videoDataOutput else { return }
            guard let audioDataOutput = audioDataOutput else { return }
            try assetWriter.createVideoSettings(with: videoDataOutput)
            try assetWriter.createAudioSettings(with: audioDataOutput)
            try assetWriter.createVideoTransform(from: videoDataOutput)
            try assetWriter.startRecord()
            completion(.success(true))
        } catch let error {
            completion(.failure(error))
        }
    }
    
    func stopRecording(completion: @escaping (Result<URL, Error>) -> Void) {
        do {
            try assetWriter.stopRecord { url in
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

// MARK: - Settings
extension DefaultStudio {
    
}

// MARK: - Video
extension DefaultStudio {
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
        guard let camera = deviceProvider.camera else { throw StudioError.cannotFindCamera }
        guard let videoDeviceInput = deviceProvider.videoDeviceInput else { throw StudioError.cannotFindVideoDeviceInput }
        guard let videoDeviceInputPort = videoDeviceInput.ports(for: .video, sourceDeviceType: camera.deviceType, sourceDevicePosition: camera.position).first else { throw StudioError.cannotFindVideoDeviceInputPort }
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
        guard let videoDeviceInput = deviceProvider.videoDeviceInput else { throw StudioError.cannotFindVideoDeviceInput }
        guard let camera = deviceProvider.camera else { throw StudioError.cannotFindCamera }
        guard let videoPort = videoDeviceInput.ports(for: .video,
                                                          sourceDeviceType: camera.deviceType,
                                                               sourceDevicePosition: camera.position).first else { throw StudioError.cannotFindVideoDeviceInputPort }
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
        guard let audioDeviceInput = deviceProvider.audioDeviceInput else { throw StudioError.cannotFindAudioDeviceInput }
        guard let microphone = deviceProvider.microphone else { throw DeviceError.cannotFindMicrophone }
        guard let audioDeviceInputPort = audioDeviceInput.ports(for: .audio,
                                                                 sourceDeviceType: microphone.deviceType,
                                                                 sourceDevicePosition: .back).first else {
            throw StudioError.cannotFindAudioDeviceInputPort
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

extension DefaultStudio: AVCaptureVideoDataOutputSampleBufferDelegate & AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if let output = output as? AVCaptureVideoDataOutput {
            processVideoSampleBuffer(sampleBuffer, from: output)
        } else if let output = output as? AVCaptureAudioDataOutput {
            processsAudioSampleBuffer(sampleBuffer, from: output)
        }
    }

    // MARK: - AVCaptureVideoDataOutput -> not called in method
    private func processVideoSampleBuffer(_ sampleBuffer: CMSampleBuffer, from videoDataOutput: AVCaptureVideoDataOutput) {
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
        
        assetWriter.recordVideo(sampleBuffer: videoSampleBuffer)
    }

    // MARK: - AVCaptureAudioDataOutput -> not called in method
    private func processsAudioSampleBuffer(_ sampleBuffer: CMSampleBuffer, from audioDataOutput: AVCaptureAudioDataOutput) {
        assetWriter.recordAudio(sampleBuffer: sampleBuffer)
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
