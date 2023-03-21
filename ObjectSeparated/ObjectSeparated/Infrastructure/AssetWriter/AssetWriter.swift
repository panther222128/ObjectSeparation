//
//  AssetWriter.swift
//  ObjectSeparated
//
//  Created by Horus on 2023/03/21.
//

import UIKit
import AVFoundation

enum AssetWriterError: Error {
    case assetWriterInstantiate
    case cannotFindAssetWriter
}

protocol AssetWriter {
    var videoTransform: CGAffineTransform? { get }
    
    func startRecord() throws
    func stopRecord(completion: @escaping (URL) -> Void) throws
    func recordVideo(sampleBuffer: CMSampleBuffer)
    func recordAudio(sampleBuffer: CMSampleBuffer)
    func createVideoSettings(with videoDataOutput: AVCaptureVideoDataOutput) throws
    func createAudioSettings(with audioDataOutput: AVCaptureAudioDataOutput) throws
    func createVideoTransform(from videoDataOutput: AVCaptureVideoDataOutput) throws
}

final class DefaultAssetWriter: AssetWriter {
    
    private var assetWriter: AVAssetWriter?
    private var videoAssetWriterInput: AVAssetWriterInput?
    private var audioAssetWriterInput: AVAssetWriterInput?
    private var videoSettings: [String: NSObject]?
    private var audioSettings: [String: NSObject]?
    private(set) var videoTransform: CGAffineTransform?
    private var isRecording: Bool = false
    
    init() {
        self.assetWriter = nil
        self.videoAssetWriterInput = nil
        self.audioAssetWriterInput = nil
        self.videoSettings = nil
        self.audioSettings = nil
        self.videoTransform = nil
    }
    
    func startRecord() throws {
        let outputFileName = NSUUID().uuidString
        let outputFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(outputFileName).appendingPathExtension("MOV")
        guard let assetWriter = try? AVAssetWriter(url: outputFileURL, fileType: .mov) else { throw AssetWriterError.assetWriterInstantiate }
        
        let assetWriterAudioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
        assetWriterAudioInput.expectsMediaDataInRealTime = true
        assetWriter.add(assetWriterAudioInput)
        
        let assetWriterVideoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        assetWriterVideoInput.expectsMediaDataInRealTime = true
        guard let videoTransform = videoTransform else { throw StudioError.cannotFindVideoTransform }
        assetWriterVideoInput.transform = videoTransform
        assetWriter.add(assetWriterVideoInput)
        
        self.assetWriter = assetWriter
        self.videoAssetWriterInput = assetWriterAudioInput
        self.audioAssetWriterInput = assetWriterVideoInput
        
        isRecording = true
    }
    
    func stopRecord(completion: @escaping (URL) -> Void) throws {
        guard let assetWriter = assetWriter else { throw AssetWriterError.cannotFindAssetWriter }
        
        self.isRecording = false
        self.assetWriter = nil
        
        assetWriter.finishWriting {
            completion(assetWriter.outputURL)
        }
    }
    
    func recordVideo(sampleBuffer: CMSampleBuffer) {
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
    
    func recordAudio(sampleBuffer: CMSampleBuffer) {
        guard isRecording, let assetWriter = assetWriter, assetWriter.status == .writing, let input = audioAssetWriterInput, input.isReadyForMoreMediaData else { return }
        input.append(sampleBuffer)
    }
    
    func createVideoSettings(with videoDataOutput: AVCaptureVideoDataOutput) throws {
        guard let videoSettings = videoDataOutput.recommendedVideoSettingsForAssetWriter(writingTo: .mov) as? [String: NSObject] else { throw StudioError.cannotFindVideoSetting }
        self.videoSettings = videoSettings
    }
    
    func createAudioSettings(with audioDataOutput: AVCaptureAudioDataOutput) throws {
        guard let audioSettings = audioDataOutput.recommendedAudioSettingsForAssetWriter(writingTo: .mov) as? [String: NSObject] else { throw StudioError.cannotFindAudioSetting }
        self.audioSettings = audioSettings
    }
    
    func createVideoTransform(from videoDataOutput: AVCaptureVideoDataOutput) throws {
        guard let videoConnection = videoDataOutput.connection(with: .video) else { throw SessionError.cannotFindVideoConnection }
        
        let deviceOrientation = UIDevice.current.orientation
        let videoOrientation = AVCaptureVideoOrientation(deviceOrientation: deviceOrientation) ?? .portrait
        
        let cameraTransform = videoConnection.videoOrientationTransform(relativeTo: videoOrientation)

        self.videoTransform = cameraTransform
    }
    
}
