//
//  DownloadImageOperation.swift
//  Bidirectional CollectionView Example
//
//  Created by Maxım Gaıssın on 09.02.2023.
//

import Foundation
import UIKit

final class DownloadImageOperation: AsyncOperation {
    var callback: ((UIImage?) -> Void)?
    var url: URL?
    private var task: URLSessionDataTask?
    
    private func imageURL() -> URL? {
        if let url = url {
            return url
        } else if let url = dependencies
            .compactMap({($0 as? DownloadURLOperation)?.url})
            .first {
            return url
        } else {
            return nil
        }
    }
    
    override func main() {
        guard let url = imageURL() else {
            return
        }
        task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else {
                return
            }
            defer { self.state = .finished }
            
            guard !self.isCancelled, error == nil,
                  let data = data else {
                return
            }
            
            if let callback = self.callback {
                DispatchQueue.main.async {
                    callback(UIImage(data: data))
                }
            }
        }
        task?.resume()
    }
}
