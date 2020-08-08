//
//  PDFKitExtensions.swift
//  APReader
//
//  Created by Tangos on 2020/7/25.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit
import PDFKit
import Foundation

extension PDFAnnotation {
    func contains(point: CGPoint) -> Bool {
//        var hitPath: CGPath?
//        if let path = paths?.first {
//            hitPath = path.cgPath.copy(strokingWithWidth: 10.0, lineCap: .round, lineJoin: .round, miterLimit: 0)
//        }
//        return hitPath?.contains(point) ?? false
        return bounds.contains(point)
    }
}

extension PDFPage {
    func annotationWithHitTest(at: CGPoint) -> PDFAnnotation? {
        for annotation in annotations {
            if annotation.contains(point: at) {
                return annotation
            }
        }
        return nil
    }
}
