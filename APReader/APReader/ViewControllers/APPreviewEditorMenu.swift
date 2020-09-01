//
//  APPreviewEditorMenu.swift
//  APReader
//
//  Created by Tango on 2020/8/31.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit

protocol APPreviewEditorMenuDelegate {
    func didSelectCommentAction(_ sender: UIButton)
    func didSelectPenAction(_ sender: UIButton)
}

class APPreviewEditorMenu: UIView {
    
    @IBOutlet weak var commentBtn: UIButton!
    @IBOutlet weak var paintBtn: UIButton!
    
    public var delegate: APPreviewEditorMenuDelegate?
    
    @IBAction func commentAction(_ sender: UIButton) {
        delegate?.didSelectCommentAction(sender)
    }
    
    @IBAction func penAction(_ sender: UIButton) {
        delegate?.didSelectPenAction(sender)
    }
}

extension APPreviewEditorMenu {
    public class func initInstanceFromXib()-> APPreviewEditorMenu {
        let menu = Bundle.main.loadNibNamed("\(self)", owner: self, options: nil)?.last as! APPreviewEditorMenu
        return menu
    }
}
