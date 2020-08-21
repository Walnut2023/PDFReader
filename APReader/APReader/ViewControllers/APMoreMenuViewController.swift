//
//  APMoreMenuTableViewController.swift
//  APReader
//
//  Created by Tango on 2020/8/20.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit
import SVProgressHUD
import MSGraphClientModels

protocol APMoreMenuViewControllerDelegate: AnyObject {
    func moreMenuDidSelectRow(index: Int, dict: [String: String])
}

class APMoreMenuViewController: UITableViewController {
    
    private var items: [[String: String]]?
    private let tableCellIdentifier = "APMoreMenuCell"
    
    public weak var delegate: APMoreMenuViewControllerDelegate?
    public var driveItem: MSGraphDriveItem?
    
    private var uploadFileUrl: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupData()
        setupDataSource()
    }
    
    func setupUI() {
        tableView.tableFooterView = UIView()
    }
    
    func setupData() {
        if driveItem == nil {
            driveItem = MSGraphDriveItem()
        }
    }
    
    func setupDataSource() {
        items = [["storage": "Upload PDF Files"], ["addfolders": "Add Folder"]]
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: tableCellIdentifier, for: indexPath) as! APMoreMenuCell
        let dict = items?[indexPath.row]
        cell.itemImageView.image = UIImage.init(named: dict?.keys.first ?? "")
        cell.tittleLabel.text = dict?.values.first ?? ""
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            selectUploadFileFromiCouldDrive()
        case 1:
            showCreateFolderOption()
        default:
            print("do nothing")
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
}

extension APMoreMenuViewController {
    private func selectUploadFileFromiCouldDrive()  {
        let documentTypes = ["com.adobe.pdf"]
        let document = UIDocumentPickerViewController.init(documentTypes: documentTypes, in: .open)
        document.delegate = self
        document.modalPresentationStyle = .automatic
        self.present(document, animated:true, completion:nil)
    }
}

extension APMoreMenuViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        guard controller.documentPickerMode == .open, url.startAccessingSecurityScopedResource() else { return }
        let fileName = url.lastPathComponent.removingPercentEncoding
        print("fileName: \(fileName!)")
        if APCloudManager.iCouldEnable() {
            APCloudManager.downloadFile(forDocumentUrl: url) { (fileData) in
                
                let data = fileData as NSData
                let fileManager = FileManager.default
                let docsurl = try! fileManager.url(
                    for: .cachesDirectory, in: .userDomainMask,
                    appropriateFor: nil, create: true)
                let fileUrl: URL!
                if self.driveItem?.folder != nil {
                    fileUrl = docsurl.appendingPathComponent("APReader.OneDrive/File/\(self.driveItem?.folderItemShortRelativePath() ?? "")/\(fileName ?? "")")
                } else {
                    fileUrl = docsurl.appendingPathComponent("APReader.OneDrive/File/\(fileName ?? "")")
                }
                self.uploadFileUrl = fileUrl
                data.write(to: fileUrl, atomically: true)
                SVProgressHUD.showInfo(withStatus: "Uploading to OneDrive")
                DispatchQueue.global().async {
                    self.uploadFile(name: fileName ?? "")
                }
            }
        } else {
            // Show the error
            let alert = UIAlertController(title: "Error",
                                          message: "iCloud Documents unavailable",
                                          preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                self.dismiss(animated: true, completion: nil)
            }))
            self.present(alert, animated: true)
        }
    }
    
    func uploadFile(name: String, sharing: Bool = true) {
        
        APOneDriveManager.instance.createUploadSession(filePath: driveItem?.folderItemShortRelativePath(), fileName: name, completion: { (result: OneDriveManagerResult, uploadUrl, expirationDateTime, nextExpectedRanges) -> Void in
            switch(result) {
            case .Success:
                APOneDriveManager.instance.uploadPDFBytes(driveItem: self.driveItem, uploadFilePath: self.uploadFileUrl, uploadUrl: uploadUrl!, completion: { (result: OneDriveManagerResult, webUrl, fileId) -> Void in
                    switch(result) {
                    case .Success:
                        print ("Web Url of file \(String(describing: webUrl))")
                        print ("FileId of file \(String(describing: fileId))")
                        DispatchQueue.main.async {
                            SVProgressHUD.showSuccess(withStatus: "Upload succeed")
                        }
                        
                        if sharing {
                            APOneDriveManager.instance.createSharingLink(fileId: fileId!, completion: { (result: OneDriveManagerResult, sharingUrl) -> Void in
                                switch(result) {
                                case .Success:
                                    print ("Sharing Url of file \(String(describing: sharingUrl))")
                                    DispatchQueue.main.async {
                                        SVProgressHUD.showSuccess(withStatus: "Sharing Url created")
                                    }
                                case .Failure(let error):
                                    print("\(error)")
                                    DispatchQueue.main.async {
                                        SVProgressHUD.showError(withStatus: "Unknown Error")
                                    }
                                }
                            })
                        }
                        self.dismiss(animated: true, completion: nil)
                        
                    case .Failure(let error):
                        print("\(error)")
                        DispatchQueue.main.async {
                            SVProgressHUD.showError(withStatus: "Uploading Failed")
                        }
                    }
                })
            case .Failure(let error):
                print("\(error)")
                DispatchQueue.main.async {
                    SVProgressHUD.showError(withStatus: "Uploading Failed")
                }
            }
        })
    }
}

extension APMoreMenuViewController {
    // show create folder alert and create folder
    func showCreateFolderOption() {
        var nameTextField: UITextField?
        
        let alertController = UIAlertController(
            title: "Create Folder",
            message: "Please enter folder name",
            preferredStyle: UIAlertController.Style.alert)
        
        let createAction = UIAlertAction(
        title: "Create", style: UIAlertAction.Style.default) { (action) -> Void in
            
            if let folderName = nameTextField?.text, folderName.count > 0 {
                print("folder name = \(folderName)")
                self.delegate?.moreMenuDidSelectRow(index: 1, dict: ["name": folderName])
                self.dismiss(animated: true, completion: nil)
            } else {
                print("No folder name entered")
                SVProgressHUD.showError(withStatus: "No folder name entered")
                self.dismiss(animated: true, completion: nil)
            }
        }
        
        let cancelAction = UIAlertAction( title: "Cancel", style: .cancel) { (action) in
            self.dismiss(animated: true, completion: nil)
        }
        
        alertController.addTextField {
            (folderName) -> Void in
            nameTextField = folderName
            nameTextField!.placeholder = "Folder Name"
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(createAction)
        self.present(alertController, animated: true, completion: nil)
    }
}
