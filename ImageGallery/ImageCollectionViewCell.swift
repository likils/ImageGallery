//
//  ImageCollectionViewCell.swift
//  ImageGallery
//
//  Created by Nik on 13.11.2020.
//  Copyright © 2020 Nik. All rights reserved.
//

import UIKit

class ImageCollectionViewCell: UICollectionViewCell {
    
    var imageUrl: URL? {
        didSet {
            guard let url = imageUrl else { return }
            DispatchQueue.global(qos: .userInitiated).async {
                if let data = try? Data(contentsOf: url.imageURL), let image = UIImage(data: data) {
                    DispatchQueue.main.async { [weak self] in
                        self?.activityIndicator.stopAnimating()
                        self?.backgroundImage = image
                    }
                }
            }
        }
    }
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView! {
        didSet { activityIndicator.startAnimating() }
    }
    
    var backgroundImage: UIImage? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect) {
        backgroundImage?.draw(in: bounds)
    }
}
