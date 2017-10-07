//
//  PictureViewController.swift
//  VirtualTourist
//
//  Created by Nicholas Sutanto on 9/29/17.
//  Copyright © 2017 Nicholas Sutanto. All rights reserved.
//

import UIKit
import MapKit



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
    
    var annotation: MKAnnotation!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        collectionView.delegate = self
        initMap()
    }
    
    // Mark: Init Map
    private func initMap() {
        performUIUpdatesOnMain {
            self.mapView.addAnnotation(self.annotation)
        }
    }
    
    @IBAction func performPictureAction(_ sender: Any) {
    
    }
}

