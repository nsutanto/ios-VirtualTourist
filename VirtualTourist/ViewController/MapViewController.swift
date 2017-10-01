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
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    
    // This delegate method is implemented to respond to taps. It opens the system browser
    // to the URL specified in the annotationViews subtitle property.
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        //if control == view.rightCalloutAccessoryView {
            /* TO DELETE
 if let context = fetchedResultsController?.managedObjectContext, let note = fetchedResultsController?.object(at: indexPath) as? Note, editingStyle == .delete {
 context.delete(note)
 }
 */
        //}
        let coordinate = view.annotation?.coordinate
        for location in locations {
            if location.latitude == (coordinate!.latitude) && location.longitude == (coordinate!.longitude) {
                stack?.context.delete(location)
                //CoreDataStackManager.sharedInstance().saveContext()
                let annotationToRemove = view.annotation
                self.mapView.removeAnnotation(annotationToRemove!)
                break
            }
        }
    }
    
    func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
        if (fullyRendered) {
            performUIUpdatesOnMain {
                //self.loadingIndicator.stopAnimating()
            }
        }
    }
}

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var labelDelete: UILabel!
    @IBOutlet weak var buttonEdit: UIBarButtonItem!
    
    var stack: CoreDataStack?
    var onEdit = false
    var locations = [Location]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        stack = delegate.stack
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // clean cached locations first
        locations.removeAll()
        // reload locations from core data
        loadLocations()
    }
    
    func loadLocations() {
        // Get Locations from CoreData
        let request: NSFetchRequest<Location> = Location.fetchRequest()
        if let result = try? stack?.context.fetch(request) {
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
        
        mapView.addAnnotation(annotation)
        
        // TODO : Do it in background
        let location = Location(longitude: annotation.coordinate.longitude, latitude: annotation.coordinate.latitude, context: (stack?.context)!)
        locations.append(location)
    }
}

