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
    
    public var changesManager = APChangesManager()
    
    var color = UIColor.red // default color is red
    var drawingTool = DrawingTool.pencil

    private var currentPage: PDFPage?

    private var startPoint: CGPoint!
    private var lastPoint: CGPoint!
    
    private var shape: ShapeType = ShapeType.circle
    private var endLineStyle: ArrowEndLineType = ArrowEndLineType.closed
    
    public func undoAction() {
        changesManager.undo {
            print("undo succeed")
            delegate?.pdfDrawerDidFinishDrawing()
        }
    }
    
    public func redoAction() {
        changesManager.redo {
            print("redo succeed")
            delegate?.pdfDrawerDidFinishDrawing()
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
    
    private func beginAnnotating(for page: PDFPage, in location: CGPoint) {
        currentPage = page
        let convertedPoint = pdfView.convert(location, to: page)
        path = UIBezierPath()
        path?.move(to: convertedPoint)
        
        lastPoint = convertedPoint
        startPoint = convertedPoint
    }
    
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
        var annotations = [PDFAnnotation]()
        pdfView?.currentSelection?.selectionsByLine().forEach({ selection in
            if pdfView != nil, pdfView!.currentPage != nil {
                annotation = PDFAnnotation(bounds: selection.bounds(for: pdfView!.currentPage!),
                                           forType: sybtype, withProperties: nil)
                annotation?.markupType = markUpType
                annotation?.color = color
                annotation?.border?.lineWidth = drawingTool.width
                pdfView?.currentPage?.addAnnotation(annotation!)
                annotations.append(annotation!)
            }
        })
        guard let page = pdfView?.currentPage else {
            return
        }
        changesManager.addTextAnnotation(annotations, forPage: page)
        delegate?.pdfDrawerDidFinishDrawing()
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
        changesManager.addInkPDFAnnotation(withPaths: path, annotation, forPage: page)
    }
    
    private func removeAnnotationAtPoint(point: CGPoint, page: PDFPage) {
        if let selectedAnnotation = page.annotationWithHitTest(at: point) {
            selectedAnnotation.page?.removeAnnotation(selectedAnnotation)
        }
    }
    
    private func forceRedraw(annotation: PDFAnnotation, onPage: PDFPage) {
        onPage.removeAnnotation(annotation)
        onPage.addAnnotation(annotation)
    }
}

