//
//  APArrowBezierPath.swift
//  APReader
//
//  Created by Tango on 2020/9/3.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit

class APArrowBezierPath: NSObject {

    static func endLine(atPoint point: CGPoint, fromType type: ArrowEndLineType) -> UIBezierPath {
        let capSize = CGFloat(20)
        let rect = CGRect(x: point.x - capSize / 2, y: point.y, width: capSize, height: capSize)

        let points = APArrowBezierPath.pointsForTriangleInRect(rect)
        let path = UIBezierPath(byConnectingThePoints: points)
        if type == .closed { path.close() }

        return path
    }

     private static func tipForTriangleInRect(_ rect: CGRect) -> CGPoint {
        return CGPoint(x: rect.minX + (rect.maxX - rect.minX) / 2, y: rect.minY)
    }

     private static func pointsForTriangleInRect(_ rect: CGRect) -> [CGPoint] {
        return [CGPoint(x: rect.minX, y: rect.maxY),
                APArrowBezierPath.tipForTriangleInRect(rect),
                CGPoint(x: rect.maxX, y: rect.maxY)]
    }
}
