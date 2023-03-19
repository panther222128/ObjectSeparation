//
//  AppFlowCoordinator.swift
//  ObjectSeparated
//
//  Created by Horus on 2023/03/19.
//

import UIKit

final class AppFlowCoordinator {

    private let tabBarController: UITabBarController
    private let appDIContainer: AppDIContainer
    
    init(tabBarontroller: UITabBarController, appDIContainer: AppDIContainer) {
        self.tabBarController = tabBarontroller
        self.appDIContainer = appDIContainer
    }
    
    func start() {
        let sceneDIContainer = appDIContainer.makeSceneDIContainer()
        let flow = sceneDIContainer.makeViewFlowCoordinator(tabBarontroller: tabBarController)
        flow.start()
    }
    
}
