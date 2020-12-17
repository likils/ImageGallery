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
    
    var galleries = [String]()
    var galleriesImages = [String: [(url: URL, aspectRatio: CGFloat)]]()
    
    var deletedGalleries = [String]()
    var deletedGalleriesImages = [String: [(url: URL, aspectRatio: CGFloat)]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = editButtonItem
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNewGallery))
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
        section == 0 ? "Galleries" : "Recently deleted"
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        44 // for better "undelete" animation
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // TODO: create custom cell with textField to rename cell via double tap
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
                tableView.deleteRows(at: [indexPath], with: .left)
                
                deletedGalleries.append(deletedGallery)
                tableView.insertRows(at: [IndexPath(row: deletedGalleries.count - 1, section: 1)], with: .left)
                
                deletedGalleriesImages[deletedGallery] = galleriesImages.removeValue(forKey: deletedGallery)
            }
            if indexPath.section == 1 {
                let deletedGallery = deletedGalleries.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .left)
                deletedGalleriesImages.removeValue(forKey: deletedGallery)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.section == 1 else { return nil }
        
        let action = UIContextualAction(style: .normal, title: "Undelete") { (_, _, _) in
            tableView.isEditing = false
            
            let undeletedGallery = self.deletedGalleries.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .none)
            
            self.galleries.append(undeletedGallery)
            tableView.insertRows(at: [IndexPath(row: self.galleries.count - 1, section: 0)], with: .right)

            self.galleriesImages[undeletedGallery] = self.deletedGalleriesImages.removeValue(forKey: undeletedGallery)
            
        }
        action.backgroundColor = #colorLiteral(red: 0.1568627451, green: 0.8039215686, blue: 0.2549019608, alpha: 1)
        let actionsConfig = UISwipeActionsConfiguration(actions: [action])
        actionsConfig.performsFirstActionWithFullSwipe = true
        return actionsConfig
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            // TODO: add handlers to "Restore" and "Delete" actions
            let ac = UIAlertController(title: "Manage Gallery", message: "\"\(deletedGalleries[indexPath.row])\"", preferredStyle: .actionSheet)
            let restore = UIAlertAction(title: "Restore", style: .default, handler: nil)
            let delete = UIAlertAction(title: "Delete", style: .destructive, handler: nil)
            ac.addAction(restore)
            ac.addAction(delete)
            ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(ac, animated: true)
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GallerySegue" {
            if let imageGalleryVC = segue.destination.contents as? ImageGalleryCollectionViewController,
               !galleries.isEmpty {
                let indexPath = tableView.indexPathForSelectedRow ?? IndexPath(row: 0, section: 0)
                imageGalleryVC.title = galleries[indexPath.row]
                imageGalleryVC.galleriesTVC = self
                tableView.deselectRow(at: indexPath, animated: true)
            }
        }
    }

    // MARK: - Helper methods
    @objc func addNewGallery() {
        galleries.append("Untitled")
        tableView.insertRows(at: [IndexPath(row: galleries.count-1, section: 0)], with: .top)
    }
}
