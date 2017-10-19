//
//  Location+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Nicholas Sutanto on 10/19/17.
//  Copyright © 2017 Nicholas Sutanto. All rights reserved.
//
//

import Foundation
import CoreData


extension Location {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Location> {
        return NSFetchRequest<Location>(entityName: "Location")
    }

    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var totalFlickrPages: Int32
    @NSManaged public var locationToImage: NSSet?

}

// MARK: Generated accessors for locationToImage
extension Location {

    @objc(addLocationToImageObject:)
    @NSManaged public func addToLocationToImage(_ value: Image)

    @objc(removeLocationToImageObject:)
    @NSManaged public func removeFromLocationToImage(_ value: Image)

    @objc(addLocationToImage:)
    @NSManaged public func addToLocationToImage(_ values: NSSet)

    @objc(removeLocationToImage:)
    @NSManaged public func removeFromLocationToImage(_ values: NSSet)

}
