//
//  APPreviewEditorMenu.swift
//  APReader
//
//  Created by Tango on 2020/8/31.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit

protocol APPreviewEditorMenuDelegate {
//    func didSelectCommentAction(_ sender: UIButton)
    func didSelectPenAction(_ sender: UIButton)
    func didSelectTextEditAction(_ sender: UIButton)
    func didSelectColorInEditorMenu(_ sender: UIButton)
}

class APPreviewEditorMenu: UIView {
    
//    @IBOutlet weak var commentBtn: UIButton!
    @IBOutlet weak var paintBtn: UIButton!
    @IBOutlet weak var highLightBtn: UIButton!
    @IBOutlet weak var underLineBtn: UIButton!
    @IBOutlet weak var strikeOutBtn: UIButton!
    @IBOutlet weak var colorBtn: UIButton!
    
    public var delegate: APPreviewEditorMenuDelegate?
    
    private var penControl: APPencilControl?
    public func initPenControl() {
        penControl = APPencilControl(buttonsArray: [paintBtn, highLightBtn, underLineBtn, strikeOutBtn])
    }
    
    public func enableButtonArray() {
        penControl?.enableButtonArray()
    }
    
    public func disableButtonArray() {
        penControl?.disableButtonArray()
    }
    
    public func updateColorBtnColor(_ color: UIColor?) {
        colorBtn.backgroundColor = color
    }
    
//    @IBAction func commentAction(_ sender: UIButton) {
//        penControl?.buttonArrayUpdated(buttonSelected: sender)
//        delegate?.didSelectCommentAction(sender)
//    }
    
    @IBAction func penAction(_ sender: UIButton) {
        penControl?.buttonArrayUpdated(buttonSelected: sender)
        delegate?.didSelectPenAction(sender)
    }
    
    @IBAction func didSelectTextEdit(_ sender: UIButton) {
        penControl?.buttonArrayUpdated(buttonSelected: sender)
        delegate?.didSelectTextEditAction(sender)
    }
    
    @IBAction func didSelectColorBtn(_ sender: UIButton) {
        delegate?.didSelectColorInEditorMenu(sender)
    }
}

extension APPreviewEditorMenu {
    public class func initInstanceFromXib()-> APPreviewEditorMenu {
        let menu = Bundle.main.loadNibNamed("\(self)", owner: self, options: nil)?.last as! APPreviewEditorMenu
        menu.initPenControl()
        return menu
    }
}
