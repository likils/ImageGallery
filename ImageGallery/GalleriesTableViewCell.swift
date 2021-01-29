//
//  GalleriesTableViewCell.swift
//  ImageGallery
//
//  Created by likils on 04.01.2021.
//  Copyright © 2021 likils. All rights reserved.
//

import UIKit

class GalleriesTableViewCell: UITableViewCell, UITextFieldDelegate {
    
    @IBOutlet weak var nameTextField: UITextField! {
        didSet {
            nameTextField.delegate = self
        }
    }
    
    var textFieldEndEditing: (() -> Void)?
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        textFieldEndEditing?()
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        nameTextField.resignFirstResponder()
        return true
    }
}
