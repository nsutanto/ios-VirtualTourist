//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Nicholas Sutanto on 9/29/17.
//  Copyright © 2017 Nicholas Sutanto. All rights reserved.
//

import UIKit
import MapKit
import CoreData

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = .red
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    // Save the region everytime we change the map
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let defaults = UserDefaults.standard
        defaults.set(self.mapView.region.center.latitude, forKey: STRING_LATITUDE)
        defaults.set(self.mapView.region.center.longitude, forKey: STRING_LONGITUDE)
        defaults.set(self.mapView.region.span.latitudeDelta, forKey: STRING_LATITUDE_DELTA)
        defaults.set(self.mapView.region.span.longitudeDelta, forKey: STRING_LONGITUDE_DELTA)
    }
    
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView){
        let coordinate = view.annotation?.coordinate
        if (onEdit) {
            // Delete
            for location in locations {
                if location.latitude == (coordinate!.latitude) && location.longitude == (coordinate!.longitude) {
                    
                    let annotationToRemove = view.annotation
                    self.mapView.removeAnnotation(annotationToRemove!)
                    coreDataStack?.context.delete(location)
                    coreDataStack?.save()
                    
                    break
                }
            }
        } else {
            let vc = self.storyboard!.instantiateViewController(withIdentifier: "PictureViewControllerID") as! PictureViewController
            
            // Grab the location object from Core Data
            let location = self.getLocation(longitude: coordinate!.longitude, latitude: coordinate!.latitude)
            
            vc.selectedLocation = location
            vc.totalPageNumber = location?.value(forKey: "totalFlickrPages") as! Int
            
            self.navigationController?.pushViewController(vc, animated: false)
        }
    }
}

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var labelDelete: UILabel!
    @IBOutlet weak var buttonEdit: UIBarButtonItem!
    
    var coreDataStack: CoreDataStack?
    var onEdit = false
    var locations = [Location]()
    
    let STRING_LATITUDE = "Latitude"
    let STRING_LONGITUDE = "Longitude"
    let STRING_LATITUDE_DELTA = "LatitudeDelta"
    let STRING_LONGITUDE_DELTA = "LongitudeDelta"
    let STRING_FIRST_LAUNCH = "FirstLaunch"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize core data stack
        let delegate = UIApplication.shared.delegate as! AppDelegate
        coreDataStack = delegate.stack
        
        mapView.delegate = self
        
        initMapSetting()
        loadLocations()
    }
    
    
    private func initMapSetting() {
        
        let defaults = UserDefaults.standard
        if UserDefaults.standard.bool(forKey: STRING_FIRST_LAUNCH) {
            let centerLatitude  = defaults.double(forKey: STRING_LATITUDE)
            let centerLongitude = defaults.double(forKey: STRING_LONGITUDE)
            let latitudeDelta   = defaults.double(forKey: STRING_LATITUDE_DELTA)
            let longitudeDelta  = defaults.double(forKey: STRING_LONGITUDE_DELTA)
            
            let centerCoordinate = CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude)
            let spanCoordinate = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            let region = MKCoordinateRegion(center: centerCoordinate, span: spanCoordinate)
            
            performUIUpdatesOnMain {
                self.mapView.setRegion(region, animated: true)
            }
        } else {
            defaults.set(true, forKey: STRING_FIRST_LAUNCH)
        }
    }
    
    // Get Locations from CoreData
    private func loadLocations() {
        let request: NSFetchRequest<Location> = Location.fetchRequest()
        if let result = try? coreDataStack?.context.fetch(request) {
            var annotationsArray = [MKPointAnnotation]()
            for location in result! {
                let annotation = MKPointAnnotation()
                annotation.coordinate.latitude = location.latitude
                annotation.coordinate.longitude = location.longitude
                annotationsArray.append(annotation)
                locations.append(location)
            }
            
            performUIUpdatesOnMain {
                self.mapView.addAnnotations(annotationsArray)
            }
        }
    }
    
    // Get 1 location from CoreData
    private func getLocation(longitude: Double, latitude: Double) -> Location? {
        var location: Location?
        let request: NSFetchRequest<Location> = Location.fetchRequest()
        
        if let result = try? coreDataStack?.context.fetch(request) {
            for locationInResult in result! {
                if (locationInResult.latitude == latitude && locationInResult.longitude == longitude) {
                    location = locationInResult
                    break
                }
            }
        }
        return location
    }
    
    private func getPhotoFromFlickr(_ pageNumber: Int, _ location: Location) {
        
        FlickrClient.sharedInstance().searchPhotos(location.longitude,
                                               location.latitude,
                                               pageNumber,
                                               completionHandlerSearchPhotos: { (result, pageNumberResult, error ) in
    
            if (error == nil) {
                for urlString in result! {
                    // https://oleb.net/blog/2014/06/core-data-concurrency-debugging/
                    self.coreDataStack?.context.perform {
                        let image = Image(urlString: urlString, imageData: nil, context: (self.coreDataStack?.context)!)
                        location.totalFlickrPages = Int32(pageNumberResult!)
                        location.addToLocationToImage(image)
                    }
                    
                }
            }
            else {
                print("***** Fail to get photo from flickr")
            }
        })
    }
    
    // MARK : Action
    @IBAction func onEditAction(_ sender: Any) {
        // TODO : shift map up
        if (buttonEdit.title == "Edit") {
            labelDelete.isHidden = false
            buttonEdit.title = "Done"
            onEdit = true
        }
        else {
            labelDelete.isHidden = true
            buttonEdit.title = "Edit"
            onEdit = false
        }
    }
    
    @IBAction func onLongPressAction(_ sender: Any) {
        
        let lpg = sender as? UILongPressGestureRecognizer
        
        let pressPoint = lpg?.location(in: mapView)
        let pressCoordinate = mapView.convert(pressPoint!, toCoordinateFrom: mapView)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = pressCoordinate
        
        let annotations = mapView.annotations
        
        var isFound = false
        for annotationEntry in annotations {
            if (annotationEntry.coordinate.latitude == pressCoordinate.latitude && annotationEntry.coordinate.longitude == pressCoordinate.longitude) {
                isFound = true
                break
            }
        }
        
        if !isFound {
            
            // Add map annotation
            self.mapView.addAnnotation(annotation)
            
            // Persist the location to the core data
            let location = Location(longitude: annotation.coordinate.longitude, latitude: annotation.coordinate.latitude, context: (coreDataStack?.context)!)
            locations.append(location)
            
            // Fetch flickr. Let's start with page 1
            getPhotoFromFlickr(1, location)
        }
        
    }
}

