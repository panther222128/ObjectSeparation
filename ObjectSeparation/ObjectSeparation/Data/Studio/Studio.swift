//
//  Studio.swift
//  ObjectSeparation
//
//  Created by Horus on 2023/03/04.
//

import AVFoundation
import UIKit
import Photos

protocol StudioConfigurable {
    func setupSession(with layer: AVCaptureVideoPreviewLayer)
    func configureCamera(with dataOutputQueue: DispatchQueue, videoPreviewLayer: AVCaptureVideoPreviewLayer)
    func configureMicrophone(with dataOutputQueue: DispatchQueue)
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
    
    func setupSession(with layer: AVCaptureVideoPreviewLayer) {
        instantiateCaptureSession()
        setSession(to: layer)
    }
    
    func configureCamera(with dataOutputQueue: DispatchQueue, videoPreviewLayer: AVCaptureVideoPreviewLayer) {
        guard let captureSession = captureSession else { return }
        captureSession.beginConfiguration()
        defer {
            captureSession.commitConfiguration()
        }
        configureVideoDeviceInput()
        addVideoDeviceInput()
        addVideoDataOutput()
        setVideoSampleBufferDelegate(on: dataOutputQueue)
        addVideoConnection()
        addConnection(to: videoPreviewLayer)
    }
    
    func configureMicrophone(with dataOutputQueue: DispatchQueue) {
        guard let captureSession = captureSession else { return }
        captureSession.beginConfiguration()
        defer {
            captureSession.commitConfiguration()
        }
        configureAudioDeviceInput()
        addAudioDeviceInput()
        addAudioDataOutput()
        setAudioSampleBufferDelegate(on: dataOutputQueue)
        addAudioConnection()
    }
    
    func startRecording() {
        createVideoSettings()
        createAudioSettings()
        createVideoTransform()
        startRecord()
    }
    
    func stopRecording(completion: @escaping (URL) -> Void) {
        stopRecord { url in
            completion(url)
        }
    }
    
}

// MARK: - Session
extension DefaultStudio {
    private func instantiateCaptureSession() {
        captureSession = AVCaptureSession()
        guard let captureSession = captureSession else { return }
        captureSession.startRunning()
    }
    
    private func setSession(to layer: AVCaptureVideoPreviewLayer) {
        guard let captureSession = captureSession else { return }
        layer.setSessionWithNoConnection(captureSession)
    }
}

// MARK: - Settings
extension DefaultStudio {
    private func createAudioSettings() {
        guard let audioDataOutput = audioDataOutput else { return }
        guard let audioSettings = audioDataOutput.recommendedAudioSettingsForAssetWriter(writingTo: .mov) as? [String: NSObject] else { return }

        self.audioSettings = audioSettings
    }
    
    private func createVideoSettings() {
        guard let videoDataOutput = videoDataOutput else { return }
        guard let videoSettings = videoDataOutput.recommendedVideoSettingsForAssetWriter(writingTo: .mov) as? [String: NSObject] else { return }

        self.videoSettings = videoSettings
    }
}

// MARK: - Video
extension DefaultStudio {
    private func configureVideoDeviceInput() {
        do {
            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }
            self.camera = camera
            videoDeviceInput = try AVCaptureDeviceInput(device: camera)
        } catch {
            print("Could not create back camera device input: \(error)")
        }
    }
    
    private func addVideoDeviceInput() {
        guard let videoDeviceInput = videoDeviceInput else { return }
        guard let captureSession = captureSession else { return }
        if captureSession.canAddInput(videoDeviceInput) {
            captureSession.addInputWithNoConnections(videoDeviceInput)
        } else {
            
        }
    }
    
    private func addVideoDataOutput() {
        videoDataOutput = AVCaptureVideoDataOutput()
        guard let captureSession = captureSession else { return }
        guard let videoDataOutput = videoDataOutput else { return }
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutputWithNoConnections(videoDataOutput)
        } else {
            
        }
    }
    
    private func setVideoSampleBufferDelegate(on dataOutputQueue: DispatchQueue) {
        guard let videoDataOutput = videoDataOutput else { return }
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
    
    private func addVideoConnection() {
        guard let camera = camera else { return }
        guard let videoDeviceInput = videoDeviceInput else { return }
        guard let videoDeviceInputPort = videoDeviceInput.ports(for: .video, sourceDeviceType: camera.deviceType, sourceDevicePosition: camera.position).first else { return }
        guard let videoDataOutput = videoDataOutput else { return }
        let videoDataOutputConnection = AVCaptureConnection(inputPorts: [videoDeviceInputPort], output: videoDataOutput)
        
        guard let captureSession = captureSession else { return }
        
        if captureSession.canAddConnection(videoDataOutputConnection) {
            captureSession.addConnection(videoDataOutputConnection)
        } else {
            
        }
        
        videoDataOutputConnection.videoOrientation = .portrait
    }
    
    private func addConnection(to videoPreviewLayer: AVCaptureVideoPreviewLayer) {
        guard let videoDeviceInput = videoDeviceInput else { return }
        guard let camera = camera else { return }
        guard let videoPort = videoDeviceInput.ports(for: .video,
                                                          sourceDeviceType: camera.deviceType,
                                                               sourceDevicePosition: camera.position).first else { return }
        let videoPreviewLayerConnection = AVCaptureConnection(inputPort: videoPort, videoPreviewLayer: videoPreviewLayer)
        guard let captureSession = captureSession else { return }
        if captureSession.canAddConnection(videoPreviewLayerConnection) {
            captureSession.addConnection(videoPreviewLayerConnection)
        } else {
            
        }
    }
}

// MARK: - Audio
extension DefaultStudio {
    private func configureAudioDeviceInput() {
        do {
            guard let microphone = AVCaptureDevice.default(for: .audio) else { return }
            self.microphone = microphone
            audioDeviceInput = try AVCaptureDeviceInput(device: microphone)
        } catch {
            
        }
    }
    
    private func addAudioDeviceInput() {
        guard let audioDeviceInput = audioDeviceInput else { return }
        guard let captureSession = captureSession else { return }
        if captureSession.canAddInput(audioDeviceInput) {
            captureSession.addInputWithNoConnections(audioDeviceInput)
        } else {
            
        }
    }
    
    private func addAudioDataOutput() {
        audioDataOutput = AVCaptureAudioDataOutput()
        guard let captureSession = captureSession else { return }
        guard let audioDataOutput = audioDataOutput else { return }
        if captureSession.canAddOutput(audioDataOutput) {
            captureSession.addOutputWithNoConnections(audioDataOutput)
        } else {
            
        }
    }
    
    private func setAudioSampleBufferDelegate(on dataOutputQueue: DispatchQueue) {
        guard let audioDataOutput = audioDataOutput else { return }
        audioDataOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)
    }
    
    private func addAudioConnection() {
        guard let audioDeviceInput = audioDeviceInput else { return }
        guard let microphone = microphone else { return }
        guard let audioDeviceInputPort = audioDeviceInput.ports(for: .audio,
                                                                 sourceDeviceType: microphone.deviceType,
                                                                 sourceDevicePosition: .back).first else {
                                                                    return
        }
        guard let audioDataOutput = audioDataOutput else { return }
        let audioDataOutputConnection = AVCaptureConnection(inputPorts: [audioDeviceInputPort], output: audioDataOutput)
        
        guard let captureSession = captureSession else { return }
        if captureSession.canAddConnection(audioDataOutputConnection) {
            captureSession.addConnection(audioDataOutputConnection)
        } else {
            
        }
    }
    
}

extension DefaultStudio: AVCaptureVideoDataOutputSampleBufferDelegate & AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if let videoDataOutput = output as? AVCaptureVideoDataOutput {
            processVideoSampleBuffer(sampleBuffer, fromOutput: videoDataOutput)
        } else if let audioDataOutput = output as? AVCaptureAudioDataOutput {
            processsAudioSampleBuffer(sampleBuffer, fromOutput: audioDataOutput)
        }
    }

    // MARK: - AVCaptureVideoDataOutput -> not called in method
    private func processVideoSampleBuffer(_ fullScreenSampleBuffer: CMSampleBuffer, fromOutput: AVCaptureVideoDataOutput) {
        guard let fullScreenPixelBuffer = CMSampleBufferGetImageBuffer(fullScreenSampleBuffer),
            let formatDescription = CMSampleBufferGetFormatDescription(fullScreenSampleBuffer) else {
                return
        }
        guard let finalVideoSampleBuffer = createVideoSampleBufferWithPixelBuffer(fullScreenPixelBuffer,
                                                                                  formatDescription: formatDescription,
                                                                                  presentationTime: CMSampleBufferGetPresentationTimeStamp(fullScreenSampleBuffer)) else {
                                                                                        print("Error: Unable to create sample buffer from pixelbuffer")
                                                                                        return
        }
        
        recordVideo(sampleBuffer: finalVideoSampleBuffer)
    }

    // MARK: - AVCaptureAudioDataOutput -> not called in method
    private func processsAudioSampleBuffer(_ sampleBuffer: CMSampleBuffer, fromOutput audioDataOutput: AVCaptureAudioDataOutput) {
        recordAudio(sampleBuffer: sampleBuffer)
    }
    
    private func createVideoSampleBufferWithPixelBuffer(_ pixelBuffer: CVPixelBuffer, formatDescription: CMFormatDescription, presentationTime: CMTime) -> CMSampleBuffer? {
        var sampleBuffer: CMSampleBuffer?
        var timingInfo = CMSampleTimingInfo(duration: .invalid, presentationTimeStamp: presentationTime, decodeTimeStamp: .invalid)
        
        let err = CMSampleBufferCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                     imageBuffer: pixelBuffer,
                                                     dataReady: true,
                                                     makeDataReadyCallback: nil,
                                                     refcon: nil,
                                                     formatDescription: formatDescription,
                                                     sampleTiming: &timingInfo,
                                                     sampleBufferOut: &sampleBuffer)
        if sampleBuffer == nil {
            print("Error: Sample buffer creation failed (error code: \(err))")
        }
        
        return sampleBuffer
    }
}

// MARK: - Transform
extension DefaultStudio {
    private func createVideoTransform() {
        guard let videoDataOutput = videoDataOutput else { return }
        guard let videoConnection = videoDataOutput.connection(with: .video) else { return }
        
        let deviceOrientation = UIDevice.current.orientation
        let videoOrientation = AVCaptureVideoOrientation(deviceOrientation: deviceOrientation) ?? .portrait
        
        let cameraTransform = videoConnection.videoOrientationTransform(relativeTo: videoOrientation)

        self.videoTransform = cameraTransform
    }
}

// MARK: - Asset writer
extension DefaultStudio {
    func startRecord() {
        let outputFileName = NSUUID().uuidString
        let outputFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(outputFileName).appendingPathExtension("MOV")
        guard let assetWriter = try? AVAssetWriter(url: outputFileURL, fileType: .mov) else {
            return
        }
        
        let assetWriterAudioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
        assetWriterAudioInput.expectsMediaDataInRealTime = true
        assetWriter.add(assetWriterAudioInput)
        
        let assetWriterVideoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        assetWriterVideoInput.expectsMediaDataInRealTime = true
        // MARK: -  Focus
        guard let videoTransform = videoTransform else { return }
        assetWriterVideoInput.transform = videoTransform
        assetWriter.add(assetWriterVideoInput)
        
        self.assetWriter = assetWriter
        self.videoAssetWriterInput = assetWriterAudioInput
        self.audioAssetWriterInput = assetWriterVideoInput
        
        isRecording = true
    }
    
    func stopRecord(completion: @escaping (URL) -> Void) {
        guard let assetWriter = assetWriter else {
            return
        }
        
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
    private func saveMovieToPhotoLibrary(_ movieURL: URL) {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    let options = PHAssetResourceCreationOptions()
                    options.shouldMoveFile = true
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    creationRequest.addResource(with: .video, fileURL: movieURL, options: options)
                }, completionHandler: { success, error in
                    if !success {
                        
                    } else {
                        if FileManager.default.fileExists(atPath: movieURL.path) {
                            do {
                                try FileManager.default.removeItem(atPath: movieURL.path)
                            } catch {
                                print("Could not remove file at url: \(movieURL)")
                            }
                        }
                        
                        if let currentBackgroundRecordingID = self.backgroundRecordingID {
                            self.backgroundRecordingID = UIBackgroundTaskIdentifier.invalid
                            
                            if currentBackgroundRecordingID != UIBackgroundTaskIdentifier.invalid {
                                UIApplication.shared.endBackgroundTask(currentBackgroundRecordingID)
                            }
                        }
                    }
                })
            } else {
                
            }
        }
    }
}
