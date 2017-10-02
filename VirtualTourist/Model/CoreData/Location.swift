//
//  Location+CoreDataClass.swift
//  VirtualTourist
//
//  Created by Nicholas Sutanto on 9/30/17.
//  Copyright © 2017 Nicholas Sutanto. All rights reserved.
//
//

import Foundation
import CoreData


public class Location: NSManagedObject {
    
    
    // MARK: Initializer
    
    convenience init(longitude: Double, latitude: Double, context: NSManagedObjectContext) {
        
        // An EntityDescription is an object that has access to all
        // the information you provided in the Entity part of the model
        // you need it to create an instance of this class.
        if let ent = NSEntityDescription.entity(forEntityName: "Location", in: context) {
            self.init(entity: ent, insertInto: context)
            self.longitude = longitude
            self.latitude = latitude
        } else {
            fatalError("Unable to find Entity name!")
        }
    }
}
