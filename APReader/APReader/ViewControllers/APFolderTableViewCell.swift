//
//  APFolderTableViewCell.swift
//  APReader
//
//  Created by Tango on 2020/8/20.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit

class APFolderTableViewCell: UITableViewCell {
    @IBOutlet weak var folderName: UILabel!
    @IBOutlet weak var updateInfo: UILabel!
    
    var updatetime: String? {
        didSet {
            updateInfo.text = updatetime
        }
    }
    
    var foldername: String? {
        didSet {
            folderName.text = foldername
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
