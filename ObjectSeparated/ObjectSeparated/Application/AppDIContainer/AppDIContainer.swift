//
//  AppDIContainer.swift
//  ObjectSeparated
//
//  Created by Horus on 2023/03/19.
//

import Foundation

final class AppDIContainer {

    lazy var appConfiguration = AppConfiguration()
    
    lazy var deviceProvider: DeviceProvidable = {
        return DeviceProvider()
    }()
    
    lazy var movieWriter: MovieWriter = {
        return DefaultMovieWriter()
    }()
    
    lazy var photoLibrarian: PhotoLibrarian = {
        return DefaultPhotoLibrarian()
    }()
    
    func makeSceneDIContainer() -> SceneDIContainer {
        let dependencies = SceneDIContainer.Dependencies(deviceProvider: deviceProvider, movieWriter: movieWriter, photoLibrarian: photoLibrarian)
        return SceneDIContainer(dependencies: dependencies)
    }
    
}
