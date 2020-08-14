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

class APFileListViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var files: [MSGraphDriveItem]?
    
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.hidesBarsOnTap = false
    }
    
    func setupUI() {
        self.tableView.tableFooterView = UIView()
    }
    
    func setupDataSource() {
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
                
                self.files = files.filter({ (fileItem) -> Bool in
                    fileItem.name?.contains(".pdf") ?? false
                })
                self.tableView.reloadData()
            }
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        guard let cell = sender as? APFileItemTableViewCell else { return false }
        return cell.downloadBtn.isHidden
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPreview" {
            guard let vc = segue.destination as? APPreviewViewController else { return }
            let filePath = self.files?[tableView.indexPathForSelectedRow!.row].name
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
                if task.status == .suspended {
                    
                }
                
                if task.status == .failed {
                    
                }
                if task.status == .canceled {
                    
                }
                if task.status == .removed {
                    
                }
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
