//
//  APFileItemTableViewCell.swift
//  APReader
//
//  Created by Tango on 2020/8/12.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit
import Tiercel
import MSGraphClientModels

class APFileItemTableViewCell: UITableViewCell {

    @IBOutlet weak var fileTypeImage: UIImageView!
    @IBOutlet weak var fileName: UILabel!
    @IBOutlet weak var updateTime: UILabel!
    @IBOutlet weak var progressview: UIProgressView!
    @IBOutlet weak var downloadBtn: UIButton!
    @IBOutlet weak var editBtn: UIButton!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var downloadedLabel: UILabel!
    
    var driveItem: MSGraphDriveItem? {
        didSet {
            if driveItem?.folder != nil {
                fileTypeImage.image = #imageLiteral(resourceName: "folder")
            }
        }
    }
    
    var tapClosure: ((APFileItemTableViewCell) -> Void)?
    var downloadClosure: ((APFileItemTableViewCell) -> Void)?

    var fileURL: URL?
    var filename: String? {
        didSet {
            fileName.text = filename
            fileURL = {
                let fileManager = FileManager.default
                let docsurl = try! fileManager.url(
                    for: .cachesDirectory, in: .userDomainMask,
                    appropriateFor: nil, create: true)
                return docsurl.appendingPathComponent("APReader.OneDrive/File/\(filename ?? "")")
            }()
            if checkFileExists(atPath: filename) {
                downloadBtn.isHidden = true
                fileTypeImage.image = #imageLiteral(resourceName: "pdf_checked")
                progressview.isHidden = true
                editBtn.isHidden = false
                downloadedLabel.isHidden = false
            }
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
            if !loadingIndicator.isHidden {
                loadingIndicator.isHidden = true
            }
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
        if checkFileExists(atPath: filename) {
            self.downloadBtn.isHidden = true
            fileTypeImage.image = #imageLiteral(resourceName: "pdf_checked")
            progressview.isHidden = true
            editBtn.isHidden = false
            downloadedLabel.isHidden = false
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        loadingIndicator.isHidden = true
        editBtn.isHidden = true
        downloadedLabel.isHidden = true
    }

}
