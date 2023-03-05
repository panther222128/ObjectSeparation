//
//  ViewFlowCoordinator.swift
//  ObjectSeparation
//
//  Created by Horus on 2023/03/04.
//

import UIKit

protocol ViewFlowCoordinatorDependencies {
    func makeTabBarController() -> UITabBarController
    func makeMovieRecordViewController() -> MovieRecordViewController
}

final class ViewFlowCoordinator {
    
    private var navigationController: UINavigationController?
    private weak var tabBarController: UITabBarController?
    private let dependencies: ViewFlowCoordinatorDependencies
    
    private weak var movieRecordViewController: MovieRecordViewController?
    
    init(tabBarController: UITabBarController, dependencies: ViewFlowCoordinatorDependencies) {
        self.tabBarController = tabBarController
        self.dependencies = dependencies
    }
    
    func start() {
        tabBarController?.tabBar.tintColor = .black
        tabBarController?.tabBar.unselectedItemTintColor = .black
        
        let movieRecordViewController = dependencies.makeMovieRecordViewController()
        self.movieRecordViewController = movieRecordViewController
        
        let mainTabBarItem = UITabBarItem(title: "", image: Constants.TabBarImage.asset, tag: 0)
        
        movieRecordViewController.tabBarItem = mainTabBarItem
        
        if let selectedAsset = Constants.TabBarImage.selectedAsset {
            mainTabBarItem.selectedImage = selectedAsset
        }
        
        self.navigationController = UINavigationController()
        guard let navigationController = navigationController else { return }
        tabBarController?.viewControllers = [navigationController]
        self.navigationController?.pushViewController(movieRecordViewController, animated: true)
    }
    
}
