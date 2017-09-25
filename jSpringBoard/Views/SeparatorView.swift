//
//  SeparatorView.swift
//  jSpringBoard
//
//  Created by Jota Melo on 31/08/17.
//  Copyright © 2017 jota. All rights reserved.
//

import UIKit

@IBDesignable
class SeparatorView: UIView {
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: 1 / UIScreen.main.scale)
    }
}
