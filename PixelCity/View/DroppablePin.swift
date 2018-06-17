//
//  DroppablePin.swift
//  PixelCity
//
//  Created by Arif Onur Şen on 19.02.2018.
//  Copyright © 2018 LiniaTech. All rights reserved.
//

import Foundation
import MapKit


class DroppablePin: NSObject, MKAnnotation {
    dynamic var coordinate: CLLocationCoordinate2D
    var identifier: String
    
    init(coordinate: CLLocationCoordinate2D, identifier: String) {
        self.coordinate = coordinate
        self.identifier = identifier
    }
    
}
