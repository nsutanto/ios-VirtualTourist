//
//  Image+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Nicholas Sutanto on 10/7/17.
//  Copyright © 2017 Nicholas Sutanto. All rights reserved.
//
//

import Foundation
import CoreData


extension Image {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Image> {
        return NSFetchRequest<Image>(entityName: "Image")
    }

    @NSManaged public var imageBinary: NSData?
    @NSManaged public var imageURL: String?
    @NSManaged public var imageToLocation: Location?

}
