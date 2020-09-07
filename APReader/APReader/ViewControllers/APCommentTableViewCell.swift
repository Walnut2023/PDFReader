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
    @IBOutlet weak var iconImage: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var modifiedTimeLabel: UILabel!
    
    public var commentDict: [String : String]? {
        didSet {
            self.textFiled.text = commentDict?["comment"]
            self.modifiedTimeLabel.text = Date.init().date2String()
            self.userNameLabel.text = commentDict?["user"]
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
