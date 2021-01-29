//
//  ImageGalleryCollectionViewController.swift
//  ImageGallery
//
//  Created by likils on 13.11.2020.
//  Copyright © 2020 likils. All rights reserved.
//

import UIKit

class ImageGalleryCollectionViewController: UICollectionViewController, UIPopoverPresentationControllerDelegate {
    // MARK: Properties
    weak var galleriesTVC: GalleriesTableViewController?
    
    var gallery: [String] {
        get {
            if let gallery = galleriesTVC?.galleriesImages[title!] {
                return gallery
            } else {
                return [String]()
            }
        }
        set {
            galleriesTVC?.galleriesImages[title!] = newValue
            stubLabel.text = nil
        }
    }

    // MARK: - Collection display setup
    private let spaceAroundItems: CGFloat = 8
    private var cellsInRow: CGFloat = 3
    private let minimumCellWidth : CGFloat = 50     /// limit of cells in row
    private var cellWidth: CGFloat! {
        didSet {
            if cellWidth >= minimumCellWidth { 
                cellsInRow = ((collectionView.bounds.size.width - spaceAroundItems*(cellsInRow+1))/cellWidth).rounded(.down)
            }
        }
    }
    
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var stubLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if UIDevice.current.userInterfaceIdiom == .pad {
            navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
            splitViewController?.preferredDisplayMode = .primaryOverlay
        }
        
        stubLabel.text = galleriesTVC == nil ? "Add gallery": gallery.isEmpty ? "Add or Drag & Drop Image here" : nil
        
        setupInteraction()
        setupFlow()
    }
    
    private func setupInteraction() {
        if galleriesTVC == nil {
            navigationItem.rightBarButtonItems = nil
        } else {
            collectionView.dragDelegate = self
            collectionView.dropDelegate = self
            collectionView.dragInteractionEnabled = true // for iphone
            
            let deleteBarItem = UIBarButtonItem(customView: UIView(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 56, height: 44))))
            let imageView = UIImageView(frame: CGRect(origin: CGPoint.zero, size: deleteBarItem.customView!.frame.size))
            deleteBarItem.customView?.addSubview(imageView)
            if #available(iOS 13.0, *) {
                imageView.image = UIImage(systemName: "trash")
                imageView.contentMode = .right
            } else {
                imageView.image = UIImage(named: "trash")
                imageView.contentMode = .scaleAspectFit
            }
            deleteBarItem.customView?.addInteraction(UIDropInteraction(delegate: self))
            navigationItem.rightBarButtonItems? += [deleteBarItem]
            
            let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(resizeCells))
            collectionView.addGestureRecognizer(pinchGesture)
        }
    }
        
    private func setupFlow() {
        flowLayout.sectionInset = UIEdgeInsets(top: spaceAroundItems, left: spaceAroundItems, bottom: spaceAroundItems, right: spaceAroundItems)
        flowLayout.minimumLineSpacing = spaceAroundItems
        flowLayout.minimumInteritemSpacing = spaceAroundItems
        cellWidth = (collectionView.bounds.size.width - spaceAroundItems*(cellsInRow+1)) / cellsInRow
        flowLayout.itemSize = CGSize(width: cellWidth, height: cellWidth)
    }
    
    // MARK: - Actions
    @objc func resizeCells(_ sender: UIPinchGestureRecognizer) {
        switch sender.state {
            case .changed, .ended:
                if (cellWidth * sender.scale) <= (collectionView.bounds.size.width - spaceAroundItems*2) {
                    cellWidth *= sender.scale
                    flowLayout.itemSize = CGSize(width: cellWidth, height: cellWidth)
                    if sender.state == .ended {
                        if cellWidth < minimumCellWidth { cellWidth = minimumCellWidth }
                        cellWidth = (collectionView.bounds.size.width - spaceAroundItems*(cellsInRow+1)) / cellsInRow
                        UIView.animate(withDuration: 0.7) { 
                            self.flowLayout.itemSize = CGSize(width: self.cellWidth, height: self.cellWidth)
                        }
                    }
                }
                sender.scale = 1.0
            default: break
        }
    }
    
    // MARK: - DataSource
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        gallery.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCollectionViewCell
        cell.imageName = gallery[indexPath.item]
        return cell
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "DetailVCSegue", let detailVC = segue.destination as? DetailViewController {
            detailVC.title = "Picture"
            let indexPath = collectionView.indexPathsForSelectedItems![0]
            let cell = collectionView.cellForItem(at: indexPath) as! ImageCollectionViewCell
            detailVC.image = cell.imageView.image
        }
        if segue.identifier == "AddImageSegue",
           let destination = segue.destination.contents as? AddImageViewController,
           let ppc = destination.popoverPresentationController {
            destination.collectionVC = self
            ppc.delegate = self // for iphone like ipad popover
        }
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none // for iphone like ipad popover
    }
}

// MARK: - Drag&Drop
extension ImageGalleryCollectionViewController: UICollectionViewDragDelegate, UICollectionViewDropDelegate, UIDropInteractionDelegate {
    
    // MARK: Drag items from gallery
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        session.localContext = collectionView
        return dragItems(at: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        return dragItems(at: indexPath)
    }
    
    private func dragItems(at indexPath: IndexPath) -> [UIDragItem] {
        var dragItems = [UIDragItem]()
        if let item = (collectionView.cellForItem(at: indexPath) as? ImageCollectionViewCell)?.imageName as NSString? {
            let itemForDrag = UIDragItem(itemProvider: NSItemProvider(object: item))
            itemForDrag.localObject = item
            dragItems.append(itemForDrag)
        }
        return dragItems
    }
    
    // MARK: Drop items to gallery
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        session.canLoadObjects(ofClass: UIImage.self) || session.canLoadObjects(ofClass: NSString.self)
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        let isSelf = (session.localDragSession?.localContext as? UICollectionView) == collectionView
        return UICollectionViewDropProposal(operation: isSelf ? .move : .copy, intent: .insertAtDestinationIndexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item: gallery.count, section: 0)
        for item in coordinator.items {
            if let sourceIndexPath = item.sourceIndexPath, (item.dragItem.localObject as? NSString) != nil {
                guard coordinator.destinationIndexPath != nil else { return }
                let image = gallery.remove(at: sourceIndexPath.item)
                gallery.insert(image, at: destinationIndexPath.item)
                collectionView.performBatchUpdates {
                    collectionView.deleteItems(at: [sourceIndexPath])
                    collectionView.insertItems(at: [destinationIndexPath])
                }
                coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
            } else {
                item.dragItem.itemProvider.loadObject(ofClass: NSString.self) { (provider, error) in
                    if let imageName = provider as? String, Double(imageName) != nil { // Double() need to not add string from external places via drag&drop
                        DispatchQueue.main.async {
                            self.gallery.insert(imageName, at: destinationIndexPath.item)
                            self.collectionView.insertItems(at: [destinationIndexPath])
                        }
                    }
                }
                
                item.dragItem.itemProvider.loadObject(ofClass: UIImage.self) { (provider, error) in
                    if let image = provider as? UIImage {
                        
                        let name = "\(Date().timeIntervalSince1970)"
                        do { try ImageGalleries.store(image: image, name: name) }
                        catch let error { print(error.localizedDescription) }
                        
                        DispatchQueue.main.async {
                            self.gallery.insert(name, at: destinationIndexPath.item)
                            self.collectionView.insertItems(at: [destinationIndexPath])
                        }
                    }
                }
            }
        }
    }
    
    // MARK: Delete items via deleteBarItem
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        session.canLoadObjects(ofClass: NSString.self)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        UIDropProposal(operation: .move)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        guard session.localDragSession != nil else { return }
        session.items.forEach {
            if let object = $0.localObject as? String,
               let index = gallery.firstIndex(where: { $0 == object }) {
                let name = gallery.remove(at: index)
                galleriesTVC?.imageGalleries.checkIfImageExistInOtherGalleries(named: name)
                
                collectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
            }
            if gallery.isEmpty {
                stubLabel.text = "Add or Drag & Drop Image here"
            }
        }
    }
}
