//
//  DownloadUrlOperation.swift
//  Bidirectional CollectionView Example
//
//  Created by Maxım Gaıssın on 09.02.2023.
//

import UIKit

protocol URLProvider {
    var url: URL? { get }
}

final class DownloadURLOperation: AsyncOperation, URLProvider {
    let hostString = "https://cataas.com/cat/"
    var url: URL?
    
    struct Response: Decodable {
        enum CodingKeys: String, CodingKey {
            case id = "_id"
        }
        let id: String
        
    }
    
    
//    let inputUrl: URL? = URL(string: "https://aws.random.cat/meow")
    let inputUrl: URL? = URL(string: "https://cataas.com/cat?json=true")
    var callBack: ((URL?) -> Void)?
    private var task: URLSessionDataTask?
    
    override func main() {
        guard let url = inputUrl else {
            return
        }
        task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else {
                return
            }
            defer {self.state = .finished }
            
            guard 
                !self.isCancelled,
                error == nil,
                let data = data,
                let response = try? JSONDecoder().decode(Response.self, from: data),
                let url = URL(string: self.hostString + response.id)
            else {
                return
            }
        
            self.url = url
            if let callback = self.callBack {
                print(url)
                callback(url)
            }
        }
        task?.resume()
    }
}
