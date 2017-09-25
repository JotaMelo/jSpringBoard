//
//  CalendarIconManager.swift
//  jSpringBoard
//
//  Created by Jota Melo on 21/09/17.
//  Copyright © 2017 jota. All rights reserved.
//

import Foundation

class CalendarIconManager {
    static let shared = CalendarIconManager()
    
    private var currentDate: Date
    private var currentIcon: UIImage?
    
    var icon: UIImage {
        if !Calendar.current.isDateInToday(self.currentDate) {
            self.currentDate = Date()
            self.currentIcon = self.generateIcon(for: self.currentDate)
        }
        
        if let currentIcon = self.currentIcon {
            return currentIcon
        } else {
            self.currentIcon = self.generateIcon(for: self.currentDate)
            return self.icon
        }
    }
    
    init() {
        self.currentDate = Date()
    }
    
    private func generateIcon(for date: Date) -> UIImage {
        
        let weekday: String
        let day: String
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.dateFormat = "EEEE"
        weekday = dateFormatter.string(from: date)
        dateFormatter.dateFormat = "d"
        day = dateFormatter.string(from: date)
        
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        view.backgroundColor = .white
        
        let weekdayLabel = UILabel(frame: CGRect(x: 0, y: 5, width: 60, height: 11))
        weekdayLabel.text = weekday
        weekdayLabel.font = UIFont.systemFont(ofSize: 9)
        weekdayLabel.textColor = #colorLiteral(red: 0.9882352941, green: 0.2509803922, blue: 0.2235294118, alpha: 1)
        weekdayLabel.textAlignment = .center
        view.addSubview(weekdayLabel)
        
        let dayLabel = UILabel(frame: CGRect(x: 0, y: 12, width: 60, height: 47))
        dayLabel.text = day
        dayLabel.font = UIFont.systemFont(ofSize: 39, weight: UIFont.Weight.ultraLight)
        dayLabel.textColor = .black
        dayLabel.textAlignment = .center
        view.addSubview(dayLabel)
        
        let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
        return renderer.image { context in
            view.layer.render(in: context.cgContext)
        }
    }
}
