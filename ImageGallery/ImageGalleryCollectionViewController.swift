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
    
    private var collection: [(url: URL, aspectRatio: CGFloat)] {
        get {
            if let gallery = galleriesTVC?.galleriesImages[title!] {
                return gallery
            } else {
                return [(url: URL, aspectRatio: CGFloat)]()
            }
        }
        set {
            galleriesTVC?.galleriesImages[title!] = newValue
        }
    }

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
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
        collectionView.dragInteractionEnabled = true // for iphone
        
        let addBarItem = UIBarButtonItem(image: nil, landscapeImagePhone: nil, style: .plain, target: self, action: #selector(addPicture))
        addBarItem.title = "➕"
        let deleteBarItem = UIBarButtonItem(customView: UIView(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 40, height: 30))))
        let label = UILabel(frame: deleteBarItem.customView!.frame)
        label.textAlignment = .center
        label.text = "🗑"
        deleteBarItem.customView?.addSubview(label)
        deleteBarItem.customView?.addInteraction(UIDropInteraction(delegate: self))
        navigationItem.rightBarButtonItems = [addBarItem, deleteBarItem]
        
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
    
    @objc func addPicture() {
        // TODO: Setup ability to add pictures from camera and photos app
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
extension ImageGalleryCollectionViewController: UICollectionViewDragDelegate, UICollectionViewDropDelegate, UIDropInteractionDelegate {
    
    // MARK: Drag items from collection
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        session.localContext = collectionView
        return dragItems(at: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
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
    
    // MARK: Drop items to collection
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
        for (index, item) in coordinator.items.enumerated() {
            if let sourceIndexPath = item.sourceIndexPath {
                if (item.dragItem.localObject as? NSURL) != nil {
                    collectionView.performBatchUpdates { 
                        let item = collection.remove(at: sourceIndexPath.item)
                        collection.insert(item, at: destinationIndexPath.item)
                        collectionView.deleteItems(at: [sourceIndexPath])
                        collectionView.insertItems(at: [destinationIndexPath])
                    }
                    coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
                }
            } else {
                item.dragItem.itemProvider.loadObject(ofClass: UIImage.self) { (provider, error) in
                    if let image = provider as? UIImage {
                        aspectRatio.append(image.aspectRatio)
                    }
                }
                item.dragItem.itemProvider.loadObject(ofClass: NSURL.self) { (provider, error) in
                    if let url = provider as? URL {
                        pictureUrl.append(url.imageURL)
                    } 
                    if !pictureUrl.isEmpty && !aspectRatio.isEmpty {
                        let item = (url: pictureUrl[index], aspectRatio: aspectRatio[index])
                        DispatchQueue.main.async {
                            self.collection.insert(item, at: destinationIndexPath.item)
                            self.collectionView.insertItems(at: [destinationIndexPath])
                        }
                    } else if !pictureUrl.isEmpty && aspectRatio.isEmpty {
                        guard let data = try? Data(contentsOf: pictureUrl[index].imageURL),
                              let image = UIImage(data: data)
                        else { print("Fail to load from URL"); return }
                        
                        let item = (url: pictureUrl[index], aspectRatio: image.aspectRatio)
                        DispatchQueue.main.async {
                            self.collection.insert(item, at: destinationIndexPath.item)
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
            if let object = $0.localObject as? URL,
               let index = collection.firstIndex(where: { $0.url == object }) {
                collection.remove(at: index)
                collectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
            }
        }
    }
}
