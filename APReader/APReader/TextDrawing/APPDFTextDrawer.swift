//
//  APPDFTextDrawer.swift
//  APReader
//
//  Created by tango on 2020/7/26.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit
import PDFKit

class APPDFTextDrawer: NSObject {
    weak var pdfView: PDFView!
    private var textField: UITextField?
    private var currentAnnotation: PDFAnnotation?
    private var currentPage: PDFPage?
    private var currentLocation: CGPoint?
    var color = UIColor.red
    
    func endEditing() {
        textField?.resignFirstResponder()
        textField?.removeFromSuperview()
    }
}

extension APPDFTextDrawer: APTextDrawingGestureRecognizerDelegate {
    func gestureRecognizerTapped(_ location: CGPoint) {
        guard let page = pdfView.page(for: location, nearest: true) else { return }
        currentPage = page
        let convertedPoint = pdfView.convert(location, to: currentPage!)
        currentLocation = convertedPoint
        print(convertedPoint.x, convertedPoint.y)
        
        self.textField?.removeFromSuperview()
        self.textField = UITextField(frame: CGRect(x:location.x, y:location.y, width:200, height:30))
        self.textField?.borderStyle = UITextField.BorderStyle.roundedRect
        self.textField?.font = UIFont(name: "TimesNewRomanPSMT", size: 15.0)
        self.textField?.layer.cornerRadius = 12.0
        self.textField?.layer.borderColor = UIColor.clear.cgColor
        self.textField?.backgroundColor = .clear
        self.textField?.becomeFirstResponder()
        self.textField?.delegate = self
        pdfView.addSubview(self.textField!)
    }
    
    private func createTextAnnotation(bounds: CGRect, text: String) {
        guard let page = currentPage, let location = currentLocation else { return }
        let bounds = CGRect(x: location.x,
                            y: location.y - 30,
                            width: 200,
                            height: 30)
        let annotation = PDFAnnotation(bounds: bounds, forType: .freeText, withProperties: nil)
        annotation.contents = text
        annotation.font = UIFont(name: "TimesNewRomanPSMT", size: 15.0)
        annotation.fontColor = color
        annotation.color = .clear
        page.addAnnotation(annotation)
    }
        
}

extension APPDFTextDrawer: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        print("string: \(textField.text ?? "no text")")
        createTextAnnotation(bounds: textField.bounds, text: textField.text ?? "")
        UIView.animate(withDuration: 0.0, animations: {
            textField.alpha = 0.0
        }) { (true) in
            textField.removeFromSuperview()
        }
        return true;
    }
    
}
