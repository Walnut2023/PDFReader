//
//  APPDFTextDrawer.swift
//  APReader
//
//  Created by tango on 2020/7/26.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit
import PDFKit

protocol APPDFTextDrawerDelegate: NSObject {
    func pdfTextDrawerDidFinishDrawing()
}

class APPDFTextDrawer: NSObject {
    weak var pdfView: PDFView!
    weak var delegate: APPDFTextDrawerDelegate?
    private var textField: UITextField?
    private var currentAnnotation: PDFAnnotation?
    private var currentPage: PDFPage?
    private var currentLocation: CGPoint?
    
    public var changesManager = APChangesManager()
    var color = UIColor.red
    
    public func undoAction() {
        changesManager.undo {
            print("undo succeed")
            delegate?.pdfTextDrawerDidFinishDrawing()
        }
    }
    
    public func redoAction() {
        changesManager.redo {
            print("redo succeed")
            delegate?.pdfTextDrawerDidFinishDrawing()
        }
    }
}
