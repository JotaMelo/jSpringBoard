//
//  ClockIconView.swift
//  jSpringBoard
//
//  Created by Jota Melo on 08/09/17.
//  Copyright © 2017 jota. All rights reserved.
//

import UIKit

class ClockIconView: UIView {
    private var secondsLayer: CALayer
    private var minutesLayer: CALayer
    private var hoursLayer: CALayer
    private var middleBall: UIView
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var displayLink: CADisplayLink!
    override init(frame: CGRect) {
        let topCornerRadiusMaskLayer: (CGRect) -> CAShapeLayer = { bounds in
            let maskPath = UIBezierPath(roundedRect: bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 6, height: 6))
            let maskLayer = CAShapeLayer()
            maskLayer.path = maskPath.cgPath
            return maskLayer
        }
        
        let viewSize = 60 as CGFloat
        let secondsHandHeight = 28 as CGFloat
        let secondsHandOverMiddleBallHeight = 4 as CGFloat
        let middleBallSize = 2.5 as CGFloat
    
        self.secondsLayer = CALayer()
        self.secondsLayer.allowsEdgeAntialiasing = true
        self.secondsLayer.backgroundColor = #colorLiteral(red: 0.9868091941, green: 0.6393163204, blue: 0.2991196811, alpha: 1)
        self.secondsLayer.anchorPoint = CGPoint(x: 0.5, y: 1 - (secondsHandOverMiddleBallHeight / secondsHandHeight))
        self.secondsLayer.position = CGPoint(x: viewSize / 2, y: viewSize / 2)
        self.secondsLayer.bounds = CGRect(x: 0, y: 0, width: 0.5, height: secondsHandHeight)
        
        self.minutesLayer = CALayer()
        self.minutesLayer.allowsEdgeAntialiasing = true
        self.minutesLayer.backgroundColor = UIColor.black.cgColor
        self.minutesLayer.anchorPoint = CGPoint(x: 0.5, y: 1)
        self.minutesLayer.position = CGPoint(x: viewSize / 2, y: viewSize / 2)
        self.minutesLayer.bounds = CGRect(x: 0, y: 0, width: 1.5, height: secondsHandHeight - secondsHandOverMiddleBallHeight)
        self.minutesLayer.mask = topCornerRadiusMaskLayer(self.minutesLayer.bounds)
        
        self.hoursLayer = CALayer()
        self.hoursLayer.allowsEdgeAntialiasing = true
        self.hoursLayer.backgroundColor = UIColor.black.cgColor
        self.hoursLayer.anchorPoint = CGPoint(x: 0.5, y: 1)
        self.hoursLayer.position = CGPoint(x: viewSize / 2, y: viewSize / 2)
        self.hoursLayer.bounds = CGRect(x: 0, y: 0, width: 1.5, height: 17)
        self.hoursLayer.mask = topCornerRadiusMaskLayer(self.hoursLayer.bounds)
        
        self.middleBall = UIView(frame: CGRect(x: (viewSize - middleBallSize) / 2, y: (viewSize - middleBallSize) / 2, width: middleBallSize, height: middleBallSize))
        self.middleBall.backgroundColor = #colorLiteral(red: 0.9868091941, green: 0.6393163204, blue: 0.2991196811, alpha: 1)
        self.middleBall.layer.cornerRadius = middleBallSize / 2
        self.middleBall.layer.borderColor = UIColor.black.cgColor
        self.middleBall.layer.borderWidth = 0.5
        
        super.init(frame: frame)
        
        self.layer.addSublayer(self.secondsLayer)
        self.layer.addSublayer(self.minutesLayer)
        self.layer.addSublayer(self.hoursLayer)
        self.addSubview(self.middleBall)
        
        self.setCurrentTime()
        
        self.displayLink = CADisplayLink(target: self, selector: #selector(setCurrentTime))
        self.displayLink.add(to: .main, forMode: .defaultRunLoopMode)
    }
    
    @objc func setCurrentTime() {
        let degreesTo3DRotation: (CGFloat) -> CATransform3D = { degrees in
            let radians = (degrees * .pi) / 180
            return CATransform3DMakeRotation(radians, 0, 0, 1)
        }
        
        let totalDegrees = 360 as CGFloat
        let dateComponents = Calendar.current.dateComponents([.hour, .minute, .second], from: Date())
        guard let second = dateComponents.second, let minute = dateComponents.minute, let hour = dateComponents.hour else { fatalError("where are my components") }
        
        let degreesPerSecond = totalDegrees / 60
        let degreesPerMinute = totalDegrees / 60
        let degreesPerHour = totalDegrees / 12
        
        let timestamp = Date().timeIntervalSince1970
        let currentMilliseconds = CGFloat(timestamp - Double(Int(timestamp)))
        
        let updatedSecond = CGFloat(second) + currentMilliseconds
        let updatedMinute = CGFloat(minute) + (updatedSecond / 60)
        let updatedHour = CGFloat(hour) + (updatedMinute / 60)
        
        let secondDegrees = updatedSecond * degreesPerSecond
        let minuteDegrees = updatedMinute * degreesPerMinute
        let hourDegrees = updatedHour * degreesPerHour
        
        self.secondsLayer.transform = degreesTo3DRotation(secondDegrees)
        self.minutesLayer.transform = degreesTo3DRotation(minuteDegrees)
        self.hoursLayer.transform = degreesTo3DRotation(hourDegrees)
    }
}
