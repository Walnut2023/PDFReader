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
    
    //        guard let document = pdfView.document else { return }
    //        let lastPage = document.page(at: document.pageCount - 1)
    //        let annotation = PDFAnnotation(bounds: CGRect(x: 100, y: 100, width: 100, height: 20), forType: .freeText, withProperties: nil)
    //        annotation.contents = "Hello, world!"
    //        annotation.font = UIFont.systemFont(ofSize: 15.0)
    //        annotation.fontColor = .blue
    //        annotation.color = .clear
    //        lastPage?.addAnnotation(annotation)
    
    weak var pdfView: PDFView!
    private var textField: UITextField?
    private var currentAnnotation: PDFAnnotation?
    private var currentPage: PDFPage?
    private var currentLocation: CGPoint?
    var color = UIColor.red
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
        //设置边框样式为圆角矩形
        self.textField?.borderStyle = UITextField.BorderStyle.roundedRect
        self.textField?.font = UIFont(name: "TimesNewRomanPSMT", size: 15.0)
        //修改圆角半径的话需要将masksToBounds设为true
        self.textField?.layer.cornerRadius = 12.0  //圆角半径
        self.textField?.layer.borderColor = UIColor.clear.cgColor //边框颜色
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
        annotation.fontColor = .black
        annotation.color = .clear
        page.addAnnotation(annotation)
    }
        
}

extension APPDFTextDrawer: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        //收起键盘
        textField.resignFirstResponder()
        //打印出文本框中的值
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
