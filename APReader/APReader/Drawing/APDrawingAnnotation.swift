//
//  APDrawingAnnotation.swift
//  APReader
//
//  Created by Tangos on 2020/7/25.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import Foundation
import PDFKit

class APDrawingAnnotation: PDFAnnotation {
    public var path = UIBezierPath()
    
    override func draw(with box: PDFDisplayBox, in context: CGContext) {
        let pathCopy = path.copy() as? UIBezierPath
        UIGraphicsPushContext(context)
        context.saveGState()
        
        context.setShouldAntialias(true)
        
        color.set()
        pathCopy?.lineJoinStyle = .round
        pathCopy?.lineCapStyle = .round
        pathCopy?.lineWidth = border?.lineWidth ?? 1.0
        pathCopy?.stroke()
        
        context.restoreGState()
        UIGraphicsPopContext()
    }
}
