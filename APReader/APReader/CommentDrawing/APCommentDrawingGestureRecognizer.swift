//
//  APCommentDrawingGestureRecognizer.swift
//  APReader
//
//  Created by Tango on 2020/9/4.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit

protocol APCommentDrawingGestureRecognizerDelegate: class {
    func commentGestureRecognizerTapped(_ location: CGPoint)
}

class APCommentDrawingGestureRecognizer: UITapGestureRecognizer {
    weak var drawingDelegate: APCommentDrawingGestureRecognizerDelegate?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first,
            let numberOfTouches = event?.allTouches?.count,
            numberOfTouches == 1 {
            state = .began
            
            let location = touch.location(in: self.view)
            drawingDelegate?.commentGestureRecognizerTapped(location)
        } else {
            state = .failed
        }
    }
}
