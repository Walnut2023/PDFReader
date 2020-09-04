//
//  APPDFCommentDrawer.swift
//  APReader
//
//  Created by Tango on 2020/9/4.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit
import PDFKit

class APPDFCommentDrawer: NSObject {
    weak var pdfView: PDFView!
    private var currentAnnotation: PDFAnnotation?
    private var currentPage: PDFPage?
    private var currentLocation: CGPoint?
    var color = UIColor.red
}

enum FieldNames: String {
  case name
  case colaPrice
  case rrPrice
  case clearButton
}

extension APPDFCommentDrawer: APCommentDrawingGestureRecognizerDelegate {
    func commentGestureRecognizerTapped(_ location: CGPoint) {
        print("touched in point: \(location)")
        guard let page = pdfView.page(for: location, nearest: true) else { return }
        currentPage = page
        let convertedPoint = pdfView.convert(location, to: currentPage!)
        currentLocation = convertedPoint
        let clearButtonBounds = CGRect(x: convertedPoint.x, y: convertedPoint.y, width: 106, height: 32)
        let clearButton = PDFAnnotation(bounds: clearButtonBounds, forType: .widget, withProperties: nil)
        clearButton.widgetFieldType = .button
        clearButton.widgetControlType = .pushButtonControl
        clearButton.caption = "Clear"
        clearButton.fieldName = FieldNames.clearButton.rawValue
        currentPage?.addAnnotation(clearButton)
        
        let resetFormAction = PDFActionResetForm()
        resetFormAction.fields = [FieldNames.colaPrice.rawValue, FieldNames.rrPrice.rawValue]
        resetFormAction.fieldsIncludedAreCleared = false
        clearButton.action = resetFormAction
    }
}
