//
//  DeviceProvider.swift
//  ObjectSeparated
//
//  Created by Horus on 2023/03/21.
//

import AVFoundation

enum DeviceError: Error {
    case cannotFindCamera
    case cannotSetupVideoDeviceInput
    case cannotFindVideoDeviceInput
    case cannotFindMicrophone
    case cannotSetupAudioDeviceinput
}

protocol DeviceProvidable {
    var camera: AVCaptureDevice? { get }
    var microphone: AVCaptureDevice? { get }
    var videoDeviceInput: AVCaptureDeviceInput? { get }
    var audioDeviceInput: AVCaptureDeviceInput? { get }
    
    func setupVideoDeviceInput(to captureSession: AVCaptureSession) throws
    func setupAudioDeviceInput(to captureSession: AVCaptureSession) throws
}

final class DeviceProvider: DeviceProvidable {
    
    private(set) var camera: AVCaptureDevice?
    private(set) var microphone: AVCaptureDevice?
    private(set) var videoDeviceInput: AVCaptureDeviceInput?
    private(set) var audioDeviceInput: AVCaptureDeviceInput?
    
    init() {
        self.camera = nil
        self.microphone = nil
        self.videoDeviceInput = nil
        self.audioDeviceInput = nil
    }
    
    func setupVideoDeviceInput(to captureSession: AVCaptureSession) throws {
        do {
            try configureVideoDeviceInput()
            try addVideoDeviceInput(to: captureSession)
        } catch let error {
            throw error
        }
    }
    
    func setupAudioDeviceInput(to captureSession: AVCaptureSession) throws {
        do {
            try configureAudioDeviceInput()
            try addAudioDeviceInput(to: captureSession)
        } catch let error {
            throw error
        }
    }
    
}

// MARK: - Video
extension DeviceProvider {
    private func configureVideoDeviceInput() throws {
        do {
            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { throw DeviceError.cannotFindCamera }
            self.camera = camera
            videoDeviceInput = try AVCaptureDeviceInput(device: camera)
        } catch {
            throw DeviceError.cannotSetupVideoDeviceInput
        }
    }
    
    private func addVideoDeviceInput(to captureSession: AVCaptureSession) throws {
        guard let videoDeviceInput = videoDeviceInput else { throw DeviceError.cannotFindVideoDeviceInput }
        if captureSession.canAddInput(videoDeviceInput) {
            captureSession.addInputWithNoConnections(videoDeviceInput)
        } else {
            throw SessionError.cannotAddVideoDeviceInput
        }
    }
}

// MARK: - Audio
extension DeviceProvider {
    private func configureAudioDeviceInput() throws {
        do {
            guard let microphone = AVCaptureDevice.default(for: .audio) else { throw DeviceError.cannotFindMicrophone }
            self.microphone = microphone
            audioDeviceInput = try AVCaptureDeviceInput(device: microphone)
        } catch {
            throw DeviceError.cannotSetupAudioDeviceinput
        }
    }
    
    private func addAudioDeviceInput(to captureSession: AVCaptureSession) throws {
        guard let audioDeviceInput = audioDeviceInput else { throw StudioError.cannotFindAudioDeviceInput }
        if captureSession.canAddInput(audioDeviceInput) {
            captureSession.addInputWithNoConnections(audioDeviceInput)
        } else {
            throw SessionError.cannotAddAudioDeviceInput
        }
    }
}
