//
//  ViewController.swift
//  ObjectSeparation
//
//  Created by Horus on 2023/03/04.
//

import UIKit
import AVFoundation
import Photos

class MovieRecordViewController: UIViewController {
    
    @IBOutlet weak var videoPreviewView: PreviewView!
    
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
    
    private func checkDeviceAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.main.async {
                self.viewModel.setupSession(with: self.videoPreviewView.videoPreviewLayer, on: self.sessionQueue)
                self.viewModel.configureCamera(with: self.dataOutputQueue, videoPreviewLayer: self.videoPreviewView.videoPreviewLayer, sessionQueue: self.sessionQueue)
                self.viewModel.configureMicrophone(with: self.dataOutputQueue, sessionQueue: self.sessionQueue)
            }
            
        case .denied:
            return
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { [weak self] isAuthorized in
                if isAuthorized {
                    DispatchQueue.main.async {
                        guard let dataOutputQueue = self?.dataOutputQueue else { return }
                        guard let sessionQueue = self?.sessionQueue else { return }
                        self?.viewModel.setupSession(with: self?.videoPreviewView.videoPreviewLayer ?? AVCaptureVideoPreviewLayer(), on: sessionQueue)
                        self?.viewModel.configureCamera(with: dataOutputQueue, videoPreviewLayer: self?.videoPreviewView.videoPreviewLayer ?? AVCaptureVideoPreviewLayer(), sessionQueue: sessionQueue)
                        self?.viewModel.configureMicrophone(with: dataOutputQueue, sessionQueue: sessionQueue)
                    }
                } else {
                    return
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

}

