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
    
    func setupSession(with layer: AVCaptureVideoPreviewLayer) {
        studio.setupSession(with: layer)
    }
    
    func configureCamera(with dataOutputQueue: DispatchQueue, videoPreviewLayer: AVCaptureVideoPreviewLayer) {
        studio.configureCamera(with: dataOutputQueue, videoPreviewLayer: videoPreviewLayer)
    }
    
    func configureMicrophone(with dataOutputQueue: DispatchQueue) {
        studio.configureMicrophone(with: dataOutputQueue)
    }
    
}
