//
//  MovieRecordUseCase.swift
//  ObjectSeparation
//
//  Created by Horus on 2023/03/04.
//

import AVFoundation

protocol MovieRecordUseCase {
    func setupSession(with layer: AVCaptureVideoPreviewLayer)
    func configureCamera(with dataOutputQueue: DispatchQueue, videoPreviewLayer: AVCaptureVideoPreviewLayer)
    func configureMicrophone(with dataOutputQueue: DispatchQueue)
}

final class DefaultMovieRecordUseCase: MovieRecordUseCase {
    
    private let movieRecordRepository: MovieRecordRepository
    
    init(movieRecordRepository: MovieRecordRepository) {
        self.movieRecordRepository = movieRecordRepository
    }
    
    func setupSession(with layer: AVCaptureVideoPreviewLayer) {
        movieRecordRepository.setupSession(with: layer)
    }
    
    func configureCamera(with dataOutputQueue: DispatchQueue, videoPreviewLayer: AVCaptureVideoPreviewLayer) {
        movieRecordRepository.configureCamera(with: dataOutputQueue, videoPreviewLayer: videoPreviewLayer)
    }
    
    func configureMicrophone(with dataOutputQueue: DispatchQueue) {
        movieRecordRepository.configureMicrophone(with: dataOutputQueue)
    }
    
}
