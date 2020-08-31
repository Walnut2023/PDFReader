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
    func didSelectInsertPage()
    func didSelectSignaure()
}

class APPreviewBottomMenu: UIView {

    public var delegate: APPreviewBottomMenuDelegate?

    @IBAction func commentAction(_ sender: Any) {
        delegate?.didSelectComment()
    }
    
    @IBAction func insetAction(_ sender: Any) {
        delegate?.didSelectInsertPage()
    }
    
    @IBAction func signatureAction(_ sender: Any) {
        delegate?.didSelectSignaure()
    }
}

extension APPreviewBottomMenu {
    public class func initInstanceFromXib()-> APPreviewBottomMenu {
        return Bundle.main.loadNibNamed("\(self)", owner: self, options: nil)?.last as! APPreviewBottomMenu
    }
}
