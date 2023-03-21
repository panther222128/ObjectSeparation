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
    
    lazy var assetWriter: AssetWriter = {
        return DefaultAssetWriter()
    }()
    
    func makeSceneDIContainer() -> SceneDIContainer {
        let dependencies = SceneDIContainer.Dependencies(deviceProvider: deviceProvider, assetWriter: assetWriter)
        return SceneDIContainer(dependencies: dependencies)
    }
    
}
