//
//  GalleriesTableViewController.swift
//  ImageGallery
//
//  Created by Nik on 13.11.2020.
//  Copyright © 2020 Nik. All rights reserved.
//

import UIKit

class GalleriesTableViewController: UITableViewController, UISplitViewControllerDelegate {
    // MARK: Model
    var galleries = [String]()
    var galleriesImages = [String: [UIImage]]()
    
    private var deletedGalleries = [String]()
    
// autoselection for iPad
    private var selectedGallery: IndexPath?
    // TODO: - Add persistance
    
    // MARK: - Initialization
    private var initialization = true
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if UIDevice.current.userInterfaceIdiom == .phone {
            splitViewController?.delegate = self
        }
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = editButtonItem
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNewGallery))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
// autoselection for iPad
        if initialization && UIDevice.current.userInterfaceIdiom == .pad {
            selectGallery()
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
        section == 0 ? nil : deletedGalleries.isEmpty ? nil : "Recently deleted:"
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        section == 0 ? 1 : deletedGalleries.isEmpty ? 0 : 44
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        44
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: indexPath.section == 0 ? "GalleryCell" : "RecentlyDeleted", for: indexPath)
        if indexPath.section == 0, let cell = cell as? GalleriesTableViewCell {
            cell.nameTextField.text = galleries[indexPath.row]
            cell.textFieldEndEditing = { [weak self] in
                self?.checkGalleryNames()
            }
            cell.accessoryType = .disclosureIndicator
        } else {
            cell.textLabel?.text = deletedGalleries[indexPath.row]
        }
        return cell
    }

    // MARK: - Table view "editing by user" setup
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if tableView.isEditing { checkGalleryNames() }
        
        for row in 0..<tableView.numberOfRows(inSection: 0) {
            cellNameEditingEnabled(tableView.isEditing, atRow: row)
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        for i in 0..<galleries.count {
            cellNameEditingEnabled(editing, atRow: i)
        }
        
// autoselection for iPad
        if tableView.indexPathForSelectedRow == nil && UIDevice.current.userInterfaceIdiom == .pad {
            tableView.selectRow(at: selectedGallery, animated: true, scrollPosition: .none)
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if indexPath.section == 0 {
                moveRowBetweenSections(at: indexPath, with: .left)
            }
            if indexPath.section == 1 {
                deleteGallery(atIndexPath: indexPath)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.section == 1 else { return nil }
        let action = UIContextualAction(style: .normal, title: "Restore") { (_, _, _) in
            self.moveRowBetweenSections(at: indexPath, with: .right)
            
            // disable editing textField after swipe
            self.cellNameEditingEnabled(false, atRow: self.galleries.count-1) // for iphone
            self.tableView.isEditing = false // for ipad
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
            if sourceIndexPath.section == 1 && deletedGalleries.isEmpty {
                tableView.reloadSections(IndexSet(integer: 1), with: .fade)
            }
            
// autoselection setup for iPad
            if sourceIndexPath == selectedGallery {
                selectedGallery = destinationIndexPath
                tableView.selectRow(at: destinationIndexPath, animated: true, scrollPosition: .none)
            } else if let selectedGallery = selectedGallery {
                let newIndexPathRow: Int
                if sourceIndexPath.section == 0 {
                    if (sourceIndexPath.row < selectedGallery.row && selectedGallery.row < destinationIndexPath.row) ||
                        (destinationIndexPath.row < selectedGallery.row && selectedGallery.row < sourceIndexPath.row) ||
                        selectedGallery.row == destinationIndexPath.row {
                        newIndexPathRow = sourceIndexPath.row < destinationIndexPath.row ? selectedGallery.row - 1 : selectedGallery.row + 1
                    } else {
                        newIndexPathRow = selectedGallery.row
                    }
                } else {
                    newIndexPathRow = selectedGallery.row < destinationIndexPath.row ? selectedGallery.row : selectedGallery.row + 1
                }
                let newIndexPath = IndexPath(row: newIndexPathRow, section: 0)
                self.selectedGallery = newIndexPath
                tableView.selectRow(at: newIndexPath, animated: true, scrollPosition: .none)
            } // end
            
        } else {
            deletedGalleries.insert(movedGallery, at: destinationIndexPath.row)
            
// autoselection for iPad
            if sourceIndexPath == selectedGallery {
                selectedGallery = nil
                selectGallery()
            } else if let selectedGallery = selectedGallery, sourceIndexPath.section == 0, sourceIndexPath.row < selectedGallery.row {
                let newIndexPath = IndexPath(row: selectedGallery.row - 1, section: 0)
                self.selectedGallery = newIndexPath
                tableView.selectRow(at: newIndexPath, animated: true, scrollPosition: .none)
            } // end
        }
        
        if sourceIndexPath.section != destinationIndexPath.section {
            tableView.reloadData()
            
// autoselection for iPad
            if galleries.count == 1 && destinationIndexPath.section == 0 {
                selectedGallery = destinationIndexPath
                selectGallery()
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
// autoselection for iPad
        if selectedGallery != indexPath && indexPath.section == 0 { selectedGallery = indexPath }
        return indexPath
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            let ac = UIAlertController(title: "Manage Gallery", message: "\"\(deletedGalleries[indexPath.row])\"", preferredStyle: .actionSheet)
            let restore = UIAlertAction(title: "Restore", style: .default) {_ in
                self.moveRowBetweenSections(at: indexPath, with: .fade)
                
                // disable editing textField after restore
                self.cellNameEditingEnabled(false, atRow: self.galleries.count-1)
            }
            let delete = UIAlertAction(title: "Delete", style: .destructive) {_ in 
                self.deleteGallery(atIndexPath: indexPath)
            }
            ac.addAction(restore)
            ac.addAction(delete)
            ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {_ in
                if UIDevice.current.userInterfaceIdiom == .pad {
                    tableView.selectRow(at: self.selectedGallery, animated: true, scrollPosition: .none)
                }
            }))
            present(ac, animated: true)
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GallerySegue" {
            if let imageGalleryVC = segue.destination.contents as? ImageGalleryCollectionViewController {
// autoselection for iPad
                if galleries.isEmpty || selectedGallery == nil {
                    imageGalleryVC.title = nil
                    imageGalleryVC.galleriesTVC = nil
                    
                } else {
                    let indexPath = tableView.indexPathForSelectedRow ?? IndexPath(row: 0, section: 0)
                    imageGalleryVC.title = galleries[indexPath.row]
                    imageGalleryVC.galleriesTVC = self
                    if UIDevice.current.userInterfaceIdiom == .phone {
                        tableView.deselectRow(at: indexPath, animated: true)
                    }
                }
            }
        }
    }
    
// autoselection for iPad
    private func selectGallery() {
        if UIDevice.current.userInterfaceIdiom == .pad {
            performSegue(withIdentifier: "GallerySegue", sender: nil)
        }
    }
    
    // MARK: - Helper methods
    @objc func addNewGallery() {
        let newName = "Untitled".madeUnique(withRespectTo: galleries+deletedGalleries)
        galleries.append(newName)
        let indexPath = IndexPath(row: galleries.count-1, section: 0)
        tableView.insertRows(at: [indexPath], with: .top)
        cellNameEditingEnabled(tableView.isEditing, atRow: galleries.count-1)
        
// autoselection for iPad
        if UIDevice.current.userInterfaceIdiom == .pad && galleries.count == 1 {
            selectedGallery = indexPath
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            selectGallery()
        }
    }
    
    private func moveRowBetweenSections(at indexPath: IndexPath, with animation: UITableView.RowAnimation) {
        let movedRow = indexPath.section == 0 ? galleries.remove(at: indexPath.row) : deletedGalleries.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: animation)
        if indexPath.section == 0 {
            deletedGalleries.append(movedRow)
            if deletedGalleries.count == 1 {
                tableView.reloadSections(IndexSet(integer: 1), with: animation)
            } else {
                let destination = IndexPath(row: tableView.numberOfRows(inSection: 1), section: 1)
                tableView.insertRows(at: [destination], with: animation)
            }
            
// autoselection for iPad
            guard UIDevice.current.userInterfaceIdiom == .pad else { return }
            if indexPath == selectedGallery {
                selectedGallery = nil
                selectGallery()
            } else if let selectedGallery = selectedGallery, indexPath.row < selectedGallery.row {
                let newIndexPath = IndexPath(row: selectedGallery.row-1, section: 0)
                self.selectedGallery = newIndexPath
                tableView.selectRow(at: newIndexPath, animated: true, scrollPosition: .none)
            } // end
            
        } else {
            if deletedGalleries.isEmpty {
                tableView.reloadSections(IndexSet(integer: 1), with: animation)
            }
            galleries.append(movedRow)
            let destination = IndexPath(row: tableView.numberOfRows(inSection: 0), section: 0)
            tableView.insertRows(at: [destination], with: animation)
            
// autoselection for iPad
            if UIDevice.current.userInterfaceIdiom == .pad {
                if galleries.count == 1 {
                    selectedGallery = destination
                    tableView.selectRow(at: destination, animated: true, scrollPosition: .none)
                    selectGallery()
                } else {
                    tableView.selectRow(at: selectedGallery, animated: true, scrollPosition: .none)
                }
            }
        }
    }
    
    private func deleteGallery(atIndexPath indexPath: IndexPath) {
        let deletedGallery = deletedGalleries.remove(at: indexPath.row)
        if deletedGalleries.isEmpty {
            tableView.reloadSections(IndexSet(integer: 1), with: .fade)
        } else {
            tableView.deleteRows(at: [indexPath], with: .fade)
            galleriesImages.removeValue(forKey: deletedGallery) 
        }
        if UIDevice.current.userInterfaceIdiom == .pad {
            tableView.selectRow(at: selectedGallery, animated: true, scrollPosition: .none)
        }
    }
    
    private func cellNameEditingEnabled(_ userInteraction: Bool, atRow row: Int) {
        guard let cell = tableView.cellForRow(at: IndexPath(row: row, section: 0)) as? GalleriesTableViewCell else { return }
        cell.nameTextField.resignFirstResponder()
        cell.nameTextField.isUserInteractionEnabled = userInteraction
        cell.nameTextField.borderStyle = userInteraction ? .roundedRect : .none
    }
    
    private func checkGalleryNames() {
        for row in 0..<galleries.count {
            guard let cell = tableView.cellForRow(at: IndexPath(row: row, section: 0)) as? GalleriesTableViewCell else { return }
            let cellText = cell.nameTextField.text!
            if !galleries.contains(cellText) && !deletedGalleries.contains(cellText) {
                let oldName = galleries.remove(at: row)
                galleries.insert(cellText, at: row)
                galleriesImages[cellText] = galleriesImages.removeValue(forKey: oldName)
            } else if cellText != galleries[row] {
                cell.nameTextField.text = self.galleries[row]
                cell.nameTextField.textColor = .red
                let ac = UIAlertController(title: "This name \"\(cellText)\" was already used.", message: "Please, enter another name.", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                    self.setEditing(true, animated: true)
                    cell.nameTextField.becomeFirstResponder()
                    cell.nameTextField.textColor = .black
                })
                present(ac, animated: true)
            }
        }
    }
}
