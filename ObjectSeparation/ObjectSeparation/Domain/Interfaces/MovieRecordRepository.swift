//
//  MovieRecordRepository.swift
//  ObjectSeparation
//
//  Created by Horus on 2023/03/04.
//

import AVFoundation

protocol MovieRecordRepository {
    func setupSession(with layer: AVCaptureVideoPreviewLayer)
    func configureCamera(with dataOutputQueue: DispatchQueue, videoPreviewLayer: AVCaptureVideoPreviewLayer)
    func configureMicrophone(with dataOutputQueue: DispatchQueue)
}
