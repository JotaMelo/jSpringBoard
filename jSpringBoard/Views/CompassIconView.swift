//
//  CompassIconView.swift
//  jSpringBoard
//
//  Created by Jota Melo on 08/09/17.
//  Copyright © 2017 jota. All rights reserved.
//

import UIKit
import CoreLocation

class CompassIconView: UIView, CLLocationManagerDelegate {
    private var locationManager: CLLocationManager
    private var imageView: UIImageView
    
    override init(frame: CGRect) {
        self.locationManager = CLLocationManager()
        self.locationManager.startUpdatingHeading()
        
        self.imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        self.imageView.image = #imageLiteral(resourceName: "compass-icon")
        
        super.init(frame: frame)
        
        self.backgroundColor = .black
        self.locationManager.delegate = self
        self.addSubview(self.imageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let radians = -newHeading.magneticHeading * .pi / 180
        self.imageView.transform = CGAffineTransform.identity.rotated(by: CGFloat(radians))
    }
}
