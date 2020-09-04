//
//  APPDFDrawer.swift
//  APReader
//
//  Created by Tangos on 2020/7/25.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import Foundation
import PDFKit

enum ArrowEndLineType: Int {
    case open, closed

    var description: String {
        switch self {
        case .open:
            return "open"
        case .closed:
            return "closed"
        }
    }
}

enum ShapeType: Int {
    case circle, roundedRectangle, regularRectangle

    var description: String {
        switch self {
        case .circle:
            return "circle"
        case .roundedRectangle:
            return "roundedRectangle"
        case .regularRectangle:
            return "regularRectangle"
        }
    }
}

enum DrawingTool: Int {
    case eraser = 0
    case pencil = 1
    case pen = 2
    case highlighter = 3
    case arrow = 4
    case shape = 5
    
    var width: CGFloat {
        switch self {
        case .pencil:
            return 3
        case .pen:
            return 7
        case .highlighter:
            return 10
        default:
            return 0
        }
    }
    
    var alpha: CGFloat {
        switch self {
        case .highlighter:
            return 0.5
        default:
            return 1
        }
    }
}

class APAnnotationItem {
    var annotation: PDFAnnotation
    var path: UIBezierPath
    init(_ anno: PDFAnnotation, _ newpath: UIBezierPath) {
        annotation = anno
        path = newpath
    }
}

protocol APPDFDrawerDelegate: NSObject {
    func pdfDrawerDidFinishDrawing()
}

class APPDFDrawer {
    weak var pdfView: PDFView!
    weak var delegate: APPDFDrawerDelegate?
    private var path: UIBezierPath?
    private var currentAnnotation : APDrawingAnnotation?
    private var annotation : PDFAnnotation?
    public var undoAnnotations: [APAnnotationItem] {
        didSet {
            undoEnable = undoAnnotations.count > 0
            delegate?.pdfDrawerDidFinishDrawing()
        }
    }
    private var redoAnnotations: [APAnnotationItem] {
        didSet {
            redoEnable = redoAnnotations.count > 0
            delegate?.pdfDrawerDidFinishDrawing()
        }
    }
    
    init() {
        undoAnnotations = [APAnnotationItem]()
        redoAnnotations = [APAnnotationItem]()
    }
    
    private var currentPage: PDFPage?
    
    var undoEnable: Bool = false
    var redoEnable: Bool = false
    
    var color = UIColor.red // default color is red
    var drawingTool = DrawingTool.pencil
    
    private var startPoint: CGPoint!
    private var lastPoint: CGPoint!
    
    private var shape: ShapeType = ShapeType.circle
    private var endLineStyle: ArrowEndLineType = ArrowEndLineType.closed
    
//    private var annotation: PDFAnnotation?

    public func undoAction() {
        if undoAnnotations.count < 0 {
            return
        }
        let last = undoAnnotations.last
        currentPage?.removeAnnotation(last!.annotation)
        redoAnnotations.insert(last!, at: 0)
        undoAnnotations.removeLast()
    }
    
    public func redoAction() {
        if redoAnnotations.count < 0 {
            return
        }
        guard let currentPage = currentPage else { return }
        if redoAnnotations.count > 0 {
            let first = redoAnnotations.first
            createFinalAnnotation(path: first!.path, page: currentPage)
            redoAnnotations.remove(at: 0)
        }
        print("redoAnnotations count: \(redoAnnotations.count)")
    }
    
    public func clearAllAnnotations() {
        if undoAnnotations.count > 0 {
            for annotation in undoAnnotations {
                currentPage?.removeAnnotation(annotation.annotation)
            }
            undoAnnotations.removeAll()
        }
    }
}

extension APPDFDrawer: APDrawingGestureRecognizerDelegate {
    func gestureRecognizerBegan(_ location: CGPoint) {
        guard let page = pdfView.page(for: location, nearest: true) else { return }
        beginAnnotating(for: page, in: location)
    }
    
    func gestureRecognizerMoved(_ location: CGPoint) {
        guard let currentPage = currentPage else { return }
        let nearestPage = pdfView.page(for: location, nearest: true) ?? currentPage

        // 如果需要跨页面, 则重新开始绘制
        if currentPage != nearestPage {
            let convertedPoint = pdfView.convert(location, to: nearestPage)
            endAnnotating(atPoint: convertedPoint, for: currentPage)
            self.currentPage = nearestPage
            beginAnnotating(for: nearestPage, in: location)
        }
        
        let convertedPoint = pdfView.convert(location, to: nearestPage)

        // Erasing
        if drawingTool == .eraser {
            removeAnnotationAtPoint(point: convertedPoint, page: nearestPage)
            return
        }
        
        path?.addLine(to: convertedPoint)
        path?.move(to: convertedPoint)
        drawAnnotation(onPage: nearestPage)
    }
    
    func gestureRecognizerEnded(_ location: CGPoint) {
        guard let currentPage = currentPage else { return }
        let nearestPage = pdfView.page(for: location, nearest: true) ?? currentPage
        let convertedPoint = pdfView.convert(location, to: nearestPage)
        
        // Erasing
        if drawingTool == .eraser {
            removeAnnotationAtPoint(point: convertedPoint, page: nearestPage)
            return
        }
        
        // Drawing
        guard currentAnnotation != nil else { return }
        
        path?.addLine(to: convertedPoint)
        path?.move(to: convertedPoint)
        
        // Final annotation
        endAnnotating(atPoint: convertedPoint, for: nearestPage)
    }
    
    // 开始注释
    // 获取对应的点, 然后将 path 移动到对应的点
    private func beginAnnotating(for page: PDFPage, in location: CGPoint) {
        currentPage = page
        let convertedPoint = pdfView.convert(location, to: page)
        path = UIBezierPath()
        path?.move(to: convertedPoint)
        
        lastPoint = convertedPoint
        startPoint = convertedPoint
    }
    
    // 结束绘制
    private func endAnnotating(atPoint point: CGPoint, for page: PDFPage) {
        page.removeAnnotation(currentAnnotation!)
        
        switch drawingTool {
        case .arrow:
            // arrow
            let angle = APDrawUtilities.angleBetweenPoint(point, andOtherPoint: startPoint)
            path = APArrowBezierPath.endLine(atPoint: point, fromType: endLineStyle)
            APDrawUtilities.rotateBezierPath(path!, aroundPoint: point, withAngle: angle)
    
            path?.move(to: startPoint)
            path?.addLine(to: CGPoint(x: point.x, y: point.y))
    
        case .shape:
            // shape
            let shapeRect = APDrawUtilities.rectBetween(point, startPoint)
    
            if shape == ShapeType.regularRectangle {
                path = UIBezierPath(rect: shapeRect)
            } else if shape == ShapeType.roundedRectangle {
                path = UIBezierPath(roundedRect: shapeRect, cornerRadius: 2.0)
            } else if shape == ShapeType.circle {
                path = UIBezierPath(ovalIn: shapeRect)
            }
        default:
            print("default")
        }

        path?.lineWidth = drawingTool.width

        createFinalAnnotation(path: path!, page: page)
        currentAnnotation = nil
        // notify
        delegate?.pdfDrawerDidFinishDrawing()
    }
    
    public func addAnnotation(_ sybtype: PDFAnnotationSubtype, markUpType: PDFMarkupType) {
//        var annotations = [PDFAnnotation]()
        pdfView?.currentSelection?.selectionsByLine().forEach({ selection in
            if pdfView != nil, pdfView!.currentPage != nil {
                annotation = PDFAnnotation(bounds: selection.bounds(for: pdfView!.currentPage!),
                                           forType: sybtype, withProperties: nil)
                annotation?.markupType = markUpType
                annotation?.color = color
                annotation?.border?.lineWidth = drawingTool.width
                pdfView?.currentPage?.addAnnotation(annotation!)
//                annotations.append(annotation!)
            }
        })
        
//        guard let page = pdfView?.currentPage else {
//             return
//        }
        // add to
    }
    
    private func createAnnotation(path: UIBezierPath, page: PDFPage) -> APDrawingAnnotation {
        let border = PDFBorder()
        border.lineWidth = drawingTool.width
        
        let annotation = APDrawingAnnotation(bounds: page.bounds(for: pdfView.displayBox), forType: .ink, withProperties: nil)
        annotation.color = color.withAlphaComponent(drawingTool.alpha)
        annotation.border = border
        return annotation
    }
    
    private func drawAnnotation(onPage: PDFPage) {
        guard let path = path else { return }
        
        if currentAnnotation == nil {
            currentAnnotation = createAnnotation(path: path, page: onPage)
        }
        
        currentAnnotation?.path = path
        forceRedraw(annotation: currentAnnotation!, onPage: onPage)
    }
    
    // 根据不同选择绘制最终的 annotation
    // 这里或者前一步需要进行对应的类型判断, 看需要何种类型
    private func createFinalAnnotation(path: UIBezierPath, page: PDFPage) {
        
        if drawingTool == .eraser {
            return
        }
        
        let border = PDFBorder()
        border.lineWidth = drawingTool.width
        
        let bounds = CGRect(x: path.bounds.origin.x - 5,
                            y: path.bounds.origin.y - 5,
                            width: path.bounds.size.width + 10,
                            height: path.bounds.size.height + 10)
        let signingPathCentered = UIBezierPath()
        signingPathCentered.cgPath = path.cgPath
        _ = signingPathCentered.moveCenter(to: bounds.center)
        
        let annotation = PDFAnnotation(bounds: bounds, forType: .ink, withProperties: nil)
        annotation.color = color.withAlphaComponent(drawingTool.alpha)
        annotation.border = border
        annotation.add(signingPathCentered)
        page.addAnnotation(annotation)
        
        // store in annotations
        undoAnnotations.append(APAnnotationItem(annotation, path))
    }
    
    private func removeAnnotationAtPoint(point: CGPoint, page: PDFPage) {
        if let selectedAnnotation = page.annotationWithHitTest(at: point) {
            redoAnnotations.insert(APAnnotationItem(selectedAnnotation, path!), at: 0)
            selectedAnnotation.page?.removeAnnotation(selectedAnnotation)
        }
    }
    
    private func forceRedraw(annotation: PDFAnnotation, onPage: PDFPage) {
        onPage.removeAnnotation(annotation)
        onPage.addAnnotation(annotation)
    }
}

