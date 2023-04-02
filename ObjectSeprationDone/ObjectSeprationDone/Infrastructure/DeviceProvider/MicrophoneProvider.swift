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
    case cannotFindAudioDeviceInput
    case cannotFindAudioDeviceInputPort
}

protocol MicrophoneProvidable {
    var microphone: AVCaptureDevice? { get }
    var audioDeviceInput: AVCaptureDeviceInput? { get }
    
    func prepareAudioDeviceInput(for captureSession: AVCaptureSession) throws
}

final class MicrophoneProvider: MicrophoneProvidable {
    
    private(set) var microphone: AVCaptureDevice?
    private(set) var audioDeviceInput: AVCaptureDeviceInput?
    
    init() {
        self.microphone = nil
        self.audioDeviceInput = nil
    }
    
    func prepareAudioDeviceInput(for captureSession: AVCaptureSession) throws {
        do {
            try configureAudioDeviceInput()
            try addAudioDeviceInput(to: captureSession)
        } catch let error {
            throw error
        }
    }
    
}

extension MicrophoneProvider {
    private func configureAudioDeviceInput() throws {
        do {
            guard let microphone = AVCaptureDevice.default(for: .audio) else { throw MicrophoneError.cannotFindMicrophone }
            self.microphone = microphone
            audioDeviceInput = try AVCaptureDeviceInput(device: microphone)
        } catch {
            throw MicrophoneError.cannotSetupAudioDeviceinput
        }
    }
    
    private func addAudioDeviceInput(to captureSession: AVCaptureSession) throws {
        guard let audioDeviceInput = audioDeviceInput else { throw MicrophoneError.cannotFindAudioDeviceInput }
        if captureSession.canAddInput(audioDeviceInput) {
            captureSession.addInputWithNoConnections(audioDeviceInput)
        } else {
            throw SessionError.cannotAddAudioDeviceInput
        }
    }
}
