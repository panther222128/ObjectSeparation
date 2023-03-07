//
//  MovieRecordRepository.swift
//  ObjectSeparation
//
//  Created by Horus on 2023/03/04.
//

import AVFoundation

protocol MovieRecordRepository {
    func startSession(on sessionQueue: DispatchQueue, with layer: AVCaptureVideoPreviewLayer)
    func configureCamera(with dataOutputQueue: DispatchQueue, videoPreviewLayer: AVCaptureVideoPreviewLayer, sessionQueue: DispatchQueue)
    func configureMicrophone(with dataOutputQueue: DispatchQueue, sessionQueue: DispatchQueue)
}
