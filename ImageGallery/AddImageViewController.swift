//
//  AddImageViewController.swift
//  ImageGallery
//
//  Created by likils on 18.01.2021.
//  Copyright © 2021 likils. All rights reserved.
//

import UIKit
import MobileCoreServices

class AddImageViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPopoverPresentationControllerDelegate {
    // MARK: Properties
    weak var collectionVC: ImageGalleryCollectionViewController?
    
    var cells: [(UIImage?, String)] {
        if #available(iOS 13.0, *) {
            return [(UIImage(systemName: "camera"), "Camera"), (UIImage(systemName: "photo"), "Photo Library")]
        } else {
            return [(UIImage(named: "camera"), "Camera"), (UIImage(named: "photo"),"Photo Library")]
        }
    } 
    
    @IBOutlet weak var tableView: UITableView! {
        didSet { tableView.isScrollEnabled = false }
    }
    
    // MARK: - View size setting
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let cell = tableView.visibleCells[1]
        let width = cell.textLabel!.intrinsicContentSize.width + cell.imageView!.intrinsicContentSize.width
        let height = cell.frame.size.height
        preferredContentSize = CGSize(width: width*1.4, height: height*CGFloat(tableView.visibleCells.count) - 1)
    }
    
    // MARK: - Table View DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AddImageCell", for: indexPath)
        cell.imageView?.image = cells[indexPath.row].0
        cell.textLabel?.text = cells[indexPath.row].1
        return cell
    }
    
    // MARK: - Image Picker Setup
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let picker = UIImagePickerController()
        picker.mediaTypes = [kUTTypeImage as String]
        picker.allowsEditing = true
        picker.delegate = self
        if indexPath == IndexPath(row: 0, section: 0), UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        } else if indexPath == IndexPath(row: 1, section: 0), UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            picker.sourceType = .photoLibrary
            picker.modalPresentationStyle = .popover
            picker.popoverPresentationController?.sourceView = tableView
        }
        present(picker, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = (info[UIImagePickerController.InfoKey.editedImage] ?? info[UIImagePickerController.InfoKey.originalImage]) as? UIImage {
            let name = "\(Date().timeIntervalSince1970)"
            do { try ImageGalleries.store(image: image, name: name) }
            catch let error { print(error.localizedDescription) }
            
            collectionVC?.gallery.insert(name, at: 0)
            collectionVC?.collectionView.reloadSections(IndexSet(integer: 0))
        }
        picker.presentingViewController?.dismiss(animated: true)
        self.presentingViewController?.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.presentingViewController?.dismiss(animated: true)
    }
}
