//
//  PhotoLibrarian.swift
//  ObjectSeprationDone
//
//  Created by Horus on 2023/04/05.
//

import Photos

protocol PhotoLibrarian {
    func saveMovieToPhotoLibrary(_ movieURL: URL, completion: @escaping (Result<URL, Error>) -> Void)
    func requestForPhotoAlbumAccess(completion: @escaping (Bool) -> Void)
}

final class DefaultPhotoLibrarian: PhotoLibrarian {
    
    init() {
        
    }
    
    func saveMovieToPhotoLibrary(_ movieURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    let options = PHAssetResourceCreationOptions()
                    options.shouldMoveFile = true
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    creationRequest.addResource(with: .video, fileURL: movieURL, options: options)
                }, completionHandler: { success, error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        if FileManager.default.fileExists(atPath: movieURL.path) {
                            do {
                                try FileManager.default.removeItem(atPath: movieURL.path)
                            } catch {
                                completion(.failure(PhotoLibraryError.cannotCleanUpMovieFile))
                            }
                        }
                        completion(.success(movieURL))
                    }
                })
            } else {
                completion(.failure(PhotoLibraryError.notAuthorized))
            }
        }
    }
    
    func requestForPhotoAlbumAccess(completion: @escaping (Bool) -> Void) {
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
