//
//  APOutlineTableViewCell.swift
//  APReader
//
//  Created by tango on 2020/7/29.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit

class APOutlineTableViewCell: UITableViewCell {

    @IBOutlet weak var openButton: UIButton!
    @IBOutlet weak var outlineTextLabel: UILabel!
    @IBOutlet weak var pageNumberLabel: UILabel!
    @IBOutlet weak var leftOffsetConstraint: NSLayoutConstraint!

    override func layoutSubviews() {
        super.layoutSubviews()
        if self.indentationLevel == 0 {
            self.outlineTextLabel.font = UIFont.systemFont(ofSize: 15.0)
        } else {
            self.outlineTextLabel.font = UIFont.systemFont(ofSize: 14.0)
        }
        self.leftOffsetConstraint.constant = CGFloat(self.indentationLevel) * self.indentationWidth
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
