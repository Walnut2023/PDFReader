//
//  APBookmarkTableViewCell.swift
//  APReader
//
//  Created by tango on 2020/7/29.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit

class APBookmarkTableViewCell: UITableViewCell {

    
    @IBOutlet weak var bookmarkTextfield: UITextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
