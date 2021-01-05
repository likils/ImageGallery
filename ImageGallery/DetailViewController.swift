//
//  DetailViewController.swift
//  ImageGallery
//
//  Created by Nik on 18.12.2020.
//  Copyright © 2020 Nik. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController, UIScrollViewDelegate {
    
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
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(fitImage))
        doubleTapGesture.numberOfTouchesRequired = 2
        view.addGestureRecognizer(doubleTapGesture)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.hidesBarsOnTap = false
    }
    
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
