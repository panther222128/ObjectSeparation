//
//  SceneDIContainer.swift
//  ObjectSeprationDone
//
//  Created by Horus on 2023/03/22.
//

import UIKit

final class SceneDIContainer: ViewFlowCoordinatorDependencies {
    
    struct Dependencies {
        let cameraProvidable: CameraProvidable
        let microphoneProvidable: MicrophoneProvidable
        let movieWriter: MovieWriter
    }
    
    private let dependencies: Dependencies
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    func makeTabBarController() -> UITabBarController {
        return UITabBarController()
    }
    
    func makeViewFlowCoordinator(tabBarontroller: UITabBarController) -> ViewFlowCoordinator {
        return ViewFlowCoordinator(tabBarController: tabBarontroller, dependencies: self)
    }
    
    func makeStudio() -> StudioConfigurable {
        return DefaultStudio(cameraProvider: dependencies.cameraProvidable, microphoneProvider: dependencies.microphoneProvidable, movieWriter: dependencies.movieWriter)
    }
    
    func makeMovieRecordRepository() -> MovieRecordRepository {
        return DefaultMovieRecordRepository(studio: makeStudio())
    }
    
    func makeMovieRecordUseCase() -> MovieRecordUseCase {
        return DefaultMovieRecordUseCase(movieRecordRepository: makeMovieRecordRepository())
    }
    
    func makeMovieRecordViewModel() -> MovieRecordViewModel {
        return DefaultMovieRecordViewModel(movieRecordUseCase: makeMovieRecordUseCase())
    }
    
    func makeMovieRecordViewController() -> MovieRecordViewController {
        return MovieRecordViewController.create(with: makeMovieRecordViewModel())
    }
    
}


