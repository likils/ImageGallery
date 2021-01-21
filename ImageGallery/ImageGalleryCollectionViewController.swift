//
//  ImageGalleryCollectionViewController.swift
//  ImageGallery
//
//  Created by Nik on 13.11.2020.
//  Copyright © 2020 Nik. All rights reserved.
//

import UIKit

class ImageGalleryCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UIPopoverPresentationControllerDelegate {
    // MARK: Properties
    weak var galleriesTVC: GalleriesTableViewController?
    
    var gallery: [UIImage] {
        get {
            if let gallery = galleriesTVC?.galleriesImages[title!] {
                return gallery
            } else {
                return [UIImage]()
            }
        }
        set {
            galleriesTVC?.galleriesImages[title!] = newValue
        }
    }

    // MARK: - Collection display setup
    private let spaceAroundItems: CGFloat = 8
    private var cellsInRow: CGFloat = 3
    private var cellWidth: CGFloat! {
        didSet {
            cellsInRow = collectionView.bounds.size.width/cellWidth.rounded(.down)
        }
    }
    
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if UIDevice.current.userInterfaceIdiom == .pad {
            navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
            splitViewController?.preferredDisplayMode = .primaryOverlay
        }
        
        if galleriesTVC == nil {
            navigationItem.rightBarButtonItems = nil
            let label = UILabel(frame: collectionView.superview!.frame)
            label.text = "Choose gallery"
            label.textColor = .gray
            label.font.withSize(17)
            label.textAlignment = .center
            collectionView.superview!.addSubview(label)
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
            
            flowLayout.sectionInset = UIEdgeInsets(top: spaceAroundItems, left: spaceAroundItems, bottom: spaceAroundItems, right: spaceAroundItems)
            flowLayout.minimumLineSpacing = spaceAroundItems
            flowLayout.minimumInteritemSpacing = spaceAroundItems
            
            cellWidth = (collectionView.bounds.size.width - 0.1 - spaceAroundItems*(cellsInRow+1)) / cellsInRow
            
            let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(resizeCells))
            collectionView.addGestureRecognizer(pinchGesture)
        }
    }
    
    // MARK: - Actions
    @objc func resizeCells(_ sender: UIPinchGestureRecognizer) {
        switch sender.state {
            case .changed, .ended:
                if (cellWidth * sender.scale) <= (collectionView.bounds.size.width - spaceAroundItems*2) {
                    cellWidth *= sender.scale
                    flowLayout.invalidateLayout()
                    collectionView.visibleCells.forEach{ $0.setNeedsDisplay() }
                }
                sender.scale = 1.0
            default: break
        }
    }
    
    // MARK: - DataSource
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        gallery.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellHeight = gallery[indexPath.item].aspectRatio * cellWidth
        return CGSize(width: cellWidth, height: cellHeight)
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCollectionViewCell
        cell.backgroundImage = gallery[indexPath.item]
        return cell
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "DetailVCSegue", let detailVC = segue.destination as? DetailViewController {
            detailVC.title = "Picture"
            let indexPath = collectionView.indexPathsForSelectedItems![0]
            let cell = collectionView.cellForItem(at: indexPath) as! ImageCollectionViewCell
            detailVC.image = cell.backgroundImage
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
        let item = (collectionView.cellForItem(at: indexPath) as! ImageCollectionViewCell).backgroundImage! as UIImage
        let itemForDrag = UIDragItem(itemProvider: NSItemProvider(object: item))
        itemForDrag.localObject = item
        dragItems.append(itemForDrag)
        return dragItems
    }
    
    // MARK: Drop items to gallery
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        session.canLoadObjects(ofClass: UIImage.self)
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        let isSelf = (session.localDragSession?.localContext as? UICollectionView) == collectionView
        return UICollectionViewDropProposal(operation: isSelf ? .move : .copy, intent: .insertAtDestinationIndexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item: gallery.count, section: 0)
        for item in coordinator.items {
            if let sourceIndexPath = item.sourceIndexPath, (item.dragItem.localObject as? UIImage) != nil {
                    collectionView.performBatchUpdates { 
                        let item = gallery.remove(at: sourceIndexPath.item)
                        gallery.insert(item, at: destinationIndexPath.item)
                        collectionView.deleteItems(at: [sourceIndexPath])
                        collectionView.insertItems(at: [destinationIndexPath])
                    }
                    coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
                
            } else {
                item.dragItem.itemProvider.loadObject(ofClass: UIImage.self) { (provider, error) in
                    if let image = provider as? UIImage {
                        DispatchQueue.main.async {
                            self.gallery.insert(image, at: destinationIndexPath.item)
                            self.collectionView.insertItems(at: [destinationIndexPath])
                        }
                    }
                }
            }
        }
    }
    
    // MARK: Delete items via deleteBarItem
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        session.canLoadObjects(ofClass: NSURL.self) || session.canLoadObjects(ofClass: UIImage.self)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        UIDropProposal(operation: .move)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        guard session.localDragSession != nil else { return }
        session.items.forEach {
            if let object = $0.localObject as? UIImage,
               let index = gallery.firstIndex(where: { $0 == object }) {
                gallery.remove(at: index)
                collectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
            }
        }
    }
}
