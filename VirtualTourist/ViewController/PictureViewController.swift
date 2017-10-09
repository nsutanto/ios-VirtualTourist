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
        //print("***** Count = \(flickrImages?.count ?? 0)")
        //return flickrImages?.count ?? 0
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    // make a cell for each cell index path
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // get a reference to our storyboard cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionViewCell", for: indexPath as IndexPath) as! PictureCollectionViewCell
        
        print("***** Get Image")
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
        // Reset indexes
        insertIndexes = [IndexPath]()
        deleteIndexes = [IndexPath]()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        // Assigned all the indexes so that we can update the cell accordingly
        switch(type) {
        case .insert:
            insertIndexes.append(newIndexPath!)
        case .delete:
            deleteIndexes.append(newIndexPath!)
        default:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.performBatchUpdates( {
            self.collectionView.insertItems(at: insertIndexes)
            self.collectionView.deleteItems(at: deleteIndexes)
        }, completion: nil)
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
    
    // Selected Location from previous navigation controller
    var selectedLocation: Location!
    // Core Data Stack
    var coreDataStack: CoreDataStack?
    // List of flickr images
    var flickrImages : [Image]?
    // Insert and Delete index for the fetched results controller
    var insertIndexes: [IndexPath]!
    var deleteIndexes: [IndexPath]!
    
    lazy var fetchedResultsController: NSFetchedResultsController<Image> = {
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Image")
        request.sortDescriptors = [NSSortDescriptor(key: "imageURL", ascending: true)]
        request.predicate = NSPredicate(format: "imageToLocation == %@", self.selectedLocation)
        
        let moc = coreDataStack?.context
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: request as! NSFetchRequest<Image>,
                                                                  managedObjectContext: moc!,
                                                                  sectionNameKeyPath: nil,
                                                                  cacheName: nil)
        
       
        
        return fetchedResultsController
    }()
    
    func performFetch() {
        do {
            try fetchedResultsController.performFetch()
        } catch {
            // TODO : Perform error handling
            fatalError("Failed to initialize FetchedResultsController: \(error)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize core data stack
        let delegate = UIApplication.shared.delegate as! AppDelegate
        coreDataStack = delegate.stack
        
        // Initialize delegate
        mapView.delegate = self
        collectionView.delegate = self
        fetchedResultsController.delegate = self
        
        // Initialize fetched results controller from core data stack
        performFetch()
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

