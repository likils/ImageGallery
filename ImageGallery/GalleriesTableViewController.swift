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
    
    // TODO: - Add persistance
    
    // MARK: - Launch
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
    
    // MARK: - TableView DataSource
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

    // MARK: - TableView "editing by user" setup
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if tableView.isEditing { checkGalleryNames() }
        
        for row in 0..<tableView.numberOfRows(inSection: 0) {
            cellNameEditingEnabled(tableView.isEditing, at: row)
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        for i in 0..<galleries.count {
            cellNameEditingEnabled(editing, at: i)
        }
        
        // autoselection for iPad
        if tableView.indexPathForSelectedRow == nil {
            showSelection()
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if indexPath.section == 0 {
                moveRowBetweenSections(at: indexPath, with: .left)
            }
            if indexPath.section == 1 {
                deleteGallery(at: indexPath, with: .left)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.section == 1 else { return nil }
        let action = UIContextualAction(style: .normal, title: "Restore") { (_, _, _) in
            self.moveRowBetweenSections(at: indexPath, with: .right)
            
            // disable editing textField after swipe
            self.cellNameEditingEnabled(false, at: self.galleries.count-1) // for iphone
            self.tableView.isEditing = false // for ipad
        }
        action.backgroundColor = #colorLiteral(red: 0.1568627451, green: 0.8039215686, blue: 0.2549019608, alpha: 1)
        let actionsConfig = UISwipeActionsConfiguration(actions: [action])
        actionsConfig.performsFirstActionWithFullSwipe = true
        return actionsConfig
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        indexPath.section == 0 ? true : false
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let movedGallery = galleries.remove(at: sourceIndexPath.row)
        if destinationIndexPath.section == 0 {
            galleries.insert(movedGallery, at: destinationIndexPath.row)
            
            // autoselection setup for iPad
            if sourceIndexPath == selectedGallery {
                selectedGallery = destinationIndexPath
            } else if let selectedGallery = selectedGallery {
                if (sourceIndexPath.row < selectedGallery.row && selectedGallery.row <= destinationIndexPath.row) ||
                    (destinationIndexPath.row <= selectedGallery.row && selectedGallery.row < sourceIndexPath.row) {
                    
                    let newIndexPathRow = sourceIndexPath.row < destinationIndexPath.row ? selectedGallery.row - 1 : selectedGallery.row + 1
                    self.selectedGallery = IndexPath(row: newIndexPathRow, section: 0)
                }
            } // end
            
        } else {
            deletedGalleries.insert(movedGallery, at: destinationIndexPath.row)
            tableView.reloadData()
            
            // autoselection for iPad
            previousOrCurrentGalleryRemoved(at: sourceIndexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            let ac = UIAlertController(title: "Manage Gallery", message: "\"\(deletedGalleries[indexPath.row])\"", preferredStyle: .actionSheet)
            let restore = UIAlertAction(title: "Restore", style: .default) {_ in
                self.moveRowBetweenSections(at: indexPath, with: .fade)
                
                // disable editing textField after restore
                self.cellNameEditingEnabled(false, at: self.galleries.count-1)
            }
            let delete = UIAlertAction(title: "Delete", style: .destructive) {_ in 
                self.deleteGallery(at: indexPath, with: .fade)
            }
            ac.addAction(restore)
            ac.addAction(delete)
            ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {_ in
                self.showSelection()
            }))
            present(ac, animated: true)
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GallerySegue" {
            if let imageGalleryVC = segue.destination.contents as? ImageGalleryCollectionViewController {
                if galleries.isEmpty { // autoselection for iPad
                    imageGalleryVC.title = nil
                    imageGalleryVC.galleriesTVC = nil
                } else {
                    let indexPath = tableView.indexPathForSelectedRow ?? selectedGallery ?? IndexPath(row: 0, section: 0)
                    imageGalleryVC.title = galleries[indexPath.row]
                    imageGalleryVC.galleriesTVC = self
                    if UIDevice.current.userInterfaceIdiom == .phone {
                        tableView.deselectRow(at: indexPath, animated: true)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper methods
    @objc func addNewGallery() {
        let newName = "Untitled".madeUnique(withRespectTo: galleries+deletedGalleries)
        galleries.append(newName)
        let indexPath = IndexPath(row: galleries.count-1, section: 0)
        tableView.insertRows(at: [indexPath], with: .top)
        cellNameEditingEnabled(tableView.isEditing, at: galleries.count-1)
        
        // autoselection for iPad
        if galleries.count == 1 {
            showSelection()
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
            previousOrCurrentGalleryRemoved(at: indexPath)
            
        } else {
            if deletedGalleries.isEmpty {
                tableView.reloadSections(IndexSet(integer: 1), with: animation)
            }
            galleries.append(movedRow)
            let destination = IndexPath(row: tableView.numberOfRows(inSection: 0), section: 0)
            tableView.insertRows(at: [destination], with: animation)
            
            // autoselection for iPad
            showSelection()
            if galleries.count == 1 { selectGallery() } 
        }
    }
    
    private func deleteGallery(at indexPath: IndexPath, with animation: UITableView.RowAnimation) {
        let deletedGallery = deletedGalleries.remove(at: indexPath.row)
        if deletedGalleries.isEmpty {
            tableView.reloadSections(IndexSet(integer: 1), with: animation)
        } else {
            tableView.deleteRows(at: [indexPath], with: animation)
        }
        galleriesImages.removeValue(forKey: deletedGallery)
        
        showSelection()
    }
    
    private func cellNameEditingEnabled(_ userInteraction: Bool, at row: Int) {
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
    
    // MARK: - Autoselection for iPad
    private var firstLaunch = true
    
    private var selectedGallery: IndexPath?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if firstLaunch {
            showSelection()
            selectGallery()
            firstLaunch = false
        }
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return indexPath }
        if selectedGallery != indexPath && indexPath.section == 0 { selectedGallery = indexPath }
        return indexPath
    }
    
    private func selectGallery() {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return }
        performSegue(withIdentifier: "GallerySegue", sender: nil)
    }
    
    private func showSelection() {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return }
        if galleries.count == 1 {
            selectedGallery = IndexPath(row: 0, section: 0)
        }
        tableView.selectRow(at: selectedGallery, animated: true, scrollPosition: .none)
    }
    
    private func previousOrCurrentGalleryRemoved(at indexPath: IndexPath) {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return }
        if let selectedGallery = selectedGallery, indexPath.row <= selectedGallery.row {
            if selectedGallery.row > 0 {
                self.selectedGallery = IndexPath(row: selectedGallery.row - 1, section: 0)
            }
            if selectedGallery.row == indexPath.row { selectGallery() }
        }
    }
}
