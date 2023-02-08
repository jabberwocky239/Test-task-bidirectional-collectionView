//
//  ViewController.swift
//  Bidirectional CollectionView Example
//
//  Created by Maxım Gaıssın on 09.02.2023.
//

import UIKit

class ViewController: UIViewController {
    
    // MARK: Nested Type
    
    enum Section: Int, CaseIterable {
        case horizontal, vertical
        var orthogonalScrollingBehavior: UICollectionLayoutSectionOrthogonalScrollingBehavior {
            switch self {
            case .horizontal:
                return .continuous
            default:
                return .none
            }
        }
    }
    
    // MARK: SubViews
    
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: view.bounds,
            collectionViewLayout: makeLayout()
        )
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        return collectionView
    }()
        
    //MARK: Private properties
    
    private static let imagesNumber: Int = 50
    private let queue = OperationQueue()
    private var urls: [URL?] = .init(repeating: nil, count: 2 * imagesNumber)
    private var operations: [IndexPath: [Operation]] = [:]
    private let cache = NSCache<NSNumber, UIImage>()
    
    private lazy var dataSource: UICollectionViewDiffableDataSource<Int, Int> = {
        let cellProvider = UICollectionView.CellRegistration<ImageCell, Int> {[weak self] (cell, indexPath, identifier) in
            guard let self = self else {
                return
            }
            cell.isLoading = true
            cell.display(image: nil)
            if let cahcedImage = self.cache.object(forKey: NSNumber(value: identifier)) {
                cell.isLoading = false
                cell.display(image: cahcedImage)
            } else if let url = self.urls[identifier] {
                let downloadImageOperation = DownloadImageOperation()
                downloadImageOperation.url = url
                downloadImageOperation.callback = { [weak self] image in
                    guard let cell = self?.collectionView.cellForItem(at: indexPath) as? ImageCell else {
                        return
                    }
                    cell.isLoading = false
                    cell.display(image: image)
                    if let image = image {
                        self?.cache.setObject(image, forKey: NSNumber(value: identifier))
                    }
                }
                self.queue.addOperation(downloadImageOperation)
                
                if let operations = self.operations[indexPath] {
                    operations.forEach({
                        $0.cancel()
                    })
                }
                self.operations[indexPath] = [downloadImageOperation]
            } else {
                let downloadURLOperation = DownloadURLOperation()
                downloadURLOperation.callBack = {[weak self] url in
                    self?.urls[identifier] = url
                }
                let downloadImageOperation = DownloadImageOperation()
                downloadImageOperation.addDependency(downloadURLOperation)
                downloadImageOperation.callback = { [weak self] image in
                    guard let cell = self?.collectionView.cellForItem(at: indexPath) as? ImageCell else {
                        return
                    }
                    cell.isLoading = false
                    cell.display(image: image)
                    if let image = image {
                        self?.cache.setObject(image, forKey: NSNumber(value: identifier))
                    }
                }
                self.queue.addOperation(downloadURLOperation)
                self.queue.addOperation(downloadImageOperation)
                
                if let operations = self.operations[indexPath] {
                    operations.forEach({
                        $0.cancel()
                    })
                }
                self.operations[indexPath] = [downloadURLOperation, downloadImageOperation]
            }
        }
        
        let dataSource = UICollectionViewDiffableDataSource<Int, Int>(collectionView: collectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, identifier: Int) -> UICollectionViewCell? in
            return collectionView.dequeueConfiguredReusableCell(using: cellProvider, for: indexPath, item: identifier)
        }
        return dataSource
    }()
    
    //MARK: LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(collectionView)
        var snapshot = NSDiffableDataSourceSnapshot<Int, Int>()
        var offsetCounter = 0
        Section.allCases.forEach {
            snapshot.appendSections([$0.rawValue])
            let max = offsetCounter + ViewController.imagesNumber
            snapshot.appendItems(Array(offsetCounter..<max))
            offsetCounter += ViewController.imagesNumber
        }
        dataSource.apply(snapshot, animatingDifferences: false)
        cache.countLimit = 100
    }
    
    //MARK: Private methods
    private func makeLayout() -> UICollectionViewCompositionalLayout {
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.interSectionSpacing = 30
        let sectionProvider = { (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            guard let sectionType = Section(rawValue: sectionIndex) else {
                fatalError("sectionType unknown")
            }
            let width = layoutEnvironment.container.contentSize.width
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .fractionalHeight(1)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
            
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .absolute(width),
                    heightDimension: .estimated(width)),
                subitems: [item])
            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = sectionType.orthogonalScrollingBehavior
            
            return section
        }
        let layout = UICollectionViewCompositionalLayout(
            sectionProvider: sectionProvider,
            configuration: config
        )
        
        return layout
    }
}

extension ViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let operations = operations[indexPath] {
          for operation in operations {
            operation.cancel()
          }
        }
    }
}
