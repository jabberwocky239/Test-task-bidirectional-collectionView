//
//  ImageCell.swift
//  Bidirectional CollectionView Example
//
//  Created by Maxım Gaıssın on 09.02.2023.
//

import UIKit

class ImageCell: UICollectionViewCell {
    //MARK: Subviews
    private var activityIndicator: UIActivityIndicatorView
    private var imageView: UIImageView
    
    var isLoading: Bool {
        get { activityIndicator.isAnimating }
        set { newValue ? activityIndicator.startAnimating() : activityIndicator.stopAnimating() }
    }
    
    //MARK: Init
    override init(frame: CGRect) {
        activityIndicator = UIActivityIndicatorView(style: .medium)
        imageView = UIImageView()
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal Methods
    func display(image: UIImage?) {
        imageView.image = image
        imageView.contentMode = .scaleAspectFill
        clipsToBounds = true
    }
    
    //MARK: Private methods
    private func setup() {
        addSubview(activityIndicator)
        activityIndicator.center = CGPoint(x: bounds.size.width/2, y: bounds.size.height/2)
        addSubview(imageView)
        imageView.frame = bounds
    }
}
