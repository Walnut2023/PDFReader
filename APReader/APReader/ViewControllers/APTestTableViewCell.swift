//
//  APTestTableViewCell.swift
//  APReader
//
//  Created by Tango on 2020/8/15.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit

class APTestTableViewCell: UITableViewCell {

    var filename: String? {
        didSet {
            titleLabel.text = filename
            fileImageView.image = filename?.contains(".") ?? false ? #imageLiteral(resourceName: "pdf_checked") : #imageLiteral(resourceName: "folder")
        }
    }
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var fileImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
