//
//  MicrophoneProvider.swift
//  ObjectSeprationDone
//
//  Created by Horus on 2023/03/23.
//

import AVFoundation

enum MicrophoneError: Error {
    case cannotFindMicrophone
    case cannotSetupAudioDeviceinput
}

protocol MicrophoneProvidable {
    var microphone: AVCaptureDevice? { get }
    var audioDeviceInput: AVCaptureDeviceInput? { get }
    
    func setupAudioDeviceInput(to captureSession: AVCaptureSession) throws
}

final class MicrophoneProvider: MicrophoneProvidable {
    
    private(set) var microphone: AVCaptureDevice?
    private(set) var audioDeviceInput: AVCaptureDeviceInput?
    
    init() {
        self.microphone = nil
        self.audioDeviceInput = nil
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

// MARK: - Audio
extension MicrophoneProvider {
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
