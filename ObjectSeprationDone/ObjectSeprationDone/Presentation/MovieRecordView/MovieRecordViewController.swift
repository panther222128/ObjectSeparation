//
//  MovieRecordViewController.swift
//  ObjectSeprationDone
//
//  Created by Horus on 2023/03/22.
//

import UIKit
import AVFoundation
import Photos
import Combine

enum AuthorizationError: String, Error {
    case cameraNotAuthorized = "Camera authorization"
    case photoLibraryNotAuthorized = "Photo library authorization"
}

final class MovieRecordViewController: UIViewController {
    
    @IBOutlet weak var videoPreviewView: PreviewView!
    @IBOutlet weak var recordButton: RecordButton!
    
    static let storyboardName = "MovieRecordViewController"
    static let storyboardID = "MovieRecordViewController"
    
    private let dataOutputQueue: DispatchQueue = DispatchQueue(label: "DataOutputQueue")
    private let sessionQueue: DispatchQueue = DispatchQueue(label: "SessionQueue")
    private var cancellables: Set<AnyCancellable> = []
    
    private weak var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    private var viewModel: MovieRecordViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        videoPreviewLayer = videoPreviewView.videoPreviewLayer
        viewModel.startSession(on:sessionQueue, with: videoPreviewLayer ?? .init())
        subscribeError()
        viewModel.requestPhotoAuthorization { [weak self] isSuccess in
            switch isSuccess {
            case true:
                return
                
            case false:
                self?.presentAlert(of: AuthorizationError.photoLibraryNotAuthorized)
                
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        checkDeviceAuthorization()
    }
    
    static func create(with viewModel: MovieRecordViewModel) -> MovieRecordViewController {
        let storyboard = UIStoryboard(name: storyboardName, bundle: Bundle.main)
        guard let viewController = storyboard.instantiateViewController(withIdentifier: storyboardID) as? MovieRecordViewController else { return .init() }
        viewController.viewModel = viewModel
        return viewController
    }
    
    private func subscribeError() {
        viewModel.error
            .sink { [weak self] error in
                self?.presentAlert(of: error)
            }
            .store(in: &cancellables)
    }
    
    private func presentAlert(of error: Error) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: Constants.AlertMessages.errorTitle, message: "\(error)", preferredStyle: UIAlertController.Style.alert)
            let addAlertAction = UIAlertAction(title: Constants.AlertMessages.ok, style: .default)
            alert.addAction(addAlertAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func checkDeviceAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.viewModel.configureCamera(with: self.dataOutputQueue, videoPreviewLayer: self.videoPreviewLayer ?? .init(), sessionQueue: self.sessionQueue)
            self.viewModel.configureMicrophone(with: self.dataOutputQueue, sessionQueue: self.sessionQueue)
            self.viewModel.runSession(on: sessionQueue)
            
        case .denied:
            presentAlert(of: AuthorizationError.cameraNotAuthorized)
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { [weak self] isAuthorized in
                if isAuthorized {
                    guard let dataOutputQueue = self?.dataOutputQueue else { return }
                    guard let sessionQueue = self?.sessionQueue else { return }
                    self?.viewModel.configureCamera(with: dataOutputQueue, videoPreviewLayer: self?.videoPreviewLayer ?? .init(), sessionQueue: sessionQueue)
                    self?.viewModel.configureMicrophone(with: dataOutputQueue, sessionQueue: sessionQueue)
                    self?.viewModel.runSession(on: sessionQueue)
                } else {
                    self?.presentAlert(of: AuthorizationError.cameraNotAuthorized)
                }
            })
            
        default:
            return
            
        }
    }
    
    @IBAction func recordButtonAction(_ sender: Any) {
        recordButton.toggle()
        if recordButton.isSelected {
            viewModel.didStartMovieRecord(on: dataOutputQueue)
        } else {
            viewModel.didStopMovieRecord(from: dataOutputQueue)
        }
    }
    
}
