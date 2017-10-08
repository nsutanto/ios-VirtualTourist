//
//  PictureViewController.swift
//  VirtualTourist
//
//  Created by Nicholas Sutanto on 9/29/17.
//  Copyright © 2017 Nicholas Sutanto. All rights reserved.
//

import UIKit
import MapKit
import CoreData



extension PictureViewController: UICollectionViewDataSource {
    // tell the collection view how many cells to make
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //return self.items.count
        return 4
    }
    
    // make a cell for each cell index path
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // get a reference to our storyboard cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionViewCell", for: indexPath as IndexPath) as! PictureCollectionViewCell
        
        // Use the outlet in our custom class to get a reference to the UILabel in the cell
        //cell.myLabel.text = self.items[indexPath.item]
        cell.backgroundColor = UIColor.cyan // make cell more visible in our example project
        
        return cell
    }
}

extension PictureViewController: NSFetchedResultsControllerDelegate {
    
}

extension PictureViewController: UICollectionViewDelegate {
    
}

extension PictureViewController: MKMapViewDelegate {

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
}

class PictureViewController: UIViewController {
    
    @IBOutlet weak var buttonPictureAction: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var selectedLocation: Location!
    var coreDataStack: CoreDataStack?
    
    lazy var fetchedResultsController: NSFetchedResultsController = { () -> NSFetchedResultsController<NSFetchRequestResult> in
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Image")
        request.sortDescriptors = [NSSortDescriptor(key: "imageURL", ascending: true)]
        request.predicate = NSPredicate(format: "location == %@", self.selectedLocation)
        
        let moc = coreDataStack?.context
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: request,
                                                                  managedObjectContext: moc!,
                                                                  sectionNameKeyPath: nil,
                                                                  cacheName: nil)
        return fetchedResultsController
        
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize core data stack
        let delegate = UIApplication.shared.delegate as! AppDelegate
        coreDataStack = delegate.stack
        
        // Initialize delegate
        mapView.delegate = self
        collectionView.delegate = self
        fetchedResultsController.delegate = self
        
        // Init Map
        initMap()
    }
    
    // Mark: Init Map
    private func initMap() {
        
        let annotation = MKPointAnnotation()
        annotation.coordinate.latitude = selectedLocation.latitude
        annotation.coordinate.longitude = selectedLocation.longitude
        
        performUIUpdatesOnMain {
            self.mapView.addAnnotation(annotation)
        }
    }
    
    @IBAction func performPictureAction(_ sender: Any) {
    
    }
    
    func performFetch() {
        do {
            try fetchedResultsController.performFetch()
        } catch {
            // TODO : Perform error handling
            fatalError("Failed to initialize FetchedResultsController: \(error)")
        }
    }
}

