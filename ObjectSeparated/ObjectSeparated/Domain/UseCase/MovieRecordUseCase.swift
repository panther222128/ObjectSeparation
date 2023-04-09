//
//  MovieRecordUseCase.swift
//  ObjectSeparated
//
//  Created by Horus on 2023/03/19.
//

import AVFoundation

protocol MovieRecordUseCase {
    func startSession(on sessionQueue: DispatchQueue, with layer: AVCaptureVideoPreviewLayer, completion: @escaping (Result<Bool, Error>) -> Void)
    func configureCamera(with dataOutputQueue: DispatchQueue, videoPreviewLayer: AVCaptureVideoPreviewLayer, sessionQueue: DispatchQueue, completion: @escaping (Result<Bool, Error>) -> Void)
    func configureMicrophone(with dataOutputQueue: DispatchQueue, sessionQueue: DispatchQueue, completion: @escaping (Result<Bool, Error>) -> Void)
    func executeMovieRecord(on dataOutputQueue: DispatchQueue, completion: @escaping (Result<Bool, Error>) -> Void)
    func executeStopMovieRecord(from dataOutputQueue: DispatchQueue, completion: @escaping (Result<URL, Error>) -> Void)
    func executeRequestPhotoAuthorization(completion: @escaping (Bool) -> Void)
}

final class DefaultMovieRecordUseCase: MovieRecordUseCase {
    
    private let movieRecordRepository: MovieRecordRepository
    private let studio: StudioConfigurable
    
    init(movieRecordRepository: MovieRecordRepository, studio: StudioConfigurable) {
        self.movieRecordRepository = movieRecordRepository
        self.studio = studio
    }
    
    func startSession(on sessionQueue: DispatchQueue, with layer: AVCaptureVideoPreviewLayer, completion: @escaping (Result<Bool, Error>) -> Void) {
        studio.startCaptureSession(on: sessionQueue, with: layer) { result in
            switch result {
            case .success(let isSuccess):
                completion(.success(isSuccess))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func configureCamera(with dataOutputQueue: DispatchQueue, videoPreviewLayer: AVCaptureVideoPreviewLayer, sessionQueue: DispatchQueue, completion: @escaping (Result<Bool, Error>) -> Void) {
        studio.configureCamera(with: dataOutputQueue, videoPreviewLayer: videoPreviewLayer, sessionQueue: sessionQueue) { result in
            switch result {
            case .success(let isSuccess):
                completion(.success(isSuccess))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func configureMicrophone(with dataOutputQueue: DispatchQueue, sessionQueue: DispatchQueue, completion: @escaping (Result<Bool, Error>) -> Void) {
        studio.configureMicrophone(with: dataOutputQueue, sessionQueue: sessionQueue) { result in
            switch result {
            case .success(let isSuccess):
                completion(.success(isSuccess))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func executeMovieRecord(on dataOutputQueue: DispatchQueue, completion: @escaping (Result<Bool, Error>) -> Void) {
        do {
            studio.startRecording(on: dataOutputQueue, completion: { result in
                switch result {
                case .success(let isSuccess):
                    completion(.success(isSuccess))
                    
                case .failure(let error):
                    completion(.failure(error))
                    
                }
            })
        }
    }
    
    func executeStopMovieRecord(from dataOutPutQueue: DispatchQueue, completion: @escaping (Result<URL, Error>) -> Void) {
        studio.stopRecording(from: dataOutPutQueue) { result in
            switch result {
            case .success(let isSuccess):
                completion(.success(isSuccess))
                
            case .failure(let error):
                completion(.failure(error))
                
            }
        }
    }
    
    func executeRequestPhotoAuthorization(completion: @escaping (Bool) -> Void) {
        studio.requestForPhotoAlbumAccess { isSuccess in
            switch isSuccess {
            case true:
                completion(isSuccess)
                
            case false:
                completion(isSuccess)
                
            }
        }
    }
    
    
}
