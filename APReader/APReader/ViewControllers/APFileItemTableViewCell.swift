//
//  APFileItemTableViewCell.swift
//  APReader
//
//  Created by Tango on 2020/8/12.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit
import Tiercel

class APFileItemTableViewCell: UITableViewCell {

    @IBOutlet weak var fileTypeImage: UIImageView!
    @IBOutlet weak var fileName: UILabel!
    @IBOutlet weak var updateTime: UILabel!
    @IBOutlet weak var progressview: UIProgressView!
    @IBOutlet weak var downloadBtn: UIButton!
    
    var tapClosure: ((APFileItemTableViewCell) -> Void)?
    var downloadClosure: ((APFileItemTableViewCell) -> Void)?

    var filename: String? {
        didSet {
            fileName.text = filename
        }
    }

    var updatetime: String? {
        didSet {
            updateTime.text = updatetime
        }
    }
    
    @IBAction func downloadAction(_ sender: Any) {
        tapClosure?(self)
    }
    
    @IBAction func downloadBtnClicked(_ sender: Any) {
        downloadClosure?(self)
    }
    
    func updateProgress(_ task: DownloadTask) {
        progressview.observedProgress = task.progress
        
        var image = #imageLiteral(resourceName: "download")
        switch task.status {
        case .suspended:
            image = #imageLiteral(resourceName: "play")
        case .running:
            image = #imageLiteral(resourceName: "pause")
        case .succeeded:
            image = #imageLiteral(resourceName: "success")
            fileTypeImage.image = #imageLiteral(resourceName: "pdf_checked")
        case .failed:
            image = #imageLiteral(resourceName: "refresh")
        case .waiting:
            image = #imageLiteral(resourceName: "play")
        default:
            image = downloadBtn.imageView?.image ?? #imageLiteral(resourceName: "play")
            break
        }
        downloadBtn.setImage(image, for: .normal)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

    }

}
