//
//  MovieRecordViewModel.swift
//  ObjectSeparation
//
//  Created by Horus on 2023/03/04.
//

import AVFoundation

protocol MovieRecordViewModel {
    func setupSession(with layer: AVCaptureVideoPreviewLayer)
    func configureCamera(with dataOutputQueue: DispatchQueue, videoPreviewLayer: AVCaptureVideoPreviewLayer)
    func configureMicrophone(with dataOutputQueue: DispatchQueue)
}

final class DefaultMovieRecordViewModel: MovieRecordViewModel {
    
    private let movieRecordUseCase: MovieRecordUseCase
    
    init(movieRecordUseCase: MovieRecordUseCase) {
        self.movieRecordUseCase = movieRecordUseCase
    }
    
    func setupSession(with layer: AVCaptureVideoPreviewLayer) {
        movieRecordUseCase.setupSession(with: layer)
    }
    
    func configureCamera(with dataOutputQueue: DispatchQueue, videoPreviewLayer: AVCaptureVideoPreviewLayer) {
        movieRecordUseCase.configureCamera(with: dataOutputQueue, videoPreviewLayer: videoPreviewLayer)
    }
    
    func configureMicrophone(with dataOutputQueue: DispatchQueue) {
        movieRecordUseCase.configureMicrophone(with: dataOutputQueue)
    }
    
}
