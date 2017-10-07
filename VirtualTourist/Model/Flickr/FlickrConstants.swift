//
//  FlickrConstants.swift
//  VirtualTourist
//
//  Created by Nicholas Sutanto on 10/5/17.
//  Copyright © 2017 Nicholas Sutanto. All rights reserved.
//

import Foundation

extension FlickrClient {
    
    // MARK: Constants
    struct Constants {
        // MARK: API Key and Application ID
        static let APIKey = "9881c57d3b69bebfe22619173ecaf54e"
        
        // MARK: URLs
        static let ApiScheme = "https"
        static let ApiHost = "api.flickr.com"
        static let ApiPath = "/services/rest"
    }
    
    // MARK: Methods
    struct Methods {
        // MARK: StudentLocation
        static let Search = "flickr.photos.search"
    }
    
    // MARK: Flickr Parameter Keys
    struct FlickrParameterKeys {
        static let Method = "method"
        static let APIKey = "api_key"
        static let Extras = "extras"
        static let SafeSearch = "safe_search"
        static let Longitude = "lon"
        static let Latitude = "lat"
        static let Format = "format"
        static let NoJsonCallback = "nojsoncallback"
    }
    
    // MARK: Flickr Parameter Values
    struct FlickrParameterValues {
        static let MediumURL = "url_m"
        static let SquareURL = "url_q"
        static let UseSafeSearch = "1"
        static let Json = "json"
        static let JsonCallBackValue = "1"
    }
    
    // MARK: Flickr Response Keys
    struct FlickrResponseKeys {
        static let Status = "stat"
        static let Photos = "photos"
        static let Photo = "photo"
        static let MediumURL = "url_m"
        static let Pages = "pages"
        static let Total = "total"
        
    }
    
    // MARK: Flickr Response Values
    struct FlickrResponseValues {
        static let OKStatus = "ok"
    }
}
