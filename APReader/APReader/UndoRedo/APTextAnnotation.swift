//
//  APTextAnnotation.swift
//  APReader
//
//  Created by Tango on 2020/9/4.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit
import PDFKit

class APTextAnnotation: NSObject {
    var annotation = [PDFAnnotation]()
    var page: PDFPage

    init(_ annotation: [PDFAnnotation], forPage page: PDFPage) {
        self.annotation = annotation
        self.page = page
    }
}

// MARK: - Command Methods
extension APTextAnnotation: Command {
    func unexecute() {
        annotation.forEach({ page.removeAnnotation($0) })
    }

    func execute() {
        annotation.forEach({ page.addAnnotation($0) })
    }
}
