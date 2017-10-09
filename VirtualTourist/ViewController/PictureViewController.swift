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
        print("***** Count = \(flickrImages?.count ?? 0)")
        return flickrImages?.count ?? 0
    }
    
    // make a cell for each cell index path
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // get a reference to our storyboard cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionViewCell", for: indexPath as IndexPath) as! PictureCollectionViewCell
        
        let image = fetchedResultsController.object(at: indexPath)
        
        if let imageData = image.imageBinary {
            print("***** Assign Image")
            // assign image
            cell.imageView.image = UIImage(data: imageData as Data)
        }
        else {
            print("***** Download Image")
            // Download image
            downloadImage(imageURL: image.imageURL!) { (imageData) -> Void in
                // Display it
                cell.imageView.image = UIImage(data: imageData as Data)
                    
                // Stop animating
                //cell.activityView.stopAnimating()
            }
        }
        return cell
    }
}

extension PictureViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        //tableView.beginUpdates()
        print("controller will change content")
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        
        //print("controller didChange 0")
        /*
        let set = IndexSet(integer: sectionIndex)
        
        switch (type) {
        case .insert:
            tableView.insertSections(set, with: .fade)
        case .delete:
            tableView.deleteSections(set, with: .fade)
        default:
            // irrelevant in our case
            break
        }*/
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        //print("controller didChange 1")
        /*
        switch(type) {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .fade)
        case .update:
            tableView.reloadRows(at: [indexPath!], with: .fade)
        case .move:
            tableView.deleteRows(at: [indexPath!], with: .fade)
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        }
 */
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        //tableView.endUpdates()
        // Download Images
        
        print("controller didChange 2")
    }
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
    var flickrImages : [Image]?
    
    lazy var fetchedResultsController: NSFetchedResultsController<Image> = {
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Image")
        request.sortDescriptors = [NSSortDescriptor(key: "imageURL", ascending: true)]
        request.predicate = NSPredicate(format: "imageToLocation == %@", self.selectedLocation)
        
        let moc = coreDataStack?.context
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: request as! NSFetchRequest<Image>,
                                                                  managedObjectContext: moc!,
                                                                  sectionNameKeyPath: nil,
                                                                  cacheName: nil)
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            // TODO : Perform error handling
            fatalError("Failed to initialize FetchedResultsController: \(error)")
        }
        
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
        // Init Photos
        initPhotos()
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
    
    private func initPhotos() {
        flickrImages = fetchedResultsController.fetchedObjects!
        
        if (flickrImages?.count == 0) {
            getPhotoFromFlickr()
        } else {
            print("***** Flickr image is not 0")
            // TODO
        }
    }
    
    private func getPhotoFromFlickr() {
        FlickrClient.sharedInstance().searchPhotos(selectedLocation.longitude, selectedLocation.latitude, completionHandlerSearchPhotos: { (result, error ) in
            if (error == nil) {
                print("**** Get Data from flickr")
                for urlString in result! {
                    let image = Image(urlString: urlString, imageData: nil, context: (self.coreDataStack?.context)!)
                    self.selectedLocation.addToLocationToImage(image)
                }
            }
            else {
                print("**** Error requesting flickr")
            // TODO: Perform alert
            }
        })
    }
    
    private func downloadImages() {
        coreDataStack?.performBackgroundBatchOperation { (workerContext) in
            for image in self.flickrImages! {
                if image.imageBinary == nil {
                    let imageURL = URL(string: image.imageURL!)
                    if let imageData = try? Data(contentsOf: imageURL!) {
                        image.imageBinary = imageData as NSData
                    }
                }
            }
        }
    }
    
    // MARK: Download Big Image
    
    // This method downloads and image in the background once it's
    // finished, it runs the closure it receives as a parameter.
    // This closure is called a completion handler
    // Go download the image, and once you're done, do _this_ (the completion handler)
    func downloadImage(imageURL: String, completionHandler handler: @escaping (_ imgData: Data) -> Void){
        
        print("***** download big image")
        DispatchQueue.global(qos: .userInitiated).async { () -> Void in
            
            // get the url
            // get the NSData
            // turn it into a UIImage
            if let url = URL(string: imageURL),
                let imgData = try? Data(contentsOf: url) {
                // run the completion block
                // always in the main queue, just in case!
                DispatchQueue.main.async(execute: { () -> Void in
                    handler(imgData)
                })
            }
        }
    }

    
    @IBAction func performPictureAction(_ sender: Any) {
    
    }
}

