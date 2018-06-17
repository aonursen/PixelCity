//
//  PopVC.swift
//  PixelCity
//
//  Created by Arif Onur Şen on 20.02.2018.
//  Copyright © 2018 LiniaTech. All rights reserved.
//

import UIKit

class PopVC: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    var selectedImage: UIImage!
    
    func getImage(image: UIImage) {
        selectedImage = image
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = selectedImage
        swipeDown()
    }
    
    func swipeDown() {
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(dismissView))
        swipeDown.direction = .down
        view.addGestureRecognizer(swipeDown)
    }
    
    @objc func dismissView() {
        dismiss(animated: true, completion: nil)
    }

}
