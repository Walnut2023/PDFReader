//
//  APPrivewBottonMenu.swift
//  APReader
//
//  Created by Tango on 2020/8/31.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit

protocol APPreviewBottomMenuDelegate {
    func didSelectComment()
    func didSelectSignature()
}

class APPreviewBottomMenu: UIView {

    public var delegate: APPreviewBottomMenuDelegate?

    @IBAction func commentAction(_ sender: Any) {
        delegate?.didSelectComment()
    }
    
    @IBAction func signatureAction(_ sender: Any) {
        delegate?.didSelectSignature()
    }
}

extension APPreviewBottomMenu {
    public class func initInstanceFromXib()-> APPreviewBottomMenu {
        return Bundle.main.loadNibNamed("\(self)", owner: self, options: nil)?.last as! APPreviewBottomMenu
    }
}
