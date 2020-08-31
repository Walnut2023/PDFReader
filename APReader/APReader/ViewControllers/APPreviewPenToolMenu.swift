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
    func didSelectColor(_ sender: UIButton)
}

class APPreviewPenToolMenu: UIView {
    @IBOutlet weak var pencilBtn: UIButton!
    @IBOutlet weak var penBtn: UIButton!
    @IBOutlet weak var markBtn: UIButton!
    @IBOutlet weak var eraserBtn: UIButton!
    @IBOutlet weak var colorBtn: UIButton!
    public var delegate: APPreviewPenToolMenuDelegate?
    
    private var penControl: APPencilControl?

    public func initPenControl() {
        penControl = APPencilControl(buttonsArray: [pencilBtn, penBtn, markBtn, eraserBtn])
        penControl?.defaultButton = pencilBtn
    }
    
    public func updateColorBtnColor(_ color: UIColor?) {
        colorBtn.backgroundColor = color
    }
    
    public func disableButtonArray() {
        penControl?.disableButtonArray()
    }
    
    public func enableButtonArray() {
        penControl?.enableButtonArray()
    }
    
    @IBAction func pencilAction(_ sender: UIButton) {
        penControl?.buttonArrayUpdated(buttonSelected: sender)
        delegate?.didSelectPenControl(penControl!.selectedValue)
    }
    
    @IBAction func colorAction(_ sender: UIButton) {
        delegate?.didSelectColor(sender)
    }
}

extension APPreviewPenToolMenu {
    public class func initInstanceFromXib()-> APPreviewPenToolMenu {
        return Bundle.main.loadNibNamed("\(self)", owner: self, options: nil)?.last as! APPreviewPenToolMenu
    }
}
