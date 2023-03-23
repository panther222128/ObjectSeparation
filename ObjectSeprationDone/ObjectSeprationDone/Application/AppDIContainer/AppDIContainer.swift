//
//  AppDIContainer.swift
//  ObjectSeprationDone
//
//  Created by Horus on 2023/03/22.
//

import Foundation

final class AppDIContainer {

    lazy var appConfiguration = AppConfiguration()
    
    lazy var cameraProvider: CameraProvidable = {
        return CameraProvider()
    }()
    
    lazy var microphoneProvider: MicrophoneProvidable = {
        return MicrophoneProvider()
    }()
    
    lazy var assetWriter: AssetWriter = {
        return DefaultAssetWriter()
    }()
    
    func makeSceneDIContainer() -> SceneDIContainer {
        let dependencies = SceneDIContainer.Dependencies(cameraProvidable: cameraProvider, microphoneProvidable: microphoneProvider, assetWriter: assetWriter)
        return SceneDIContainer(dependencies: dependencies)
    }
    
}
