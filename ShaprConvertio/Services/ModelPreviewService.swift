//
//  ModelPreviewService.swift
//  ShaprConvertio
//
//  Created by Shreyash Shah on 10/02/24.
//

import Foundation
import UIKit

class ModelPreviewService {
    typealias LoadingResult = ((Result<UIImage, Error>) -> (Void))
    
    enum Resolution: Int {
        case low = 108
        case sd = 540
        case hd = 1080
    }
    
    // TODO: Will be implemented with graphics engine for actual 3D model previews
    func loadModelPreview(from url: URL,
                          resolution: Resolution,
                          onLoaded: @escaping LoadingResult) {}
        
    class Mock: ModelPreviewService {
        var cache: [URL: UIImage] /// - Note In Memory Mocked Cache for loaded images, ideally this should be a disk cache
        var seed: Int
        override init() {
            cache = [:]
            seed = 1000
            super.init()
        }
        
        override func loadModelPreview(from url: URL,
                                       resolution: Resolution,
                                       onLoaded: @escaping LoadingResult) {
            let cacheURL = url.appendingPathComponent("\(resolution.rawValue)")
            if let cachedImage = cache[cacheURL] {
                onLoaded(.success(cachedImage))
                return
            } else {
                /// - Note Use picsum to load random images based on arbitrary id from model Id
                self.seed += 1
                guard let imageURL = URL(string: "https://picsum.photos/id/\(seed)")?
                    .appendingPathComponent("\(resolution.rawValue)")
                    .appendingPathComponent("\(resolution.rawValue)")
                else {
                    onLoaded(.failure(AppError.somethingWentWrong))
                    return
                }
                             
                let request = URLRequest(url: imageURL,
                                         cachePolicy: .returnCacheDataElseLoad) /// - Note This mimics caching for model metadata (ex loading shaders, serializing mesh, loading materials & textures etc.)
                
                URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
                    /// - Note Resolution is will be used to simulate delay in loading preview
                    let mockModelLoadingDelay: DispatchTime = .now() + .microseconds(resolution.rawValue * 2) + .microseconds(Int.random(in: 0...2000))
                    
                    if let data = data, let downloadedImage = UIImage(data: data) {
                        DispatchQueue.main.asyncAfter(deadline: mockModelLoadingDelay) {
                            self?.cache[cacheURL] = downloadedImage
                            onLoaded(.success(downloadedImage))
                        }
                    } else {
                        print("Error loading image from URL: \(String(describing: error))")
                        DispatchQueue.main.asyncAfter(deadline: mockModelLoadingDelay) {
                            onLoaded(.failure(error ?? AppError.somethingWentWrong))
                        }
                    }
                }.resume()
            }
            
        }
    }
}
