//
//  Image+CoreDataClass.swift
//
//  Created by Nicholas Sutanto on 10/7/17.
//  Copyright © 2017 Nicholas Sutanto. All rights reserved.
//
//

import Foundation
import CoreData


public class Image: NSManagedObject {

    convenience init(urlString: String, imageData: NSData, context: NSManagedObjectContext) {
        
        // An EntityDescription is an object that has access to all
        // the information you provided in the Entity part of the model
        // you need it to create an instance of this class.
        if let ent = NSEntityDescription.entity(forEntityName: "Image", in: context) {
            self.init(entity: ent, insertInto: context)
            self.imageURL = urlString
            self.imageBinary = imageData
        } else {
            fatalError("Unable to find Entity name!")
        }
    }
}
