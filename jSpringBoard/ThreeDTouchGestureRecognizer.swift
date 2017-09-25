//
//  ThreeDTouchGestureRecognizer.swift
//  jSpringBoard
//
//  Created by Jota Melo on 23/07/17.
//  Copyright © 2017 jota. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass

class ThreeDTouchGestureRecognizer: UIGestureRecognizer {
    
    var pressProgress: CGFloat = 0
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        self.touchHandler(touches: touches)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        self.touchHandler(touches: touches)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        self.touchHandler(touches: touches)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        self.state = .failed
    }
    
    func touchHandler(touches: Set<UITouch>) {
        guard let touch = touches.first, touches.count == 1 else {
            self.state = .failed
            return
        }
        
        self.pressProgress = touch.force / touch.maximumPossibleForce
        if self.pressProgress > 0.2 {
            if touch.phase == .ended {
                self.state = .ended
            } else if self.state == .began || self.state == .changed {
                self.state = .changed
            } else {
                self.state = .began
            }
        } else if touch.phase == .ended {
            self.state = .failed
        }
    }
}
