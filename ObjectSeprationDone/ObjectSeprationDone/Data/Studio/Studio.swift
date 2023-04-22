//
//  Studio.swift
//  ObjectSeprationDone
//
//  Created by Horus on 2023/03/22.
//

import AVFoundation
import UIKit
import Photos

enum StudioError: Error {
    case captureSessionInstantiate
    case cannotFindVideoDataOutput
    case cannotFindAudioDataOutput
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
    func runCaptureSession(on sessionQueue: DispatchQueue, completion: @escaping (Result<Bool, Error>) -> Void)
    func configureCamera(with dataOutputQueue: DispatchQueue, videoPreviewLayer: AVCaptureVideoPreviewLayer, sessionQueue: DispatchQueue, completion: @escaping (Result<Bool, Error>) -> Void)
    func configureMicrophone(with dataOutputQueue: DispatchQueue, sessionQueue: DispatchQueue, completion: @escaping (Result<Bool, Error>) -> Void)
    func startRecording(on dataOutputQueue: DispatchQueue, completion: @escaping (Result<Bool, Error>) -> Void)
    func stopRecording(from dataOutputQueue: DispatchQueue, completion: @escaping (Result<URL, Error>) -> Void)
    func requestForPhotoAlbumAccess(completion: @escaping (Bool) -> Void)
}

final class DefaultStudio: NSObject, StudioConfigurable {
    
    private let cameraProvider: CameraProvidable
    private let microphoneProvider: MicrophoneProvidable
    private let movieWriter: MovieWriter
    private let photoLibrarian: PhotoLibrarian
    private var captureSession: AVCaptureSession?
    private var videoDataOutput: AVCaptureVideoDataOutput?
    private var audioDataOutput: AVCaptureAudioDataOutput?
    private var videoPixelFormat: [String: Any]?
    
    init(cameraProvider: CameraProvidable, microphoneProvider: MicrophoneProvidable, movieWriter: MovieWriter, photoLibrarian: PhotoLibrarian) {
        self.cameraProvider = cameraProvider
        self.microphoneProvider = microphoneProvider
        self.movieWriter = movieWriter
        self.photoLibrarian = photoLibrarian
        self.captureSession = nil
        self.videoDataOutput = nil
        self.audioDataOutput = nil
        self.videoPixelFormat = nil
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
    
    func runCaptureSession(on sessionQueue: DispatchQueue, completion: @escaping (Result<Bool, Error>) -> Void) {
        sessionQueue.async {
            guard let captureSession = self.captureSession else {
                completion(.failure(StudioError.captureSessionInstantiate))
                return
            }
            captureSession.startRunning()
        }
    }
    
    func configureCamera(with dataOutputQueue: DispatchQueue, videoPreviewLayer: AVCaptureVideoPreviewLayer, sessionQueue: DispatchQueue, completion: @escaping (Result<Bool, Error>) -> Void) {
        sessionQueue.async {
            guard let captureSession = self.captureSession else {
                completion(.failure(StudioError.captureSessionInstantiate))
                return
            }
            captureSession.beginConfiguration()
            defer {
                captureSession.commitConfiguration()
            }
            do {
                try self.cameraProvider.prepareVideoDeviceInput(for: captureSession)
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
            guard let captureSession = self.captureSession else {
                completion(.failure(StudioError.captureSessionInstantiate))
                return
            }
            captureSession.beginConfiguration()
            defer {
                captureSession.commitConfiguration()
            }
            do {
                try self.microphoneProvider.prepareAudioDeviceInput(for: captureSession)
                try self.addAudioDataOutput()
                try self.setAudioSampleBufferDelegate(on: dataOutputQueue)
                try self.addAudioConnection()
                completion(.success(true))
            } catch let error {
                completion(.failure(error))
            }
        }
    }
    
    func startRecording(on dataOutputQueue: DispatchQueue, completion: @escaping (Result<Bool, Error>) -> Void) {
        dataOutputQueue.async {
            do {
                guard let videoDataOutput = self.videoDataOutput else {
                    completion(.failure(StudioError.cannotFindVideoDataOutput))
                    return
                }
                guard let audioDataOutput = self.audioDataOutput else {
                    completion(.failure(StudioError.cannotFindAudioDataOutput))
                    return
                }
                try self.movieWriter.startMovieRecord(with: videoDataOutput, audioDataOutput)
                completion(.success(true))
            } catch let error {
                completion(.failure(error))
            }
        }
    }
    
    func stopRecording(from dataOutputQueue: DispatchQueue, completion: @escaping (Result<URL, Error>) -> Void) {
        dataOutputQueue.async {
            do {
                try self.movieWriter.stopRecord { [weak self] url in
                    self?.photoLibrarian.saveMovieToPhotoLibrary(url, completion: { result in
                        switch result {
                        case .success(let url):
                            completion(.success(url))
                            
                        case .failure(let error):
                            completion(.failure(error))
                            
                        }
                    })
                }
            } catch let error {
                completion(.failure(error))
            }
        }
    }
    
    func requestForPhotoAlbumAccess(completion: @escaping (Bool) -> Void) {
        photoLibrarian.requestForPhotoAlbumAccess { isSuccess in
            switch isSuccess {
            case true:
                completion(isSuccess)
                
            case false:
                completion(isSuccess)
                
            }
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
        guard let camera = cameraProvider.camera else { throw CameraError.cannotFindCamera }
        guard let videoDeviceInput = cameraProvider.videoDeviceInput else { throw CameraError.cannotFindVideoDeviceInput }
        guard let videoDeviceInputPort = videoDeviceInput.ports(for: .video, sourceDeviceType: camera.deviceType, sourceDevicePosition: camera.position).first else { throw CameraError.cannotFindVideoDeviceInputPort }
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
        guard let videoDeviceInput = cameraProvider.videoDeviceInput else { throw CameraError.cannotFindVideoDeviceInput }
        guard let camera = cameraProvider.camera else { throw CameraError.cannotFindCamera }
        guard let videoPort = videoDeviceInput.ports(for: .video,
                                                          sourceDeviceType: camera.deviceType,
                                                               sourceDevicePosition: camera.position).first else { throw CameraError.cannotFindVideoDeviceInputPort }
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
        guard let audioDeviceInput = microphoneProvider.audioDeviceInput else { throw MicrophoneError.cannotFindAudioDeviceInput }
        guard let microphone = microphoneProvider.microphone else { throw MicrophoneError.cannotFindMicrophone }
        guard let audioDeviceInputPort = audioDeviceInput.ports(for: .audio,
                                                                 sourceDeviceType: microphone.deviceType,
                                                                 sourceDevicePosition: .unspecified).first else {
            throw MicrophoneError.cannotFindAudioDeviceInputPort
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
        if let videoDataOutput = output as? AVCaptureVideoDataOutput {
            processVideo(sampleBuffer, from: videoDataOutput)
        } else if let audioDataOutput = output as? AVCaptureAudioDataOutput {
            processsAudio(sampleBuffer, from: audioDataOutput)
        }
    }

    private func processVideo(_ sampleBuffer: CMSampleBuffer, from: AVCaptureVideoDataOutput) {
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
        movieWriter.recordVideo(sampleBuffer: videoSampleBuffer)
    }

    private func processsAudio(_ sampleBuffer: CMSampleBuffer, from: AVCaptureAudioDataOutput) {
        movieWriter.recordAudio(sampleBuffer: sampleBuffer)
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
