//
//  APInkAnnotation.swift
//  APReader
//
//  Created by Tango on 2020/9/4.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit
import PDFKit

class APInkAnnotation: NSObject {

    let annotation: PDFAnnotation
    let path: UIBezierPath?
    let page: PDFPage

    init(_ annotation: PDFAnnotation, path: UIBezierPath?, forPDFPage page: PDFPage) {
        self.page = page
        self.path = path
        self.annotation = annotation
    }
}

// MARK: - Command Methods
extension APInkAnnotation: Command {
    func execute() {
        page.addAnnotation(annotation)
    }

    func unexecute() {
        page.removeAnnotation(annotation)
    }
}
