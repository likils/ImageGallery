//
//  ImageGalleryCollectionViewController.swift
//  ImageGallery
//
//  Created by Nik on 13.11.2020.
//  Copyright © 2020 Nik. All rights reserved.
//

import UIKit

class ImageGalleryCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    var imageUrlCollection = [(url: URL, aspectRatio: CGFloat)]()

    let spaceAroundItems: CGFloat = 8
    let cellsInRow: CGFloat = 3
    
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
        splitViewController?.preferredDisplayMode = .primaryOverlay
        
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
        
        flowLayout.sectionInset = UIEdgeInsets(top: spaceAroundItems, left: spaceAroundItems, bottom: spaceAroundItems, right: spaceAroundItems)
        flowLayout.minimumLineSpacing = spaceAroundItems
        flowLayout.minimumInteritemSpacing = spaceAroundItems
    }
    
    // MARK: - UICollectionViewDataSource
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        imageUrlCollection.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellWidth = (collectionView.bounds.size.width - 0.1 - spaceAroundItems*(cellsInRow+1)) / cellsInRow
        let cellHeight = imageUrlCollection[indexPath.item].aspectRatio * cellWidth
        return CGSize(width: cellWidth, height: cellHeight)
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCollectionViewCell
        cell.imageUrl = imageUrlCollection[indexPath.item].url
        return cell
    }
    
    
}

// MARK: - Drag&Drop Setup
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
                        let item = imageUrlCollection.remove(at: sourseIndexPath.item)
                        imageUrlCollection.insert(item, at: destinationIndexPath.item)
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
                        self.imageUrlCollection.insert(item, at: destinationIndexPath.item)
                        
                        DispatchQueue.main.async {
                            self.collectionView.insertItems(at: [destinationIndexPath])
                        }
                    } else if !pictureUrl.isEmpty && aspectRatio.isEmpty {
                        guard let data = try? Data(contentsOf: pictureUrl[0].imageURL),
                              let image = UIImage(data: data) else { print("Fail to load from URL"); return }
                        let aspectRatio = image.size.height / image.size.width
                        let item = (url: pictureUrl[0], aspectRatio: aspectRatio)
                        self.imageUrlCollection.insert(item, at: destinationIndexPath.item)
                        
                        DispatchQueue.main.async {
                            self.collectionView.insertItems(at: [destinationIndexPath])
                        }
                    }
                }
            }
        }
    }
}
