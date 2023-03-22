//
//  SceneDelegate.swift
//  ObjectSeprationDone
//
//  Created by Horus on 2023/03/22.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    private let appDIContainer = AppDIContainer()
    private var appFlowCoordinator: AppFlowCoordinator?
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        let tabBarController = UITabBarController()

        window?.rootViewController = tabBarController
        self.appFlowCoordinator = AppFlowCoordinator(tabBarontroller: tabBarController, appDIContainer: appDIContainer)
        
        self.appFlowCoordinator?.start()
        window?.makeKeyAndVisible()
    }

}
