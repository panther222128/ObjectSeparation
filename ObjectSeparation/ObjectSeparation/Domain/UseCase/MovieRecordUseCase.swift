//
//  MovieRecordUseCase.swift
//  ObjectSeparation
//
//  Created by Horus on 2023/03/04.
//

import AVFoundation

protocol MovieRecordUseCase {
    func startSession(on sessionQueue: DispatchQueue, with layer: AVCaptureVideoPreviewLayer)
    func configureCamera(with dataOutputQueue: DispatchQueue, videoPreviewLayer: AVCaptureVideoPreviewLayer, sessionQueue: DispatchQueue)
    func configureMicrophone(with dataOutputQueue: DispatchQueue, sessionQueue: DispatchQueue)
}

final class DefaultMovieRecordUseCase: MovieRecordUseCase {
    
    private let movieRecordRepository: MovieRecordRepository
    
    init(movieRecordRepository: MovieRecordRepository) {
        self.movieRecordRepository = movieRecordRepository
    }
    
    func startSession(on sessionQueue: DispatchQueue, with layer: AVCaptureVideoPreviewLayer) {
        movieRecordRepository.startSession(on: sessionQueue, with: layer)
    }
    
    func configureCamera(with dataOutputQueue: DispatchQueue, videoPreviewLayer: AVCaptureVideoPreviewLayer, sessionQueue: DispatchQueue) {
        movieRecordRepository.configureCamera(with: dataOutputQueue, videoPreviewLayer: videoPreviewLayer, sessionQueue: sessionQueue)
    }
    
    func configureMicrophone(with dataOutputQueue: DispatchQueue, sessionQueue: DispatchQueue) {
        movieRecordRepository.configureMicrophone(with: dataOutputQueue, sessionQueue: sessionQueue)
    }
    
}
