//
//  MovieRecordUseCase.swift
//  ObjectSeparation
//
//  Created by Horus on 2023/03/04.
//

import AVFoundation

protocol MovieRecordUseCase {
    func startSession(on sessionQueue: DispatchQueue, with layer: AVCaptureVideoPreviewLayer, completion: @escaping (Result<Bool, Error>) -> Void)
    func configureCamera(with dataOutputQueue: DispatchQueue, videoPreviewLayer: AVCaptureVideoPreviewLayer, sessionQueue: DispatchQueue, completion: @escaping (Result<Bool, Error>) -> Void)
    func configureMicrophone(with dataOutputQueue: DispatchQueue, sessionQueue: DispatchQueue, completion: @escaping (Result<Bool, Error>) -> Void)
    func executeMovieRecord(completion: @escaping (Result<Bool, Error>) -> Void)
    func executeStopMovieRecord(completion: @escaping (Result<URL, Error>) -> Void)
}

final class DefaultMovieRecordUseCase: MovieRecordUseCase {
    
    private let movieRecordRepository: MovieRecordRepository
    
    init(movieRecordRepository: MovieRecordRepository) {
        self.movieRecordRepository = movieRecordRepository
    }
    
    func startSession(on sessionQueue: DispatchQueue, with layer: AVCaptureVideoPreviewLayer, completion: @escaping (Result<Bool, Error>) -> Void) {
        movieRecordRepository.startSession(on: sessionQueue, with: layer) { result in
            switch result {
            case .success(let isSuccess):
                completion(.success(isSuccess))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func configureCamera(with dataOutputQueue: DispatchQueue, videoPreviewLayer: AVCaptureVideoPreviewLayer, sessionQueue: DispatchQueue, completion: @escaping (Result<Bool, Error>) -> Void) {
        movieRecordRepository.configureCamera(with: dataOutputQueue, videoPreviewLayer: videoPreviewLayer, sessionQueue: sessionQueue) { result in
            switch result {
            case .success(let isSuccess):
                completion(.success(isSuccess))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func configureMicrophone(with dataOutputQueue: DispatchQueue, sessionQueue: DispatchQueue, completion: @escaping (Result<Bool, Error>) -> Void) {
        movieRecordRepository.configureMicrophone(with: dataOutputQueue, sessionQueue: sessionQueue) { result in
            switch result {
            case .success(let isSuccess):
                completion(.success(isSuccess))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func executeMovieRecord(completion: @escaping (Result<Bool, Error>) -> Void) {
        movieRecordRepository.startMovieRecord { result in
            switch result {
            case .success(let isSuccess):
                completion(.success(isSuccess))
                
            case .failure(let error):
                completion(.failure(error))
                
            }
        }
    }
    
    func executeStopMovieRecord(completion: @escaping (Result<URL, Error>) -> Void) {
        movieRecordRepository.stopMovieRecord { result in
            switch result {
            case .success(let url):
                completion(.success(url))
                
            case .failure(let error):
                completion(.failure(error))
                
            }
        }
    }
    
}
