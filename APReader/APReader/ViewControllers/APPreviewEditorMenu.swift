//
//  APPreviewEditorMenu.swift
//  APReader
//
//  Created by Tango on 2020/8/31.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit

protocol APPreviewEditorMenuDelegate {
    func didSelectCommentAction()
    func didSelectTextInputAction()
    func didSelectPenAction()
    func didSelectRactAction()
    func didSelectLineAction()

}

class APPreviewEditorMenu: UIView {
    
    public var delegate: APPreviewEditorMenuDelegate?
    
    @IBAction func commentAction(_ sender: Any) {
        delegate?.didSelectCommentAction()
    }
    
    @IBAction func textInputAction(_ sender: Any) {
        delegate?.didSelectTextInputAction()
    }
    
    @IBAction func penAction(_ sender: Any) {
        delegate?.didSelectPenAction()
    }
    
    @IBAction func ractAction(_ sender: Any) {
        delegate?.didSelectRactAction()
    }
    
    @IBAction func lineAction(_ sender: Any) {
        delegate?.didSelectLineAction()
    }
}

extension APPreviewEditorMenu {
    public class func initInstanceFromXib()-> APPreviewEditorMenu {
        return Bundle.main.loadNibNamed("\(self)", owner: self, options: nil)?.last as! APPreviewEditorMenu
    }
}
