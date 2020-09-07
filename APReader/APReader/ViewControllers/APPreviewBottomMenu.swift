//
//  APPrivewBottonMenu.swift
//  APReader
//
//  Created by Tango on 2020/8/31.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit

protocol APPreviewBottomMenuDelegate {
    func didSelectMark()
    func didSelectComment(_ sender: UIButton)
}

class APPreviewBottomMenu: UIView {

    private var penControl: APPencilControl?
    @IBOutlet weak var commentBtn: UIButton!
    @IBOutlet weak var markBtn: UIButton!
    
    public var delegate: APPreviewBottomMenuDelegate?

    public func initPenControl() {
        penControl = APPencilControl(buttonsArray: [commentBtn, markBtn])
    }
    
    public func enableButtonArray() {
        penControl?.enableButtonArray()
    }
    
    public func disableButtonArray() {
        penControl?.disableButtonArray()
    }
    
    @IBAction func markAction(_ sender: UIButton) {
        penControl?.buttonArrayUpdated(buttonSelected: sender)
        delegate?.didSelectMark()
    }
    
    @IBAction func commentAction(_ sender: UIButton) {
        penControl?.buttonArrayUpdated(buttonSelected: sender)
        delegate?.didSelectComment(sender)
    }
    
//    @IBAction func signatureAction(_ sender: Any) {
//        delegate?.didSelectSignature()
//    }
}

extension APPreviewBottomMenu {
    public class func initInstanceFromXib()-> APPreviewBottomMenu {
        let menu = Bundle.main.loadNibNamed("\(self)", owner: self, options: nil)?.last as! APPreviewBottomMenu
        menu.initPenControl()
        return menu
    }
}
