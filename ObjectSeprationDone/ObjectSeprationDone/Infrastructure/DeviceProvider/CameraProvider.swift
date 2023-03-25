//
//  CameraProvider.swift
//  ObjectSeprationDone
//
//  Created by Horus on 2023/03/23.
//

import AVFoundation

enum CameraError: Error {
    case cannotFindCamera
    case cannotSetupVideoDeviceInput
    case cannotFindVideoDeviceInput
    case cannotFindVideoDeviceInputPort
}

protocol CameraProvidable {
    var camera: AVCaptureDevice? { get }
    var videoDeviceInput: AVCaptureDeviceInput? { get }
    
    func setupVideoDeviceInput(to captureSession: AVCaptureSession) throws
}

final class CameraProvider: CameraProvidable {
    
    private(set) var camera: AVCaptureDevice?
    private(set) var videoDeviceInput: AVCaptureDeviceInput?
    
    init() {
        self.camera = nil
        self.videoDeviceInput = nil
    }
    
    func setupVideoDeviceInput(to captureSession: AVCaptureSession) throws {
        do {
            try configureVideoDeviceInput()
            try addVideoDeviceInput(to: captureSession)
        } catch let error {
            throw error
        }
    }
    
}

extension CameraProvider {
    private func configureVideoDeviceInput() throws {
        do {
            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { throw CameraError.cannotFindCamera }
            self.camera = camera
            videoDeviceInput = try AVCaptureDeviceInput(device: camera)
        } catch {
            throw CameraError.cannotSetupVideoDeviceInput
        }
    }
    
    private func addVideoDeviceInput(to captureSession: AVCaptureSession) throws {
        guard let videoDeviceInput = videoDeviceInput else { throw CameraError.cannotFindVideoDeviceInput }
        if captureSession.canAddInput(videoDeviceInput) {
            captureSession.addInputWithNoConnections(videoDeviceInput)
        } else {
            throw SessionError.cannotAddVideoDeviceInput
        }
    }
}
