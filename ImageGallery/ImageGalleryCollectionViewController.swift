//
//  ImageGalleryCollectionViewController.swift
//  ImageGallery
//
//  Created by Nik on 13.11.2020.
//  Copyright © 2020 Nik. All rights reserved.
//

import UIKit

class ImageGalleryCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    weak var galleriesTVC: GalleriesTableViewController?
    private lazy var _collection = collection {
        didSet { collection = _collection }
    }
    private var collection: [(url: URL, aspectRatio: CGFloat)] {
        get {
            if galleriesTVC?.galleriesImages[title!] != nil {
                return galleriesTVC!.galleriesImages[title!]!
            } else {
                return [(url: URL, aspectRatio: CGFloat)]()
            }
        }
        set { galleriesTVC?.galleriesImages[title!] = newValue }
    }

    let spaceAroundItems: CGFloat = 8
    var cellsInRow: CGFloat = 3
    var cellWidth: CGFloat! {
        didSet {
            cellsInRow = collectionView.bounds.size.width/cellWidth.rounded(.down)
        }
    }
    
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if UIDevice.current.userInterfaceIdiom == .pad {
            navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
        }
        splitViewController?.preferredDisplayMode = .primaryOverlay
        
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
        
        flowLayout.sectionInset = UIEdgeInsets(top: spaceAroundItems, left: spaceAroundItems, bottom: spaceAroundItems, right: spaceAroundItems)
        flowLayout.minimumLineSpacing = spaceAroundItems
        flowLayout.minimumInteritemSpacing = spaceAroundItems
        
        cellWidth = (collectionView.bounds.size.width - 0.1 - spaceAroundItems*(cellsInRow+1)) / cellsInRow
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(resizeCells))
        collectionView.addGestureRecognizer(pinchGesture)
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
    
    // MARK: - Delegate & DataSource
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        collection.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellHeight = collection[indexPath.item].aspectRatio * cellWidth
        return CGSize(width: cellWidth, height: cellHeight)
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCollectionViewCell
        cell.imageUrl = collection[indexPath.item].url
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
    }
}

// MARK: - Drag&Drop
extension ImageGalleryCollectionViewController: UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    
    // MARK: Drag items
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        session.localContext = collectionView
        return dragItems(at: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        print("items")
        return dragItems(at: indexPath)
    }
    
    private func dragItems(at indexPath: IndexPath) -> [UIDragItem] {
        var dragItems = [UIDragItem]()
        let item = (collectionView.cellForItem(at: indexPath) as! ImageCollectionViewCell).imageUrl! as NSURL
        let itemForDrag = UIDragItem(itemProvider: NSItemProvider(object: item))
        itemForDrag.localObject = item
        dragItems.append(itemForDrag)
        return dragItems
    }
    
    // MARK: Drop items
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        session.canLoadObjects(ofClass: NSURL.self) || session.canLoadObjects(ofClass: UIImage.self)
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        let isSelf = (session.localDragSession?.localContext as? UICollectionView) == collectionView
        return UICollectionViewDropProposal(operation: isSelf ? .move : .copy, intent: .insertAtDestinationIndexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item: 0, section: 0)
        var pictureUrl = [URL]()
        var aspectRatio = [CGFloat]()
        for item in coordinator.items {
            if let sourseIndexPath = item.sourceIndexPath {
                if (item.dragItem.localObject as? NSURL) != nil {
                    collectionView.performBatchUpdates { 
                        let item = _collection.remove(at: sourseIndexPath.item)
                        _collection.insert(item, at: destinationIndexPath.item)
                        collectionView.deleteItems(at: [sourseIndexPath])
                        collectionView.insertItems(at: [destinationIndexPath])
                    }
                    coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
                }
            } else {
                item.dragItem.itemProvider.loadObject(ofClass: UIImage.self) { (provider, error) in
                    if let image = provider as? UIImage {
                        aspectRatio.append(image.size.height / image.size.width)
                    }
                }
                item.dragItem.itemProvider.loadObject(ofClass: NSURL.self) { (provider, error) in
                    if let url = provider as? URL {
                        pictureUrl.append(url.imageURL)
                    } 
                    if !pictureUrl.isEmpty && !aspectRatio.isEmpty {
                        let item = (url: pictureUrl[0], aspectRatio: aspectRatio[0])
                        self._collection.insert(item, at: destinationIndexPath.item)
                        
                        DispatchQueue.main.async {
                            self.collectionView.insertItems(at: [destinationIndexPath])
                        }
                    } else if !pictureUrl.isEmpty && aspectRatio.isEmpty {
                        guard let data = try? Data(contentsOf: pictureUrl[0].imageURL),
                              let image = UIImage(data: data) else { print("Fail to load from URL"); return }
                        let aspectRatio = image.size.height / image.size.width
                        let item = (url: pictureUrl[0], aspectRatio: aspectRatio)
                        self._collection.insert(item, at: destinationIndexPath.item)
                        
                        DispatchQueue.main.async {
                            self.collectionView.insertItems(at: [destinationIndexPath])
                        }
                    }
                }
            }
        }
    }
}
