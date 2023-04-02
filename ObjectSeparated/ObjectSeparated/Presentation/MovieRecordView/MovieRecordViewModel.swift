//
//  MovieRecordViewModel.swift
//  ObjectSeparated
//
//  Created by Horus on 2023/03/19.
//

import AVFoundation

protocol MovieRecordViewModel {
    func startSession(on sessionQueue: DispatchQueue, with layer: AVCaptureVideoPreviewLayer)
    func configureCamera(with dataOutputQueue: DispatchQueue, videoPreviewLayer: AVCaptureVideoPreviewLayer, sessionQueue: DispatchQueue)
    func configureMicrophone(with dataOutputQueue: DispatchQueue, sessionQueue: DispatchQueue)
    func didStartMovieRecord(on dataOutputQueue: DispatchQueue)
    func didStopMovieRecord(from dataOutputQueue: DispatchQueue)
}

final class DefaultMovieRecordViewModel: MovieRecordViewModel {
    
    private var isSuccess: Bool
    private var error: Error?
    private let movieRecordUseCase: MovieRecordUseCase
    
    init(movieRecordUseCase: MovieRecordUseCase) {
        self.isSuccess = false
        self.error = nil
        self.movieRecordUseCase = movieRecordUseCase
    }
    
    func startSession(on sessionQueue: DispatchQueue, with layer: AVCaptureVideoPreviewLayer) {
        movieRecordUseCase.startSession(on: sessionQueue, with: layer) { [weak self] result in
            switch result {
            case .success(let isSuccess):
                self?.isSuccess = isSuccess
                
            case .failure(let error):
                self?.error = error
                
            }
        }
    }
    
    func configureCamera(with dataOutputQueue: DispatchQueue, videoPreviewLayer: AVCaptureVideoPreviewLayer, sessionQueue: DispatchQueue) {
        movieRecordUseCase.configureCamera(with: dataOutputQueue, videoPreviewLayer: videoPreviewLayer, sessionQueue: sessionQueue) { [weak self] result in
            switch result {
            case .success(let isSuccess):
                self?.isSuccess = isSuccess
                
            case .failure(let error):
                self?.error = error
                
            }
        }
    }
    
    func configureMicrophone(with dataOutputQueue: DispatchQueue, sessionQueue: DispatchQueue) {
        movieRecordUseCase.configureMicrophone(with: dataOutputQueue, sessionQueue: sessionQueue) { [weak self] result in
            switch result {
            case .success(let isSuccess):
                self?.isSuccess = isSuccess
                
            case .failure(let error):
                self?.error = error
                
            }
        }
    }
    
    func didStartMovieRecord(on dataOutputQueue: DispatchQueue) {
        do {
            movieRecordUseCase.executeMovieRecord(on: dataOutputQueue, completion: { result in
                switch result {
                case .success(_):
                    return
                    
                case .failure(let error):
                    self.error = error
                    
                }
            })
        }
    }
    
    func didStopMovieRecord(from dataOutputQueue: DispatchQueue) {
        movieRecordUseCase.executeStopMovieRecord(from: dataOutputQueue) { [weak self] result in
            switch result {
            case .success(_):
                return
                
            case .failure(let error):
                self?.error = error
                
            }
        }
    }
    
}

