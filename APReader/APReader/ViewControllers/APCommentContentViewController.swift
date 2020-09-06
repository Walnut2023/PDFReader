//
//  APCommentContentViewController.swift
//  APReader
//
//  Created by Tango on 2020/9/5.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit

class APCommentContentViewController: UIViewController {

    public var actionHanlder: ((Bool, String) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func saveAction(_ sender: Any) {
        if actionHanlder != nil {
            actionHanlder!(true, "test Hello world")
        }
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        if actionHanlder != nil {
            actionHanlder!(false, "an empty string")
        }
        dismiss(animated: true, completion: nil)
    }
}
