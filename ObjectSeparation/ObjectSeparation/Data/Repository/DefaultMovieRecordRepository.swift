//
//  DefaultMovieRecordRepository.swift
//  ObjectSeparation
//
//  Created by Horus on 2023/03/04.
//

import AVFoundation

final class DefaultMovieRecordRepository: MovieRecordRepository {
    
    private let studio: StudioConfigurable
    
    init(studio: StudioConfigurable) {
        self.studio = studio
    }
    
    func startSession(on sessionQueue: DispatchQueue, with layer: AVCaptureVideoPreviewLayer) {
        studio.startSession(on: sessionQueue, with: layer)
    }
    
    func configureCamera(with dataOutputQueue: DispatchQueue, videoPreviewLayer: AVCaptureVideoPreviewLayer, sessionQueue: DispatchQueue) {
        studio.configureCamera(with: dataOutputQueue, videoPreviewLayer: videoPreviewLayer, sessionQueue: sessionQueue)
    }
    
    func configureMicrophone(with dataOutputQueue: DispatchQueue, sessionQueue: DispatchQueue) {
        studio.configureMicrophone(with: dataOutputQueue, sessionQueue: sessionQueue)
    }
    
}
