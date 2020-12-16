//
//  GalleriesTableViewController.swift
//  ImageGallery
//
//  Created by Nik on 13.11.2020.
//  Copyright © 2020 Nik. All rights reserved.
//

import UIKit

class GalleriesTableViewController: UITableViewController {
    
    var initialization = true
    
    // TODO: create galleries indices to manage restored gallery in their place
    var galleries = [String]()
    var galleriesImages = [String: [(URL, CGFloat)]]()
    
    var deletedGalleries = [String]()
    var deletedGalleriesImages = [String: [(URL, CGFloat)]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = editButtonItem
        galleriesImages =
            ["Pinterest Gallery":
                [(URL(string: "https://i.pinimg.com/originals/11/ab/14/11ab147894a7d2ce866ff88a4aa63655.jpg")!, 1.2361),
                 (URL(string: "https://i.pinimg.com/originals/8c/3c/05/8c3c053dad41391987706b5b270c7857.png")!, 1.25),
                 (URL(string: "https://img2.goodfon.ru/wallpaper/nbig/3/31/podvodnyy-mir-underwater-voda.jpg")!, 1.7781),
                 (URL(string: "https://wallpapershome.ru/images/pages/pic_v/386.jpg")!, 0.6381),],
             
             "Water Gallery":
                [(URL(string: "https://img2.goodfon.ru/wallpaper/nbig/3/31/podvodnyy-mir-underwater-voda.jpg")!, 1.7781),
                 (URL(string: "https://wallpapershome.ru/images/pages/pic_v/386.jpg")!, 0.6381),
                 (URL(string: "https://i.pinimg.com/originals/11/ab/14/11ab147894a7d2ce866ff88a4aa63655.jpg")!, 1.2361),
                 (URL(string: "https://i.pinimg.com/originals/8c/3c/05/8c3c053dad41391987706b5b270c7857.png")!, 1.25)]]
        
        galleriesImages.keys.forEach{ galleries.append($0) }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if initialization {
            tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: true, scrollPosition: .none)
            prepare(for: UIStoryboardSegue(identifier: "GallerySegue", source: self, destination: splitViewController!.viewControllers[1]), sender: nil)
            initialization = false
        }
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? galleries.count : deletedGalleries.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            return "Recently deleted"
        }
        return "Galleries"
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: indexPath.section == 0 ? "GalleryCell" : "RecentlyDeleted", for: indexPath)
        if indexPath.section == 0 {
            cell.textLabel?.text = galleries[indexPath.row]
            cell.accessoryType = .disclosureIndicator
        } else {
            cell.textLabel?.text = deletedGalleries[indexPath.row]
        }
        
        return cell
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if indexPath.section == 0 {
                let deletedGallery = galleries.remove(at: indexPath.row)
                deletedGalleries.append(deletedGallery)
                tableView.performBatchUpdates { 
                    tableView.deleteRows(at: [indexPath], with: .automatic)
                    tableView.insertRows(at: [IndexPath(row: deletedGalleries.count - 1, section: 1)], with: .automatic)
                }
                deletedGalleriesImages[deletedGallery] = galleriesImages[deletedGallery]
                galleriesImages.removeValue(forKey: deletedGallery)
            }
            if indexPath.section == 1 {
                let deletedGallery = deletedGalleries.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .automatic)
                deletedGalleriesImages.removeValue(forKey: deletedGallery)
            }
        }
    }

    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let movedGallery = sourceIndexPath.section == 0 ? galleries.remove(at: sourceIndexPath.row) : deletedGalleries.remove(at: sourceIndexPath.row)
        if destinationIndexPath.section == 0 {
            galleries.insert(movedGallery, at: destinationIndexPath.row)
        } else {
            deletedGalleries.insert(movedGallery, at: destinationIndexPath.row)
        }
        tableView.reloadData()
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GallerySegue" {
            if let imageGalleryVC = segue.destination.contents as? ImageGalleryCollectionViewController,
               !galleries.isEmpty {
                let indexPath = tableView.indexPathForSelectedRow ?? IndexPath(row: 0, section: 0)
                let galleryName = galleries[indexPath.row]
                imageGalleryVC.title = galleryName
                imageGalleryVC.imageUrlCollection = galleriesImages[galleryName]!
                tableView.deselectRow(at: indexPath, animated: true)
            }
        }
    }

}
