//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Nicholas Sutanto on 10/5/17.
//  Copyright © 2017 Nicholas Sutanto. All rights reserved.
//

import Foundation

class FlickrClient {
    // shared session
    
    var session = URLSession.shared
    
    
    // MARK: Shared Instance
    
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }
    
    
    // GET Student Locations
    
    func searchPhotos(_ longitude: Double,
                      _ latitude: Double,
                      _ pageNumber: Int = 1,
                      completionHandlerSearchPhotos: @escaping (_ result: [String]?, _ pageNumber: Int?, _ error: NSError?)
        -> Void) {
     
        /* 1. Specify parameters, method (if has {key}), and HTTP body (if POST) */
        let methodParameters = [
            FlickrParameterKeys.Method: Methods.Search,
            FlickrParameterKeys.APIKey: Constants.APIKey,
            FlickrParameterKeys.SafeSearch: FlickrParameterValues.UseSafeSearch,
            FlickrParameterKeys.Extras: FlickrParameterValues.SquareURL,
            FlickrParameterKeys.Format: FlickrParameterValues.Json,
            FlickrParameterKeys.NoJsonCallback: FlickrParameterValues.JsonCallBackValue,
            FlickrParameterKeys.PerPage: FlickrParameterValues.PerPageValue,
            FlickrParameterKeys.Page: String(pageNumber),
            FlickrParameterKeys.Latitude: String(latitude),
            FlickrParameterKeys.Longitude: String(longitude)
        ]
        
        let request = URLRequest(url: parseURLFromParameters(methodParameters as [String : AnyObject]))
        
        /* 2. Make the request */
        let _ = performRequest(request: request as! NSMutableURLRequest) { (parsedResult, error) in
            
            /* 3. Send the desired value(s) to completion handler */
            if let error = error {
                completionHandlerSearchPhotos(nil, nil, error)
            } else {
                
                /* GUARD: Is the "photos" key in our result? */
                guard let photosDictionary = parsedResult?[FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                    // TODO : perform error handling
                    return
                }
                
                guard let pageNumberOut = photosDictionary[FlickrResponseKeys.Pages] as? Int else {
                    return
                }
                
                /* GUARD: Is the "photo" key in photosDictionary? */
                guard let photosArray = photosDictionary[FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
                    // TODO : perform error handling
                    return
                }
             
                if photosArray.count == 0 {
                    // TODO : perform error handling
                    return
                } else {
                    var urlArray = [String]()
                    
                    for photo in photosArray {
                        let photoDictionary = photo as [String:Any]
                        
                        /* GUARD: Does our photo have a key for 'url_q'? */
                        guard let imageUrlString = photoDictionary[FlickrResponseKeys.SquareURL] as? String else {
                            // TODO : perform error handling
                            return
                        }
                        
                        urlArray.append(imageUrlString)
                    }
                    
                     completionHandlerSearchPhotos(urlArray, pageNumberOut, nil)
                }
            }
        }
 
    }
    
    func downloadImage(imageURL: String, completionHandler: @escaping(_ imageData: Data?, _ error: NSError?) ->  Void) -> URLSessionTask {
        
        let url = URL(string: imageURL)
        let request = URLRequest(url: url!)
        
        let task = session.dataTask(with: request) {data, response, downloadError in
            
            if let error = downloadError {
                //completionHandler(imageData: nil, error: newError)
                // TODO : Handle error
                print("***** Task Download error")
            } else {
                completionHandler(data, nil)
            }
        }
        
        task.resume()
        return task
    }
    
    private func performRequest(request: NSMutableURLRequest,
                                completionHandlerRequest: @escaping (_ result: AnyObject?, _ error: NSError?) -> Void)
        -> URLSessionDataTask {
            
            let task = session.dataTask(with: request as URLRequest) { data, response, error in
                
                func sendError(_ error: String) {
                    print(error)
                    let userInfo = [NSLocalizedDescriptionKey : error]
                    completionHandlerRequest(nil, NSError(domain: "performRequest", code: 1, userInfo: userInfo))
                }
                
                /* GUARD: Was there an error? */
                guard (error == nil) else {
                    sendError("There was an error with your request: \(error!)")
                    return
                }
                
                /* GUARD: Did we get a successful 2XX response? */
                guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                    let httpError = (response as? HTTPURLResponse)?.statusCode
                    sendError("Your request returned a status code : \(String(describing: httpError))")
                    return
                }
                
                /* GUARD: Was there any data returned? */
                guard let data = data else {
                    sendError("No data was returned by the request!")
                    return
                }
                
                //print(NSString(data: data, encoding: String.Encoding.utf8.rawValue)!)
                self.convertDataWithCompletionHandler(data, completionHandlerConvertData: completionHandlerRequest)
            }
            
            task.resume()
            return task
    }
    
    // given raw JSON, return a usable Foundation object
    private func convertDataWithCompletionHandler(_ data: Data, completionHandlerConvertData: (_ result: AnyObject?, _ error: NSError?) -> Void) {
        
        var parsedResult: AnyObject! = nil
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
            completionHandlerConvertData(nil, NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        
        completionHandlerConvertData(parsedResult, nil)
    }
    
    // create a URL from parameters
    private func parseURLFromParameters(_ parameters: [String:AnyObject]?, withPathExtension: String? = nil) -> URL {
        
        var components = URLComponents()
        components.scheme = Constants.ApiScheme
        components.host = Constants.ApiHost
        components.path = Constants.ApiPath + (withPathExtension ?? "")
        components.queryItems = [URLQueryItem]()
        
        if let parameters = parameters {
            for (key, value) in parameters {
                let queryItem = URLQueryItem(name: key, value: "\(value)")
                components.queryItems!.append(queryItem)
            }
        }
        
        print(components.url!.absoluteString)
        return components.url!
    }
}