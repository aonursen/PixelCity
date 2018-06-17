//
//  GetPhotos.swift
//  PixelCity
//
//  Created by Arif Onur Şen on 20.02.2018.
//  Copyright © 2018 LiniaTech. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON


class GetPhotos {
    static let instance = GetPhotos()
    var imagesContent = [PhotosUrls]()
    
    func getUrls(forAnnotation annotation: DroppablePin, completion: @escaping CompletionHander) {
        let url = flickrURL(forApiKey: API_KEY, withAnnotation: annotation, andNumberOfPhotos: 40)
        Alamofire.request(url).responseJSON { (response) in
            if response.result.error == nil {
                guard let data = response.data else {return}
                let json = try! JSON(data: data)
                if let photos = json["photos"]["photo"].array {
                    for item in photos {
                        let url = PhotosUrls(farm: item["farm"].intValue, server: item["server"].stringValue, id: item["id"].stringValue, secret: item["secret"].stringValue)
                        self.imagesContent.append(url)
                    }
                }
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    func removeContent() {
        self.imagesContent.removeAll()
    }
    
    func cancelSessions() {
        Alamofire.SessionManager.default.session.getTasksWithCompletionHandler { (sessionDataTask, sessionUploadTask, sessionDownloadTask) in
            sessionDataTask.forEach({ $0.cancel() })
            sessionDownloadTask.forEach({ $0.cancel() })
        }
    }
    
    
}
