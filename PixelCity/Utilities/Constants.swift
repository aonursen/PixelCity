//
//  Constants.swift
//  PixelCity
//
//  Created by Arif Onur Şen on 20.02.2018.
//  Copyright © 2018 LiniaTech. All rights reserved.
//

import Foundation


typealias CompletionHander = (_ success: Bool) -> ()


let API_KEY = "*****"

func flickrURL(forApiKey key: String, withAnnotation annotation: DroppablePin, andNumberOfPhotos number: Int) -> String {
    let url = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(API_KEY)&lat=\(annotation.coordinate.latitude)&lon=\(annotation.coordinate.longitude)&radius=1&radius_units=mi&per_page=\(number)&format=json&nojsoncallback=1"
    return url
}
