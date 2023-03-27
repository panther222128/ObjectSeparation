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
    
    func startMovieRecord(with videoDataOuput: AVCaptureVideoDataOutput, _ audioDataOutput: AVCaptureAudioDataOutput, completion: @escaping (Result<Bool, Error>) -> Void) throws
    func stopRecord(completion: @escaping (URL) -> Void) throws
    func recordVideo(sampleBuffer: CMSampleBuffer)
    func recordAudio(sampleBuffer: CMSampleBuffer)
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
    
    func startMovieRecord(with videoDataOuput: AVCaptureVideoDataOutput, _ audioDataOutput: AVCaptureAudioDataOutput, completion: @escaping (Result<Bool, Error>) -> Void) throws {
        do {
            try createVideoSettings(with: videoDataOuput)
            try createAudioSettings(with: audioDataOutput)
            try createVideoTransform(from: videoDataOuput)
            try startRecord()
            completion(.success(true))
        } catch let error {
            completion(.failure(error))
        }
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
    
}

extension DefaultMovieWriter {
    private func startRecord() throws {
        let outputFileName = NSUUID().uuidString
        let outputFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(outputFileName).appendingPathExtension("MOV")
        guard let movieWriter = try? AVAssetWriter(url: outputFileURL, fileType: .mov) else { throw MovieWriterError.movieWriterInstantiate }
        
        let assetWriterVideoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        assetWriterVideoInput.expectsMediaDataInRealTime = true
        guard let videoTransform = videoTransform else { throw MovieWriterError.cannotFindVideoTransform }
        assetWriterVideoInput.transform = videoTransform
        movieWriter.add(assetWriterVideoInput)
        
        let assetWriterAudioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
        assetWriterAudioInput.expectsMediaDataInRealTime = true
        movieWriter.add(assetWriterAudioInput)
        
        self.movieWriter = movieWriter
        self.videoAssetWriterInput = assetWriterVideoInput
        self.audioAssetWriterInput = assetWriterAudioInput
        
        isRecording = true
    }
    
    private func createVideoSettings(with videoDataOutput: AVCaptureVideoDataOutput) throws {
        guard let videoSettings = videoDataOutput.recommendedVideoSettingsForAssetWriter(writingTo: .mov) as? [String: NSObject] else { throw MovieWriterError.cannotFindVideoSetting }
        self.videoSettings = videoSettings
    }
    
    private func createAudioSettings(with audioDataOutput: AVCaptureAudioDataOutput) throws {
        guard let audioSettings = audioDataOutput.recommendedAudioSettingsForAssetWriter(writingTo: .mov) as? [String: NSObject] else {
            self.audioSettings = nil
            return
        }
        self.audioSettings = audioSettings
    }
    
    private func createVideoTransform(from videoDataOutput: AVCaptureVideoDataOutput) throws {
        guard let videoConnection = videoDataOutput.connection(with: .video) else { throw SessionError.cannotFindVideoConnection }
        
        let deviceOrientation = UIDevice.current.orientation
        let videoOrientation = AVCaptureVideoOrientation(deviceOrientation: deviceOrientation) ?? .portrait
        
        let cameraTransform = videoConnection.videoOrientationTransform(relativeTo: videoOrientation)

        self.videoTransform = cameraTransform
    }
}
