//
//  AssetWriter.swift
//  ObjectSeparated
//
//  Created by Horus on 2023/03/21.
//

import UIKit
import AVFoundation

enum MovieWriterError: Error {
    case cannotFindAudioSetting
    case cannotFindVideoSetting
    case movieWriterInstantiate
    case cannotFindVideoTransform
    case cannotFindMovieWriter
}

protocol MovieWriter {
    var videoTransform: CGAffineTransform? { get }
    
    func startRecord() throws
    func stopRecord(completion: @escaping (URL) -> Void) throws
    func recordVideo(sampleBuffer: CMSampleBuffer)
    func recordAudio(sampleBuffer: CMSampleBuffer)
    func createVideoSettings(with videoDataOutput: AVCaptureVideoDataOutput) throws
    func createAudioSettings(with audioDataOutput: AVCaptureAudioDataOutput) throws
    func createVideoTransform(from videoDataOutput: AVCaptureVideoDataOutput) throws
}

final class DefaultMovieWriter: MovieWriter {
    
    private var movieWriter: AVAssetWriter?
    private var videoAssetWriterInput: AVAssetWriterInput?
    private var audioAssetWriterInput: AVAssetWriterInput?
    private var videoSettings: [String: NSObject]?
    private var audioSettings: [String: NSObject]?
    private(set) var videoTransform: CGAffineTransform?
    private var isRecording: Bool = false
    
    init() {
        self.movieWriter = nil
        self.videoAssetWriterInput = nil
        self.audioAssetWriterInput = nil
        self.videoSettings = nil
        self.audioSettings = nil
        self.videoTransform = nil
    }
    
    func startRecord() throws {
        let outputFileName = NSUUID().uuidString
        let outputFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(outputFileName).appendingPathExtension("MOV")
        guard let movieWriter = try? AVAssetWriter(url: outputFileURL, fileType: .mov) else { throw MovieWriterError.movieWriterInstantiate }
        
        let assetWriterAudioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
        assetWriterAudioInput.expectsMediaDataInRealTime = true
        movieWriter.add(assetWriterAudioInput)
        
        let assetWriterVideoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        assetWriterVideoInput.expectsMediaDataInRealTime = true
        guard let videoTransform = videoTransform else { throw MovieWriterError.cannotFindVideoTransform }
        assetWriterVideoInput.transform = videoTransform
        movieWriter.add(assetWriterVideoInput)
        
        self.movieWriter = movieWriter
        self.videoAssetWriterInput = assetWriterAudioInput
        self.audioAssetWriterInput = assetWriterVideoInput
        
        isRecording = true
    }
    
    func stopRecord(completion: @escaping (URL) -> Void) throws {
        guard let movieWriter = movieWriter else { throw MovieWriterError.cannotFindMovieWriter }
        
        self.isRecording = false
        self.movieWriter = nil
        
        movieWriter.finishWriting {
            completion(movieWriter.outputURL)
        }
    }
    
    func recordVideo(sampleBuffer: CMSampleBuffer) {
        guard isRecording, let movieWriter = movieWriter else { return }
        
        if movieWriter.status == .unknown {
            movieWriter.startWriting()
            movieWriter.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
        } else if movieWriter.status == .writing {
            if let input = videoAssetWriterInput,
                input.isReadyForMoreMediaData {
                input.append(sampleBuffer)
            }
        }
    }
    
    func recordAudio(sampleBuffer: CMSampleBuffer) {
        guard isRecording, let movieWriter = movieWriter, movieWriter.status == .writing, let input = audioAssetWriterInput, input.isReadyForMoreMediaData else { return }
        input.append(sampleBuffer)
    }
    
    func createVideoSettings(with videoDataOutput: AVCaptureVideoDataOutput) throws {
        guard let videoSettings = videoDataOutput.recommendedVideoSettingsForAssetWriter(writingTo: .mov) as? [String: NSObject] else { throw MovieWriterError.cannotFindVideoSetting }
        self.videoSettings = videoSettings
    }
    
    func createAudioSettings(with audioDataOutput: AVCaptureAudioDataOutput) throws {
        guard let audioSettings = audioDataOutput.recommendedAudioSettingsForAssetWriter(writingTo: .mov) as? [String: NSObject] else { throw MovieWriterError.cannotFindAudioSetting }
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
