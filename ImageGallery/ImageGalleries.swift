//
//  ImageGalleries.swift
//  ImageGallery
//
//  Created by likils on 27.01.2021.
//  Copyright © 2021 likils. All rights reserved.
//

import UIKit

struct ImageGalleries: Codable, Equatable {
    var galleries = [String]()
    var deletedGalleries = [String]()
    var galleriesImages = [String: [String]]()
    
    var json: Data? {
        try? JSONEncoder().encode(self)
    }
    
    /// autoselection for iPad
    var selectedGallery: Int?
    
    // MARK: - Initialization
    init?(json: Data?) {
        if json != nil, let savedGalleries = try? JSONDecoder().decode(ImageGalleries.self, from: json!) {
            self = savedGalleries
        } else {
            return nil
        }
    }
    
    init() { }
    
    // MARK: - Save, load and delete images via path
    private static func path(for imageName: String, fileExtension: String = "png") -> URL? {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return directory?.appendingPathComponent("\(imageName).\(fileExtension)")
    }
    
    static func store(image: UIImage, name: String) throws {
        guard let imageData = image.pngData() else {
            throw NSError(domain: "com.selfcoded.image", code: 0, userInfo: [NSLocalizedDescriptionKey: "Image could not be created"])
        }
        guard let imagePath = ImageGalleries.path(for: name) else {
            throw NSError(domain: "com.selfcoded.image", code: 0, userInfo: [NSLocalizedDescriptionKey: "Image path could not be retrieved"])
        }
        try imageData.write(to: imagePath, options: .atomic)
    }
    
    static func retrieve(imageNamed name: String) -> UIImage? {
        guard let imagePath = ImageGalleries.path(for: name) else { return nil }
        return UIImage(contentsOfFile: imagePath.path)
    }
    
    static func delete(imageNamed name: String) {
        guard let imagePath = ImageGalleries.path(for: name) else { return }
        do {
            try FileManager.default.removeItem(at: imagePath)
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func checkIfImageExistInOtherGalleries(named name: String) {
        let allNames = galleriesImages.values.reduce([], +)
        if !allNames.contains(name) { ImageGalleries.delete(imageNamed: name) }
    }
}
