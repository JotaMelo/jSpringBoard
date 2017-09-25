//
//  WeatherWidgetViewController.swift
//  jSpringBoard
//
//  Created by Jota Melo on 27/08/17.
//  Copyright © 2017 jota. All rights reserved.
//

import UIKit

class WeatherWidgetViewController: UIViewController {

    @IBOutlet var separator: UIView!
    @IBOutlet var hourlyView: UIStackView!
    @IBOutlet var hourlyImageViews: [UIImageView]!
    @IBOutlet var hourlyTemperatureLabels: [UILabel]!
    
    @IBOutlet var containerHeightConstraint: NSLayoutConstraint!
    @IBOutlet var separatorHeightConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.separatorHeightConstraint.constant = 1 / UIScreen.main.scale
        self.containerHeightConstraint.constant = 110
        self.view.layoutIfNeeded()
        
        self.separator.alpha = 0
        self.hourlyView.alpha = 0
        self.hourlyImageViews.forEach { $0.transform = CGAffineTransform.identity.scaledBy(x: 0.001, y: 0.001) }
        self.hourlyTemperatureLabels.forEach { $0.alpha = 0 }
    }
}

extension WeatherWidgetViewController: WidgetProviding {
    
    var name: String {
        return "WEATHER"
    }
    
    var icon: UIImage {
        return #imageLiteral(resourceName: "weather.jpg")
    }
    
    var iconNeedsMasking: Bool {
        return true
    }
    
    func didChange(displayMode: WidgetDisplayMode) {
        
        if displayMode == .compact {
            self.containerHeightConstraint.constant = 110
            UIView.animate(withDuration: 0.35, animations: {
                self.separator.alpha = 0
                self.hourlyView.alpha = 0
                self.hourlyImageViews.forEach { $0.transform = CGAffineTransform.identity.scaledBy(x: 0.001, y: 0.001) }
                self.hourlyTemperatureLabels.forEach { $0.alpha = 0 }
            })
        } else {
            self.containerHeightConstraint.constant = 220
            UIView.animate(withDuration: 0.35, animations: {
                self.separator.alpha = 1
                self.hourlyView.alpha = 1
                self.hourlyImageViews.forEach { $0.transform = .identity }
                self.hourlyTemperatureLabels.forEach { $0.alpha = 1 }
            })
        }
    }
}
