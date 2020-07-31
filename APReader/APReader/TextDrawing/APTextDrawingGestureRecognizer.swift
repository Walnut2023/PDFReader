//
//  APTextDrawingGestureRecognizer.swift
//  APReader
//
//  Created by tango on 2020/7/26.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit

protocol APTextDrawingGestureRecognizerDelegate: class {
    func gestureRecognizerTapped(_ location: CGPoint)
}

class APTextDrawingGestureRecognizer: UITapGestureRecognizer {
    weak var drawingDelegate: APTextDrawingGestureRecognizerDelegate?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first,
            let numberOfTouches = event?.allTouches?.count,
            numberOfTouches == 1 {
            state = .began
            
            let location = touch.location(in: self.view)
            drawingDelegate?.gestureRecognizerTapped(location)
        } else {
            state = .failed
        }
    }
    
}
