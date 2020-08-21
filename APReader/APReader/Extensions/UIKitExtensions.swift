//
//  UIKitExtensions.swift
//  APReader
//
//  Created by Tangos on 2020/7/25.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit

extension CGRect {
    var center: CGPoint {
        return CGPoint(x: self.size.width / 2.0,y: self.size.height / 2.0)
    }
}

extension CGPoint {
    func vector(to p1:CGPoint) -> CGVector {
        return CGVector(dx: p1.x - self.x, dy: p1.y - self.y)
    }
}

extension UIBezierPath {
    func moveCenter(to:CGPoint) -> Self {
        let bound = self.cgPath.boundingBox
        let center = bounds.center
        
        let zeroedTo = CGPoint(x: to.x - bound.origin.x, y: to.y - bound.origin.y)
        let vector = center.vector(to: zeroedTo)
        
        _ = offset(to: CGSize(width: vector.dx, height: vector.dy))
        return self
    }
    
    func offset(to offset:CGSize) -> Self {
        let t = CGAffineTransform(translationX: offset.width, y: offset.height)
        _ = applyCentered(transform: t)
        return self
    }
    
    func fit(into:CGRect) -> Self {
        let bounds = self.cgPath.boundingBox
        
        let sw = into.size.width / bounds.width
        let sh = into.size.height / bounds.height
        let factor = min(sw, max(sh, 0.0))
        
        return scale(x: factor, y: factor)
    }
    
    func scale(x:CGFloat, y:CGFloat) -> Self {
        let scale = CGAffineTransform(scaleX: x, y: y)
        _ = applyCentered(transform: scale)
        return self
    }
    
    
    func applyCentered(transform: @autoclosure () -> CGAffineTransform ) -> Self {
        let bound = self.cgPath.boundingBox
        let center = CGPoint(x: bound.midX, y: bound.midY)
        var xform = CGAffineTransform.identity
        
        xform = xform.concatenating(CGAffineTransform(translationX: -center.x, y: -center.y))
        xform = xform.concatenating(transform())
        xform = xform.concatenating(CGAffineTransform(translationX: center.x, y: center.y))
        apply(xform)
        
        return self
    }
}

extension UIViewController {
    func sceneDelegateWindow() -> UIWindow? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let sceneDelegate = windowScene.delegate as? SceneDelegate
            else {
                return nil
        }
        return sceneDelegate.window
    }
}

extension String {
    subscript(_ i: Int) -> Character {
        return self[index(startIndex, offsetBy: i)]
    }
    
    func subString(_ begin: Int, _ count: Int) -> String {
        let start = self.index(self.startIndex, offsetBy: max(0, begin))
        let end = self.index(self.startIndex, offsetBy: min(self.count, begin + count))
        return String(self[start..<end])
    }
    
    func subString(_ index: Int) -> String {
        let theIndex = self.index(self.endIndex, offsetBy: index - self.count)
        return String(self[theIndex..<endIndex])
    }
}
