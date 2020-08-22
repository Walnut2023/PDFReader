//
//  APNavigationController.swift
//  APReader
//
//  Created by Tango on 2020/8/22.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit

class APNavigationController: UINavigationController {
    
    var popDelegate: UIGestureRecognizerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        popDelegate = interactivePopGestureRecognizer?.delegate
        delegate = self
    }
    
}

extension APNavigationController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        if viewController == self.viewControllers[0] {
            self.interactivePopGestureRecognizer!.delegate = popDelegate
        } else {
            self.interactivePopGestureRecognizer!.delegate = nil
        }
    }
}
