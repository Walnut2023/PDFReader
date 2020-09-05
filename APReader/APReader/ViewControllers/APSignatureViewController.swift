//
//  APSignatureViewController.swift
//  APReader
//
//  Created by Tango on 2020/9/5.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit
import TouchDraw

class APSignatureViewController: UIViewController {
    
    @IBOutlet weak var touchDrawView: TouchDrawView!

    var previousViewController: UIViewController?
    var signatureExport: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        touchDrawView.delegate = self
        touchDrawView.setWidth(3.0)
        
        self.navigationController?.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        touchDrawView.clearDrawing()
        signatureExport = nil
        
    }
    
    @IBAction func trashButtonPressed(_ sender: Any) {
        touchDrawView.clearDrawing()
    }
    
    @IBAction func attachSignatureButtonPressed(_ sender: Any) {
        if touchDrawView.exportStack().count > 0 {
            signatureExport = touchDrawView.exportDrawing()
            navigationController?.popViewController(animated: true)
        }
    }

}

extension APSignatureViewController: UINavigationControllerDelegate {
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if viewController == self.previousViewController {
            let vc = viewController as! APPreviewViewController
            vc.signatureImage = signatureExport
        }
    }
    
}

extension APSignatureViewController: TouchDrawViewDelegate {

}
