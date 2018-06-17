//
//  ViewController.swift
//  PixelCity
//
//  Created by Arif Onur Şen on 17.02.2018.
//  Copyright © 2018 LiniaTech. All rights reserved.
//

import UIKit
import MapKit
import Alamofire
import AlamofireImage
import CoreLocation

class MapVC: UIViewController {

    @IBOutlet weak var mapView: MKMapView!

    @IBOutlet weak var pullUpHeightCons: NSLayoutConstraint!
    
    @IBOutlet weak var pullUpView: UIView!
    var locationManager = CLLocationManager()
    var authStatus = CLLocationManager.authorizationStatus()
    let regionRadius: Double = 1000
    
    var screenSize = UIScreen.main.bounds
    
    var spinner: UIActivityIndicatorView?
    var loadLbl: UILabel?
    
    var flowLayout = UICollectionViewFlowLayout()
    var collectionView: UICollectionView?
    
    var imagesUrls = [String]()
    var images = [UIImage]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        configureLocationServices()
        doubleTap()
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
        collectionView?.register(PhotoCell.self, forCellWithReuseIdentifier: "photoCell")
        collectionView?.backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        collectionView?.delegate = self
        collectionView?.dataSource = self
        pullUpView.addSubview(collectionView!)
        registerForPreviewing(with: self, sourceView: collectionView!)
    }
    
    @IBAction func locationBtnPressed(_ sender: Any) {
        if authStatus == .authorizedAlways || authStatus == .authorizedWhenInUse {
            centerMapOnUser()
        }
        
    }
    
    func swipeDown() {
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(animateViewDown))
        swipeDown.direction = .down
        pullUpView.addGestureRecognizer(swipeDown)
    }
    
    func animateViewUp() {
        pullUpHeightCons.constant = 300
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    func addSpinner() {
        spinner = UIActivityIndicatorView()
        spinner?.center = CGPoint(x: (screenSize.width / 2) - ((spinner?.frame.width)! / 2), y: 150)
        spinner?.activityIndicatorViewStyle = .whiteLarge
        spinner?.color = #colorLiteral(red: 0.9372094225, green: 0.3192563114, blue: 0.2439649536, alpha: 1)
        spinner?.startAnimating()
        collectionView?.addSubview(spinner!)
    }
    
    func removeSpinner() {
        if spinner != nil {
            spinner?.removeFromSuperview()
        }
    }
    
    func addProgressLbl() {
        loadLbl = UILabel()
        loadLbl?.frame = CGRect(x: (screenSize.width / 2) - 110, y: 175, width: 220, height: 40)
        loadLbl?.font = UIFont(name: "Avenir Next", size: 15)
        loadLbl?.textColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        loadLbl?.textAlignment = .center
        loadLbl?.text = ""
        collectionView?.addSubview(loadLbl!)
    }
    
    func removeProgressLbl() {
        if loadLbl != nil {
            loadLbl?.removeFromSuperview()
        }
    }
    
    @objc func animateViewDown() {
        GetPhotos.instance.cancelSessions()
        pullUpHeightCons.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
}


extension MapVC: UIGestureRecognizerDelegate {
    func doubleTap() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(dropPin(sender:)))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        mapView.addGestureRecognizer(doubleTap)
    }
}


extension MapVC: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        let pinAnnotation = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "droppablePin")
        pinAnnotation.pinTintColor = #colorLiteral(red: 0.9372094225, green: 0.3192563114, blue: 0.2439649536, alpha: 1)
        pinAnnotation.animatesDrop = true
        return pinAnnotation
    }
    func centerMapOnUser() {
        guard let coordinate = locationManager.location?.coordinate else {return}
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinate, regionRadius, regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    @objc func dropPin(sender: UITapGestureRecognizer) {
        removePin()
        removeSpinner()
        removeProgressLbl()
        GetPhotos.instance.cancelSessions()
        
        self.imagesUrls.removeAll()
        self.images.removeAll()
        
        self.collectionView?.reloadData()
        
        animateViewUp()
        swipeDown()
        addSpinner()
        addProgressLbl()
        
        let touchPoint = sender.location(in: mapView)
        let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        
        let annotation = DroppablePin(coordinate: touchCoordinate, identifier: "droppablePin")
        mapView.addAnnotation(annotation)
        
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(touchCoordinate, regionRadius, regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
        getUrls(annotation: annotation) { (success) in
            if success {
                self.getImages(completion: { (success) in
                    if success {
                        self.removeSpinner()
                        self.removeProgressLbl()
                        self.collectionView?.reloadData()
                    }
                })
            }
        }
    }
    
    func getUrls(annotation: DroppablePin, completion: @escaping CompletionHander) {
        GetPhotos.instance.removeContent()
        GetPhotos.instance.getUrls(forAnnotation: annotation) { (success) in
            if success {
                if GetPhotos.instance.imagesContent.count > 0 {
                    for url in GetPhotos.instance.imagesContent {
                        let flickr = "https://farm\(url.farm!).staticflickr.com/\(url.server!)/\(url.id!)_\(url.secret!)_h_d.jpg"
                        self.imagesUrls.append(flickr)
                    }
                    completion(true)
                }
            } else {
                completion(false)
            }
        }
    }
    
    func getImages(completion: @escaping CompletionHander) {
        self.images = []
        
        for image in self.imagesUrls {
            Alamofire.request(image).responseImage(completionHandler: { (response) in
                guard let data = response.result.value else {return}
                self.images.append(data)
                self.loadLbl?.text = "\(self.images.count)/40 Photos Loaded"
                
                if self.images.count == self.imagesUrls.count {
                    completion(true)
                } else {
                    completion(false)
                }
            })
        }
        
    }
    
    func removePin() {
        for annotation in mapView.annotations {
            mapView.removeAnnotation(annotation)
        }
    }
}

extension MapVC: CLLocationManagerDelegate {
    func configureLocationServices() {
        if authStatus == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        } else {
            return
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        centerMapOnUser()
    }
}

extension MapVC: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as? PhotoCell else { return UICollectionViewCell() }
        let imageFromIndex = images[indexPath.row]
        let image = UIImageView(image: imageFromIndex)
        cell.addSubview(image)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let popVC = storyboard?.instantiateViewController(withIdentifier: "PopVC") as? PopVC else {
            return
        }
        popVC.getImage(image: images[indexPath.row])
        present(popVC, animated: true, completion: nil)
    }
}

extension MapVC: UIViewControllerPreviewingDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = collectionView?.indexPathForItem(at: location), let cell = collectionView?.cellForItem(at: indexPath) else {return nil}
        guard let popVC = storyboard?.instantiateViewController(withIdentifier: "PopVC") as? PopVC else {return nil}
        popVC.getImage(image: images[indexPath.row])
        previewingContext.sourceRect = cell.contentView.frame
        
        return popVC
        
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: self)
    }
    
    
}

















