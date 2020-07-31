//
//  APNonSelectablePDFView.swift
//  APReader
//
//  Created by tango on 2020/7/26.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit
import PDFKit

class APNonSelectablePDFView: PDFView {
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return false
    }
    
    override func addGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer is UILongPressGestureRecognizer {
            gestureRecognizer.isEnabled = false
        }
        super.addGestureRecognizer(gestureRecognizer)
    }
}
