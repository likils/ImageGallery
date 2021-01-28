//
//  ImageCollectionViewCell.swift
//  ImageGallery
//
//  Created by Nik on 13.11.2020.
//  Copyright © 2020 Nik. All rights reserved.
//

import UIKit

class ImageCollectionViewCell: UICollectionViewCell {
    
    var imageName: String? {
        didSet {
            if let imageName = imageName {
                DispatchQueue.global().async {
                    let image = ImageGalleries.retrieve(imageNamed: imageName)
                    DispatchQueue.main.async {
                        self.activityIndicator.stopAnimating()
                        self.imageView.image = image
                    }
                }
            }
        }
    }
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView! {
        didSet { activityIndicator.startAnimating() }
    }
}
