//
//  APSearchTableViewCell.swift
//  APReader
//
//  Created by tango on 2020/7/30.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit

class APSearchTableViewCell: UITableViewCell {

    @IBOutlet weak var outlineLabel: UILabel!
    @IBOutlet weak var pageNumberLabel: UILabel!
    @IBOutlet weak var searchResultTextLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
