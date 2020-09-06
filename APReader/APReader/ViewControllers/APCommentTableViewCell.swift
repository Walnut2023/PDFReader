//
//  APCommentTableViewCell.swift
//  APReader
//
//  Created by Tango on 2020/9/7.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit

class APCommentTableViewCell: UITableViewCell {

    @IBOutlet weak var textFiled: UITextField!
    
    public var commentString: String? {
        didSet {
            self.textFiled.text = commentString
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
