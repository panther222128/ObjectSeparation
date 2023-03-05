//
//  AppDIContainer.swift
//  ObjectSeparation
//
//  Created by Horus on 2023/03/04.
//

import Foundation

final class AppDIContainer {

    lazy var appConfiguration = AppConfiguration()
    
    func makeSceneDIContainer() -> SceneDIContainer {
        let dependencies = SceneDIContainer.Dependencies()
        return SceneDIContainer(dependencies: dependencies)
    }
    
}
