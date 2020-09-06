//
//  APPDFCommentDrawer.swift
//  APReader
//
//  Created by Tango on 2020/9/4.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit
import PDFKit

protocol APPDFCommentDrawerDelegate: NSObject {
    func pdfCommentDrawerDidFinishDrawing()
}

class APPDFCommentDrawer: NSObject {
    weak var pdfView: PDFView!
    weak var delegate: APPDFCommentDrawerDelegate?
    private var currentAnnotation: PDFAnnotation?
    private var currentPage: PDFPage?
    private var currentLocation: CGPoint?
    var color = UIColor.red
    
    public var changesManager = APChangesManager()

    public func undoAction() {
        changesManager.undo {
            print("undo succeed")
            delegate?.pdfCommentDrawerDidFinishDrawing()
        }
    }
    
    public func redoAction() {
        changesManager.redo {
            print("redo succeed")
            delegate?.pdfCommentDrawerDidFinishDrawing()
        }
    }
}
