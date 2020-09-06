//
//  APCommentImageStampAnnotation.swift
//  APReader
//
//  Created by Tango on 2020/9/6.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit
import PDFKit

class APCommentImageStampAnnotation: PDFAnnotation {
    
    var image: UIImage!

    init(forBounds bounds: CGRect, withProperties properties: [AnyHashable : Any]?) {
        super.init(bounds: bounds, forType: PDFAnnotationSubtype.stamp, withProperties: properties)
        self.image = #imageLiteral(resourceName: "comment")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(with box: PDFDisplayBox, in context: CGContext) {
        guard let cgImage = self.image.cgImage else { return }
        context.draw(cgImage, in: self.bounds)
    }
}
