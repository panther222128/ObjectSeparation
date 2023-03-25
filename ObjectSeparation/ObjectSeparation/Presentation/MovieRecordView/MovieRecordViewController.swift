//
//  ViewController.swift
//  ObjectSeparation
//
//  Created by Horus on 2023/03/04.
//

import UIKit
import AVFoundation
import Photos

enum AuthorizationError: String, Error {
    case cameraNotAuthorized = "Camera authorization"
}

final class MovieRecordViewController: UIViewController {
    
    @IBOutlet weak var videoPreviewView: PreviewView!
    @IBOutlet weak var recordButton: RecordButton!
    
    static let storyboardName = "MovieRecordViewController"
    static let storyboardID = "MovieRecordViewController"
    
    private let dataOutputQueue: DispatchQueue = DispatchQueue(label: "DataOutputQueue")
    private let sessionQueue: DispatchQueue = DispatchQueue(label: "SessionQueue")
    
    private var viewModel: MovieRecordViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkDeviceAuthorization()
    }
    
    static func create(with viewModel: MovieRecordViewModel) -> MovieRecordViewController {
        let storyboard = UIStoryboard(name: storyboardName, bundle: Bundle.main)
        guard let viewController = storyboard.instantiateViewController(withIdentifier: storyboardID) as? MovieRecordViewController else { return .init() }
        viewController.viewModel = viewModel
        return viewController
    }
    
    private func presentAlert(of error: Error) {
        let alert = UIAlertController(title: Constants.AlertMessages.errorTitle, message: "\(error)", preferredStyle: UIAlertController.Style.alert)
        let addAlertAction = UIAlertAction(title: Constants.AlertMessages.ok, style: .default)
        alert.addAction(addAlertAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    private func checkDeviceAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.main.async {
                self.viewModel.startSession(on: self.sessionQueue, with: self.videoPreviewView.videoPreviewLayer)
                self.viewModel.configureCamera(with: self.dataOutputQueue, videoPreviewLayer: self.videoPreviewView.videoPreviewLayer, sessionQueue: self.sessionQueue)
            }
            self.viewModel.configureMicrophone(with: self.dataOutputQueue, sessionQueue: self.sessionQueue)
            
        case .denied:
            presentAlert(of: AuthorizationError.cameraNotAuthorized)
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { [weak self] isAuthorized in
                if isAuthorized {
                        guard let dataOutputQueue = self?.dataOutputQueue else { return }
                        guard let sessionQueue = self?.sessionQueue else { return }
                    DispatchQueue.main.async {
                        self?.viewModel.startSession(on: sessionQueue, with: self?.videoPreviewView.videoPreviewLayer ?? AVCaptureVideoPreviewLayer())
                        self?.viewModel.configureCamera(with: dataOutputQueue, videoPreviewLayer: self?.videoPreviewView.videoPreviewLayer ?? AVCaptureVideoPreviewLayer(), sessionQueue: sessionQueue)
                    }
                    self?.viewModel.configureMicrophone(with: dataOutputQueue, sessionQueue: sessionQueue)
                    
                } else {
                    self?.presentAlert(of: AuthorizationError.cameraNotAuthorized)
                }
            })
            
        default:
            return
            
        }
    }
    
    private func requestForPhotoAlbumAccess(completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { authorizationStatus in
            switch authorizationStatus {
            case .authorized:
                completion(true)
            default:
                completion(false)
            }
        }
    }
    
    @IBAction func recordButtonAction(_ sender: Any) {
        recordButton.toggle()
    }
    
}

