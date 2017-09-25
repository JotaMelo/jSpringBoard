//
//  JMView.swift
//  jSpringBoard
//
//  Created by Jota Melo on 14/06/17.
//  Copyright © 2017 jota. All rights reserved.
//

import UIKit

@IBDesignable
class JMView: UIView {
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            self.layer.cornerRadius = self.cornerRadius
            self.layer.masksToBounds = true
        }
    }
}

@IBDesignable
class JMImageview: UIImageView {
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            self.layer.cornerRadius = self.cornerRadius
            self.layer.masksToBounds = true
        }
    }
}

