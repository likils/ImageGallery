//
//  ImageGalleries.swift
//  ImageGallery
//
//  Created by Nik on 27.01.2021.
//  Copyright © 2021 Nik. All rights reserved.
//

import UIKit

struct ImageGalleries {
    var galleries = [String]()
    var deletedGalleries = [String]()
    var galleriesImages = [String: [UIImage]]()
    
    /// autoselection for iPad
    var selectedGallery: Int?
    
    // TODO: persistence
}
