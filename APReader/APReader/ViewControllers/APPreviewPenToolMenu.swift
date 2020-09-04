//
//  APPreviewPenToolMenu.swift
//  APReader
//
//  Created by Tango on 2020/9/1.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit

protocol APPreviewPenToolMenuDelegate {
    func didSelectPenControl(_ selectedValue: DrawingTool)
    func didSelectColorinPenTool(_ sender: UIButton)
    func didSelectTextInputMode(_ sender: UIButton)
}

class APPreviewPenToolMenu: UIView {
    @IBOutlet weak var lineBtn: UIButton!
    @IBOutlet weak var rectBtn: UIButton!
    @IBOutlet weak var textBtn: UIButton!
    @IBOutlet weak var pencilBtn: UIButton!
    @IBOutlet weak var penBtn: UIButton!
    @IBOutlet weak var markBtn: UIButton!
    @IBOutlet weak var eraserBtn: UIButton!
    @IBOutlet weak var colorBtn: UIButton!
    public var delegate: APPreviewPenToolMenuDelegate?
    
    private var penControl: APPencilControl?

    public func initPenControl() {
        penControl = APPencilControl(buttonsArray: [lineBtn, rectBtn, textBtn, pencilBtn, penBtn, markBtn, eraserBtn])
        penControl?.defaultButton = pencilBtn
    }
    
    public func updateColorBtnColor(_ color: UIColor?) {
        colorBtn.backgroundColor = color
    }
    
    public func enableOtherButtons() {
        penControl?.enableOtherButtons()
    }
    
    public func enableButtonArray() {
        penControl?.enableButtonArray()
    }
    
    public func disableButtonArray() {
        penControl?.disableButtonArray()
    }
    
    public func disableOtherButtons(_ sender: UIButton) {
        penControl?.disableOtherButtons(sender)
    }
    
    @IBAction func textBtnClicked(_ sender: UIButton) {
        penControl?.buttonArrayUpdated(buttonSelected: sender)
        delegate?.didSelectTextInputMode(sender)
    }
    
    @IBAction func pencilAction(_ sender: UIButton) {
        penControl?.buttonArrayUpdated(buttonSelected: sender)
        delegate?.didSelectPenControl(penControl!.selectedValue)
    }
    
    @IBAction func colorAction(_ sender: UIButton) {
        delegate?.didSelectColorinPenTool(sender)
    }
}

extension APPreviewPenToolMenu {
    public class func initInstanceFromXib() -> APPreviewPenToolMenu {
        let menu = Bundle.main.loadNibNamed("\(self)", owner: self, options: nil)?.last as! APPreviewPenToolMenu
        menu.initPenControl()
        return menu
    }
}
