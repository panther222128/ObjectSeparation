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
    
    lazy var movieWriter: MovieWriter = {
        return DefaultMovieWriter()
    }()
    
    func makeSceneDIContainer() -> SceneDIContainer {
        let dependencies = SceneDIContainer.Dependencies(cameraProvidable: cameraProvider, microphoneProvidable: microphoneProvider, movieWriter: movieWriter)
        return SceneDIContainer(dependencies: dependencies)
    }
    
}
