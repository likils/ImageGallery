//
//  DetailViewController.swift
//  ImageGallery
//
//  Created by likils on 18.12.2020.
//  Copyright © 2020 likils. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController, UIScrollViewDelegate {
    // MARK: Image display setup
    var image: UIImage?
    
    @IBOutlet weak var scrollView: UIScrollView! {
        didSet {
            scrollView.minimumZoomScale = 0.1
            scrollView.maximumZoomScale = 5.0
            scrollView.delegate = self
        }
    }
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var scrollViewWidth: NSLayoutConstraint!
    @IBOutlet weak var scrollViewHeight: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let image = image {
            imageView.image = image
            imageView.frame = CGRect(origin: CGPoint.zero, size: image.size)
            scrollView.contentSize = image.size
            scrollViewHeight.constant = scrollView.contentSize.height
            scrollViewWidth.constant = scrollView.contentSize.width
            fitImage()
            navigationController?.isNavigationBarHidden = true
            navigationController?.hidesBarsOnTap = true
        }
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(fitImage))
        tapGesture.numberOfTouchesRequired = 2
        view.addGestureRecognizer(tapGesture)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.hidesBarsOnTap = false
    }
    
    // MARK: - ScrollView zoom setup
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        scrollViewHeight.constant = scrollView.contentSize.height
        scrollViewWidth.constant = scrollView.contentSize.width
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }
    
    @objc func fitImage() {
        guard let image = image else {return}
        scrollView.zoomScale = min(view.frame.size.width / image.size.width, view.frame.size.height / image.size.height)
    }
}
