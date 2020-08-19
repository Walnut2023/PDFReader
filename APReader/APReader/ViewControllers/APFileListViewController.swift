//
//  FileListViewController.swift
//  APReader
//
//  Created by Tangos on 2020/7/25.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit
import MSGraphClientModels
import Tiercel
import SVProgressHUD
import DZNEmptyDataSet

class APFileListViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    private let refreshControl = UIRefreshControl()
    private lazy var tittleView = APNavigationTittleView()

    private var files: [MSGraphDriveItem]?
    private var selectedFile: String?
    static let cellID = "fileItemID"
    
    var sessionManager: SessionManager = {
        var configuration = SessionConfiguration()
        configuration.allowsCellularAccess = true
        let path = Cache.defaultDiskCachePathClosure("APReader.OneDrive")
        let cacahe = Cache("OneDrive", downloadPath: path)
        let manager = SessionManager("OneDrive", configuration: configuration, cache: cacahe, operationQueue: DispatchQueue(label: "com.tango.SessionManager.operationQueue"))
        return manager
    }()
    
    override var hidesBottomBarWhenPushed: Bool {
        get {
            return navigationController?.topViewController != self
        }
        set {
            super.hidesBottomBarWhenPushed = newValue
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupDataSource()
        updateUserInfo()
    }
    
    func reloadAction() {
        setupDataSource()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.hidesBarsOnTap = false
    }
    
    func setupUI() {
        setupNavUI()
        tableView.tableFooterView = UIView()
        tableView.refreshControl = refreshControl
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        refreshControl.addTarget(self, action: #selector(refreshWeatherData(_:)), for: .valueChanged)
    }
    
    func setupNavUI() {
        tittleView = APNavigationTittleView.initInstanceFromXib()
        tittleView.frame.size.height = 54
        
        self.navigationItem.titleView = tittleView
    }
    
    func updateUserInfo() {
        DispatchQueue.global().async {
            APGraphManager.instance.getMe {
                (user: MSGraphUser?, error: Error?) in

                DispatchQueue.main.async {
                    guard let currentUser = user, error == nil else {
                        print("Error getting user: \(String(describing: error))")
                        return
                    }

                    self.tittleView.userName.text = currentUser.mail ?? currentUser.userPrincipalName ?? ""
                    self.tittleView.userName.sizeToFit()

                    self.tittleView.tittleLabel.text = currentUser.displayName ?? "Mysterious Stranger"
                    self.tittleView.tittleLabel.sizeToFit()
                }
            }
        }
    }
    
    func setupDataSource() {
        SVProgressHUD.show()
        APGraphManager.instance.getFiles {
            (fileArray: [MSGraphDriveItem]?, error: Error?) in
            DispatchQueue.main.async {
                guard let files = fileArray, error == nil else {
                    // Show the error
                    let alert = UIAlertController(title: "Error getting files",
                                                  message: error.debugDescription,
                                                  preferredStyle: .alert)
                    
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true)
                    return
                }
                SVProgressHUD.dismiss()
                self.files = files.filter({ (fileItem) -> Bool in
                    fileItem.name?.contains(".pdf") ?? false
                })
                self.refreshControl.endRefreshing()
                self.tableView.reloadData()
            }
        }
    }
    
    @objc
    private func refreshWeatherData(_ sender: Any) {
        setupDataSource()
    }
    
    @IBAction func signoutAction(_ sender: Any) {
        APAuthManager.instance.signOut()
        // Signed Out successfully
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyBoard.instantiateViewController(identifier: "SignInVC")
        self.sceneDelegateWindow()?.rootViewController = vc
    }
    
    // more action to upload pdf files to OneDrive
    // Create folder in Apps/APDFReader
    @IBAction func moreAction(_ sender: Any) {
        
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        guard let cell = sender as? APFileItemTableViewCell else { return false }
        return cell.downloadBtn.isHidden
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPreview" {
            guard let vc = segue.destination as? APPreviewViewController else { return }
            let filePath = self.files?[tableView.indexPathForSelectedRow!.row].name
            selectedFile = filePath
            vc.filePath = filePath
        }
    }
    
}

extension APFileListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.files?.count ?? 0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: APFileListViewController.cellID) as! APFileItemTableViewCell
        let fileItem = self.files?[indexPath.row]
        cell.filename = fileItem?.name
        
        cell.updatetime = "\(fileItem?.lastModifiedTimeString() ?? "1970") - \(String(format: "%.2fMB", (Float)(fileItem?.size ?? 0) / 1024 / 1024))"

        cell.tapClosure = { [weak self] cell in
            if let task = self?.sessionManager.fetchTask(fileItem?.graphDownloadUrl() ?? "") {
                switch task.status {
                case .waiting, .running:
                    cell.loadingIndicator.isHidden = false
                    self?.sessionManager.suspend(task)
                case .suspended, .failed:
                    self?.sessionManager.start(task)
                default: break
                }
            } else {
                // shouldn't be like this
                self?.sessionManager.download(fileItem?.graphDownloadUrl() ?? "", fileName: fileItem?.name) { _ in
                    self?.tableView.reloadData()
                }
                
            }
        }
        
        if let task = sessionManager.fetchTask(fileItem?.graphDownloadUrl() ?? "") {
            cell.updateProgress(task)
            task.progress { [weak cell] (task) in
                cell?.updateProgress(task)
            }
            .success { [weak cell] (task) in
                cell?.updateProgress(task)
            }
            .failure { [weak cell] (task) in
                cell?.updateProgress(task)
                if task.status == .suspended {}
                if task.status == .failed {}
                if task.status == .canceled {}
                if task.status == .removed {}
            }
        }
        
        return cell
    }
    
}

extension APFileListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
}

// Update files to OneDrive
extension APFileListViewController {
    func updatePDFFiles() {
        guard let selectedFileName = selectedFile else {
            return
        }
        APOneDriveManager.instance.createUploadSession(fileName: selectedFileName, completion: { (result: OneDriveManagerResult, uploadUrl, expirationDateTime, nextExpectedRanges) -> Void in
                    switch(result) {
                    case .Success:
                            print("success on creating session (\(String(describing: uploadUrl)) (\(String(describing: expirationDateTime))")

                            APOneDriveManager.instance.uploadPDFBytes(fileName: selectedFileName, uploadUrl: uploadUrl!,  completion: { (result: OneDriveManagerResult, webUrl, fileId) -> Void in
                                switch(result) {
                                case .Success:
                                    print ("Web Url of file \(String(describing: webUrl))")
                                    print ("FileId of file \(String(describing: fileId))")
                                    
        //                            APOneDriveManager.instance.createSharingLink(fileId: fileId!, completion: { (result: OneDriveManagerResult, sharingUrl) -> Void in
        //                                switch(result) {
        //                                case .Success:
        //                                    print ("Sharing Url of file \(sharingUrl)")
        //
        //                                case .Failure(let error):
        //                                    print("\(error)")
        //                                }
        //                            })
                                    
                                case .Failure(let error):
                                    print("\(error)")
                                }
                            })
                    case .Failure(let error):
                        print("\(error)")
                    }
                })
    }
}

extension APFileListViewController: DZNEmptyDataSetSource {
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return UIImage.init(named: "no_pdf")
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let nofilesStr = "No PDF Files"
        let noAttr = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18.0), NSAttributedString.Key.foregroundColor: UIColor.black]
        return NSAttributedString(string: nofilesStr, attributes: noAttr)
    }
}

extension APFileListViewController: DZNEmptyDataSetDelegate {
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        return true
    }
    
    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView!) -> Bool {
        return true
    }
}
