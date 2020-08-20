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
    
    private lazy var backBarButtonItem = UIBarButtonItem(image: UIImage.init(named: "back"), style: .plain, target: self, action: #selector(backAction))
    private lazy var signOoutBarButtonItem = UIBarButtonItem(image: UIImage.init(named: "logout"), style: .plain, target: self, action: #selector(signoutAction))
    
    private let refreshControl = UIRefreshControl()
    private lazy var tittleView = APNavigationTittleView()
    private var files: [MSGraphDriveItem]?
    private var selectedFile: String?
    private var selectedDriveItem: MSGraphDriveItem?
    static let fileCellID = "fileItemID"
    static let folderCellID = "folderItemID"
    var folderName = String()
    
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
        setupDataSource(for: folderName, itemId: selectedDriveItem?.entityId)
        updateUserInfo()
    }
    
    func reloadAction() {
        setupDataSource(for: folderName, itemId: selectedDriveItem?.entityId)
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
        refreshControl.addTarget(self, action: #selector(refreshDriveItemData), for: .valueChanged)
    }
    
    func setupNavUI() {
        tittleView = APNavigationTittleView.initInstanceFromXib()
        tittleView.frame.size.height = 54
        navigationItem.titleView = tittleView
        if folderName.count > 0 {
            navigationItem.setLeftBarButtonItems([backBarButtonItem], animated: true)
        } else {
            navigationItem.setLeftBarButtonItems([signOoutBarButtonItem], animated: true)
        }

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
    
    func setupDataSource(for folder: String, itemId: String?) {
        SVProgressHUD.show()
        APGraphManager.instance.getFiles(folderName: folder, itemId: itemId) {
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
                    fileItem.name?.contains(".pdf") ?? false || fileItem.folder != nil
                })
                self.refreshControl.endRefreshing()
                self.tableView.reloadData()
            }
        }
    }
    
    @objc
    private func refreshDriveItemData(_ sender: Any) {
        setupDataSource(for: folderName, itemId: selectedDriveItem?.entityId)
    }
    
    @objc
    func signoutAction(_ sender: Any) {
        APAuthManager.instance.signOut()
        // Signed Out successfully
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyBoard.instantiateViewController(identifier: "SignInVC")
        self.sceneDelegateWindow()?.rootViewController = vc
    }
    
    @objc
    func backAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    // more action to upload pdf files to OneDrive
    // Create folder in Apps/APDFReader
    @IBAction func moreAction(_ sender: Any) {
        let storyBoard = UIStoryboard.init(name: "Main", bundle: nil)
        let moreVC: APMoreMenuViewController = storyBoard.instantiateViewController(identifier: "MoreVC")
        moreVC.delegate = self
        let navigationController: UINavigationController = UINavigationController.init(rootViewController: moreVC)
        let horizontalClass = self.traitCollection.horizontalSizeClass
        if horizontalClass == UIUserInterfaceSizeClass.regular {
            navigationController.modalPresentationStyle = .popover
            navigationController.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
            self.present(navigationController, animated: true, completion: nil)
            let popController = navigationController.popoverPresentationController
            popController?.permittedArrowDirections = .any
        } else {
            self.present(navigationController, animated: true, completion: nil)
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if let cell = sender as? APFileItemTableViewCell {
            return cell.downloadBtn.isHidden
        }
        if let _ = sender as? APFolderTableViewCell {
            return true
        }
        return false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let selectedItem = self.files?[tableView.indexPathForSelectedRow!.row]
        if segue.identifier == "showPreview" {
            guard let vc = segue.destination as? APPreviewViewController else { return }
            let filePath = selectedItem?.name ?? ""
            selectedFile = filePath
            vc.filePath = filePath
        } else if segue.identifier == "showChildFolder" {
            guard let vc = segue.destination as? APFileListViewController else { return }
            vc.folderName = selectedItem?.name ?? ""
            vc.selectedDriveItem = selectedItem
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
        let fileItem = self.files?[indexPath.row]
        if fileItem?.folder == nil {
            let cell = tableView.dequeueReusableCell(withIdentifier: APFileListViewController.fileCellID) as! APFileItemTableViewCell
            cell.driveItem = fileItem

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
            
            cell.filename = fileItem?.name
            cell.updatetime = "\(fileItem?.lastModifiedTimeString() ?? "1970") - \(String(format: "%.2fMB", (Float)(fileItem?.size ?? 0) / 1024 / 1024))"
            return cell
            
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: APFileListViewController.folderCellID) as! APFolderTableViewCell
            cell.foldername = fileItem?.name
            cell.updatetime = "\(fileItem?.lastModifiedTimeString() ?? "1970") - \(String(format: "%.2fMB", (Float)(fileItem?.size ?? 0) / 1024 / 1024))"
            return cell
        }
    }
    
}

extension APFileListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
}

extension APFileListViewController: APMoreMenuViewControllerDelegate {
    func moreMenuDidSelectRow(index: Int, dict: [String : String]) {
        switch index {
        case 0:
            print("upload file")
            
        case 1:
            print("create folder: \(dict)")
            createFolderInAppRoot(folderName: dict["name"] ?? "")
        default:
            print("do nothing")
        }
    }
    
    func createFolderInAppRoot(folderName: String) {
        APOneDriveManager.instance.createFolder(folderName: folderName, completion: {(result: OneDriveManagerResult) in
            switch(result) {
            case .Success:
                print ("success")
                self.tableView.reloadData()
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
