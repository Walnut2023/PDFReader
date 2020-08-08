//
//  APPencilControl.swift
//  APReader
//
//  Created by tango on 2020/8/8.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit

class APPencilControl: NSObject {
    var buttonsArray: [UIButton]!
    var selectedButton: UIButton?
    var selectedValue: DrawingTool {
        get {
            return (selectedButton?.tag).map { DrawingTool(rawValue: $0) }!!
        }
    }
    var defaultButton: UIButton = UIButton() {
        didSet {
            buttonArrayUpdated(buttonSelected: self.defaultButton)
        }
    }
    
    init(buttonsArray: [UIButton]) {
        self.buttonsArray = buttonsArray
    }
    
    func buttonArrayUpdated(buttonSelected: UIButton) {
        for button in buttonsArray {
            if button == buttonSelected {
                selectedButton = button
                button.isSelected = true
            } else {
                button.isSelected = false
            }
        }
    }
    
    public func enableButtonArray() {
        for button in buttonsArray {
            button.isEnabled = true
        }
        selectedButton?.isSelected = true
    }
    
    public func disableButtonArray() {
        for button in buttonsArray {
            button.isEnabled = false
        }
        selectedButton?.isSelected = false
    }
}
