//
//  MovieRecordUseCase.swift
//  ObjectSeprationDone
//
//  Created by Horus on 2023/03/22.
//

import AVFoundation

protocol MovieRecordUseCase {
    func startSession(on sessionQueue: DispatchQueue, with layer: AVCaptureVideoPreviewLayer, completion: @escaping (Result<Bool, Error>) -> Void)
    func runSession(on sessionQueue: DispatchQueue, completion: @escaping (Result<Bool, Error>) -> Void)
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
        studio.startCaptureSession(on: sessionQueue, with: layer, completion: completion)
    }
    
    func runSession(on sessionQueue: DispatchQueue, completion: @escaping (Result<Bool, Error>) -> Void) {
        studio.runCaptureSession(on: sessionQueue, completion: completion)
    }
    
    func configureCamera(with dataOutputQueue: DispatchQueue, videoPreviewLayer: AVCaptureVideoPreviewLayer, sessionQueue: DispatchQueue, completion: @escaping (Result<Bool, Error>) -> Void) {
        studio.configureCamera(with: dataOutputQueue, videoPreviewLayer: videoPreviewLayer, sessionQueue: sessionQueue, completion: completion)
    }
    
    func configureMicrophone(with dataOutputQueue: DispatchQueue, sessionQueue: DispatchQueue, completion: @escaping (Result<Bool, Error>) -> Void) {
        studio.configureMicrophone(with: dataOutputQueue, sessionQueue: sessionQueue, completion: completion)
    }
    
    func executeMovieRecord(on dataOutputQueue: DispatchQueue, completion: @escaping (Result<Bool, Error>) -> Void) {
        studio.startRecording(on: dataOutputQueue, completion: completion)
    }
    
    func executeStopMovieRecord(from dataOutPutQueue: DispatchQueue, completion: @escaping (Result<URL, Error>) -> Void) {
        studio.stopRecording(from: dataOutPutQueue, completion: completion)
    }
    
    func executeRequestPhotoAuthorization(completion: @escaping (Bool) -> Void) {
        studio.requestForPhotoAlbumAccess(completion: completion)
    }
    
}
