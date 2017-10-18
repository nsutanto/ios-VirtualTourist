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
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    // make a cell for each cell index path
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // get a reference to our storyboard cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionViewCell", for: indexPath as IndexPath) as! PictureCollectionViewCell
        
        performUIUpdatesOnMain {
            cell.imageView.image = nil
            cell.activityIndicator.isHidden = false
            cell.activityIndicator.startAnimating()
        }
        
        let image = fetchedResultsController.object(at: indexPath)
        
        if let imageData = image.imageBinary {
            performUIUpdatesOnMain {
                cell.imageView.image = UIImage(data: imageData as Data)
                cell.activityIndicator.stopAnimating()
                cell.activityIndicator.isHidden = true
            }
        }
        else {
            // Download image
            let task = FlickrClient.sharedInstance().downloadImage(imageURL: image.imageURL!, completionHandler: { (imageData, error) in
                if (error == nil) {
                    performUIUpdatesOnMain {
                        cell.imageView.image = UIImage(data: imageData!)
                        cell.activityIndicator.stopAnimating()
                        cell.activityIndicator.isHidden = true
                    }
                    
                    image.imageBinary = imageData as NSData?
                    self.coreDataStack?.save()
                    
                } else {
                    print("***** Download error")
                }
            })
            cell.taskToCancelifCellIsReused = task
        }
       
        return cell
    }
}

extension PictureViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // Reset indexes
        insertIndexes.removeAll()
        deleteIndexes.removeAll()
        updateIndexes.removeAll()
        
        // Update UI
        updateUIWhenDownloadingImage(true)
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        // Assigned all the indexes so that we can update the cell accordingly
       
        switch (type) {
        case .insert:
            insertIndexes.append(newIndexPath!)
        case .delete:
            deleteIndexes.append(indexPath!)
        case .update:
            updateIndexes.append(indexPath!)
        default:
            break
        }
    }
    
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.performBatchUpdates( {
            self.collectionView.insertItems(at: insertIndexes)
            self.collectionView.deleteItems(at: deleteIndexes)
            self.collectionView.reloadItems(at: updateIndexes)
        }, completion: nil)
        
        
        // Update UI
        updateUIWhenDownloadingImage(false)
    }
}

extension PictureViewController: UICollectionViewDelegate {
  
    // When user select one of the cell
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        // Get the specific cell
        let cell = collectionView.cellForItem(at: indexPath as IndexPath)
        if (!selectedIndexes.contains(indexPath)) {
            // Add to selected index
            selectedIndexes.append(indexPath)
            // Change selected cell color
            cell?.alpha = 0.5
        } else {
            // Remove index from selected indexes
            let index = selectedIndexes.index(of: indexPath)
            selectedIndexes.remove(at: index!)
            // Change selected cell color
            cell?.alpha = 1
        }
   
        // Whenever user selects one or more cells, the bar button changes to Remove seleceted pictures
        // else set to default title
        if (selectedIndexes.count == 0) {
            buttonPictureAction.setTitle(NEW_COLLECTION, for: .normal)
        } else {
            buttonPictureAction.setTitle(REMOVE_IMAGE, for: .normal)
        }
    }
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
    // Insert, Delete, and Update index for the fetched results controller
    var insertIndexes = [IndexPath]()
    var deleteIndexes = [IndexPath]()
    var updateIndexes = [IndexPath]()
    // Selected Index is used to delete the pictures
    var selectedIndexes = [IndexPath]()
    // Total page number for flickr. Init to 1 for default. Once we get the first request, we will generate random number.
    var totalPageNumber = 1
    var currentPageNumber = 1
    // Some String Constant
    let REMOVE_IMAGE = "Remove selected pictures"
    let NEW_COLLECTION = "New Collection"
    
    
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
        initLayout(size: view.frame.size)
        // Initialize fetched results controller from core data stack
        performFetch()
        // Init Map
        initMap()
        // Init Photos
        initPhotos()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        initLayout(size: size)
    }
    
    // Mark : Init Layout
    func initLayout(size: CGSize) {
        let space: CGFloat = 3.0
        let dimension: CGFloat
        
        dimension = (size.width - (2 * space)) / 3.0
        
        flowLayout?.minimumInteritemSpacing = space
        flowLayout?.minimumLineSpacing = space
        flowLayout?.itemSize = CGSize(width: dimension, height: dimension)
    }
    
    // Mark: Init Map
    private func initMap() {
        
        let annotation = MKPointAnnotation()
        annotation.coordinate.latitude = selectedLocation.latitude
        annotation.coordinate.longitude = selectedLocation.longitude
        
        let centerCoordinate = CLLocationCoordinate2D(latitude: selectedLocation.latitude, longitude: selectedLocation.longitude)
        let spanCoordinate = MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        let region = MKCoordinateRegion(center: centerCoordinate, span: spanCoordinate)
        
        performUIUpdatesOnMain {
            self.mapView.setRegion(region, animated: true)
            self.mapView.addAnnotation(annotation)
        }
    }
    
    // Mark: Init Photos
    private func initPhotos() {
        if (fetchedResultsController.fetchedObjects?.count == 0) {
            getPhotoFromFlickr(currentPageNumber)
        }
    }
    
    private func getPhotoFromFlickr(_ pageNumber: Int) {
        FlickrClient.sharedInstance().searchPhotos(selectedLocation.longitude,
                                                   selectedLocation.latitude,
                                                   pageNumber,
                                                   completionHandlerSearchPhotos: { (result, pageNumberResult, error ) in
            if (error == nil) {
                // No result. Hide the collection view to show the no collection available label
                if (result?.count == 0) {
                    performUIUpdatesOnMain {
                        self.collectionView.isHidden = true
                    }
                }
                
                for urlString in result! {
                    let image = Image(urlString: urlString, imageData: nil, context: (self.coreDataStack?.context)!)
                    self.selectedLocation.addToLocationToImage(image)
                }
                self.totalPageNumber = pageNumberResult!
            }
            else {
                self.alertError("Fail to get images from Flickr")
            }
        })
    }
    
    private func downloadImages() {
        coreDataStack?.performBackgroundBatchOperation { (workerContext) in
            for image in self.fetchedResultsController.fetchedObjects! {
                if image.imageBinary == nil {
                    let imageURL = URL(string: image.imageURL!)
                    if let imageData = try? Data(contentsOf: imageURL!) {
                        image.imageBinary = imageData as NSData
                    }
                }
            }
        }
    }
    
    // Delete selected image
    private func deleteSelectedImage() {
        
        for index in selectedIndexes {
            coreDataStack?.context.delete(fetchedResultsController.object(at: index))
        }
        // reset indexes
        selectedIndexes.removeAll()
        // core data save. Fetch results controller will magically update the UI
        coreDataStack?.save()
    }
    
    // Delete all the existing images
    private func clearImages() {
        
        for object in fetchedResultsController.fetchedObjects! {
            coreDataStack?.context.delete(object)
        }
        coreDataStack?.save()
    }
    
    private func alertError(_ alertMessage: String) {
        performUIUpdatesOnMain {
            let alert = UIAlertController(title: "Alert", message: alertMessage, preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func updateUIWhenDownloadingImage(_ isDownloading: Bool) {
        performUIUpdatesOnMain {
            if isDownloading {
                self.buttonPictureAction.isEnabled = false
            } else {
                self.buttonPictureAction.isEnabled = true
            }
        }
        
    }
    
    @IBAction func performPictureAction(_ sender: Any) {
        if (buttonPictureAction.titleLabel?.text == NEW_COLLECTION) {
            // Disable the button
            //updateUIWhenDownloadingImage(true)
            buttonPictureAction.isEnabled = false
            // Delete all images
            clearImages()
            // Get new images
            if (currentPageNumber < totalPageNumber) {
                currentPageNumber = currentPageNumber + 1
            }
            else {
                currentPageNumber = totalPageNumber
            }
            
            self.collectionView.isHidden = false
            
            getPhotoFromFlickr(currentPageNumber)
            downloadImages()
            
        } else {
            deleteSelectedImage()
        }
    }
}

