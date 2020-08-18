//
//  APNavigationTittleView.swift
//  APReader
//
//  Created by Tango on 2020/8/18.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit

class APNavigationTittleView: UIView {
    @IBOutlet weak var tittleLabel: UILabel!
    @IBOutlet weak var userName: UILabel!
}

extension APNavigationTittleView {
    public class func initInstanceFromXib()-> APNavigationTittleView {
        return Bundle.main.loadNibNamed("\(self)", owner: self, options: nil)?.last as! APNavigationTittleView
    }
}
