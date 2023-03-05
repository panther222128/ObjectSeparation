//
//  MovieRecordViewModel.swift
//  ObjectSeparation
//
//  Created by Horus on 2023/03/04.
//

import AVFoundation

protocol MovieRecordViewModel {
    func setupSession(with layer: AVCaptureVideoPreviewLayer, on sessionQueue: DispatchQueue)
    func configureCamera(with dataOutputQueue: DispatchQueue, videoPreviewLayer: AVCaptureVideoPreviewLayer, sessionQueue: DispatchQueue)
    func configureMicrophone(with dataOutputQueue: DispatchQueue, sessionQueue: DispatchQueue)
}

final class DefaultMovieRecordViewModel: MovieRecordViewModel {
    
    private let movieRecordUseCase: MovieRecordUseCase
    
    init(movieRecordUseCase: MovieRecordUseCase) {
        self.movieRecordUseCase = movieRecordUseCase
    }
    
    func setupSession(with layer: AVCaptureVideoPreviewLayer, on sessionQueue: DispatchQueue) {
        movieRecordUseCase.setupSession(with: layer, on: sessionQueue)
    }
    
    func configureCamera(with dataOutputQueue: DispatchQueue, videoPreviewLayer: AVCaptureVideoPreviewLayer, sessionQueue: DispatchQueue) {
        movieRecordUseCase.configureCamera(with: dataOutputQueue, videoPreviewLayer: videoPreviewLayer, sessionQueue: sessionQueue)
    }
    
    func configureMicrophone(with dataOutputQueue: DispatchQueue, sessionQueue: DispatchQueue) {
        movieRecordUseCase.configureMicrophone(with: dataOutputQueue, sessionQueue: sessionQueue)
    }
    
}
