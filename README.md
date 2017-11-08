# Virtual Tourist

The Virtual Tourist app downloads and stores images from Flickr. The app allows users to drop pins on a map, as if they were stops on a tour. Users will then be able to download pictures for the location and persist both the pictures, and the association of the pictures with the pin. Locations and images are stored using Core Data.

API used : Flickr

## Technical Features
Use NSURLSessions to interact with a public restful API
Create a user interface that intuitively communicates network activity and download progress
Store media on the device file system Use Core Data for local persistence of an object structure

### Add Map Pin
<img src="https://media.giphy.com/media/l4Ep3KjU767Xzv11C/giphy.gif" width="300">

### Delete Map Pin
<img src="https://media.giphy.com/media/3ohjV0RGllpl69aSg8/giphy.gif" width="300">

### Browse Random Images
- Use Flickr API
- Asynchronously download images, and perform batch save to core data
- Update image cell as needed
- Use FetchResultsController to update the UI if CoreData is updated

<img src="https://github.com/nsutanto/ios-VirtualTourist/blob/master/ImageAndMedia/giphy/giphy-browseImages.gif" width="300">

### Remove Images
<img src="https://media.giphy.com/media/3ohjUSK8rXNSdvrQQw/giphy.gif" width="300">

### Persist Map Pins
<img src="https://media.giphy.com/media/l4EoTt9HYSnoVKQSY/giphy.gif" width="300">

### Persist Center Map and Zoom Level
<img src="https://github.com/nsutanto/ios-VirtualTourist/blob/master/ImageAndMedia/giphy/giphy-persistZoomLevel.gif" width="300">

### Persist Images
<img src="https://github.com/nsutanto/ios-VirtualTourist/blob/master/ImageAndMedia/giphy/giphy-persistImages.gif" width="300">

## Website
https://nsutanto.blogspot.com/p/virtual-tourist.html
