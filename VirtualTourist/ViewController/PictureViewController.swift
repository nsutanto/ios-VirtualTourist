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

extension PictureViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let width = floor(collectionView.frame.size.width)
        let height = floor(collectionView.frame.size.height)
        
        let numberAcross:CGFloat = ((width < height) ? 3.0 : 5.0)
        
        let itemSize = (width - ((numberAcross - 1) * flowLayout.minimumLineSpacing)) / numberAcross
        
        return CGSize(width: itemSize, height: itemSize)
    }
}

extension PictureViewController: UICollectionViewDataSource {
    // tell the collection view how many cells to make
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("***** Count = \(fetchedResultsController.sections?[section].numberOfObjects ?? 0)")
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    // make a cell for each cell index path
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // get a reference to our storyboard cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionViewCell", for: indexPath as IndexPath) as! PictureCollectionViewCell
        
        //print("***** Get Image")
        let image = fetchedResultsController.object(at: indexPath)
        
        cell.activityIndicator.startAnimating()
        if let imageData = image.imageBinary {
            //print("***** Assign Image")
            // assign image
            cell.imageView.image = UIImage(data: imageData as Data)
        }
        else {
            //print("***** Download Image")
            // Download image
            downloadImage(imageURL: image.imageURL!) { (imageData) -> Void in
                // Display it
                cell.imageView.image = UIImage(data: imageData as Data)
                // Save it to Core Data
                image.imageBinary = imageData as NSData
                // Stop animating
                
            }
        }
        cell.activityIndicator.stopAnimating()
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
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
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
        
        // Init Layout
        initLayout()
        // Initialize fetched results controller from core data stack
        performFetch()
        // Init Map
        initMap()
        // Init Photos
        initPhotos()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        // Init Layout
        initLayout()
        
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
    private func downloadImage(imageURL: String, completionHandler handler: @escaping (_ imgData: Data) -> Void){
        
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
    /*
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Lay out the collection view so that cells take up 1/3 of the width,
        // with no space in between.
        let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        let width = floor(self.collectionView.frame.size.width/3)
        layout.itemSize = CGSize(width: width, height: width)
        print("***** Width \(width)")
        
        collectionView.collectionViewLayout = layout
    }*/
    
    private func initLayout() {
        
        /*
        print("**** init layout")
        let space : CGFloat = 1
        var height : CGFloat!
        var width : CGFloat!
        var numberOfPictures : CGFloat!
        
        numberOfPictures = 3
        
        if UIDevice.current.orientation.isPortrait {
            width = (collectionView.frame.size.width / numberOfPictures) - space
        }
        else {
            width = (collectionView.frame.size.height / numberOfPictures) - space
        }
        height = width
        print("***** Collection View width = \(collectionView.frame.size.width)")
        print("***** Collection View height = \(collectionView.frame.size.width)")
        print("***** Width \(width)")
        
        let flowLayout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = (view.frame.size.width - (numberOfPictures * width)) / (numberOfPictures - 1)
        flowLayout.itemSize = CGSize(width: width, height: height)
        collectionView.collectionViewLayout = flowLayout
         */
    }

    
    @IBAction func performPictureAction(_ sender: Any) {
    
    }
}

