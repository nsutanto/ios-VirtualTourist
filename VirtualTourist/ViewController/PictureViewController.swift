//
//  PictureViewController.swift
//  VirtualTourist
//
//  Created by Nicholas Sutanto on 9/29/17.
//  Copyright © 2017 Nicholas Sutanto. All rights reserved.
//

import UIKit
import MapKit

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
    
    var annotation: MKAnnotation!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
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

