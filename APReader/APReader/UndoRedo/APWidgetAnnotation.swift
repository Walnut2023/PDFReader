//
//  APWidgetAnnotation.swift
//  APReader
//
//  Created by Tango on 2020/9/4.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit
import PDFKit

class APWidgetAnnotation: NSObject {
    let annotation: PDFAnnotation
    var page: PDFPage

    init(_ annotation: PDFAnnotation, forPage page: PDFPage) {
        self.annotation = annotation
        self.page = page
    }
}

// MARK: - Command Methods
extension APWidgetAnnotation: Command {
    func execute() {
        page.addAnnotation(annotation)
    }

    func unexecute() {
        page.removeAnnotation(annotation)
    }
}
