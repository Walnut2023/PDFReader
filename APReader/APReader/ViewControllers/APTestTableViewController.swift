//
//  APTestTableViewController.swift
//  APReader
//
//  Created by Tango on 2020/8/11.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit
import MSGraphClientModels
import DZNEmptyDataSet

class APTestTableViewController: UITableViewController {
    
    private let tableCellIdentifier = "APTestTableViewCell"
    private var files: [String]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerNotification()
        loadLocalFiles()
        tableView.rowHeight = 100
        tableView.tableFooterView = UIView()
    }
    
    func registerNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleForOpenPDFFile), name: NSNotification.Name("OpenPDFFile"), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc
    func handleForOpenPDFFile(noti: Notification) {
        if let userInfo = noti.userInfo,
            let filePath = userInfo["filePath"] as? String,
            let fileName = userInfo["fileName"] as? String {
            print("should open a pdf file: \(filePath)")
            if FileManager.default.fileExists(atPath: filePath) {
                loadLocalFiles()
                showPreviewVC(fileName)
            }
        }
    }
    
    func showPreviewVC(_ fileName: String) {
        let storyBoard = UIStoryboard.init(name: "Main", bundle: nil)
        let previewVC: APPreviewViewController = storyBoard.instantiateViewController(identifier: "PreviewVC")
        previewVC.fileSourceType = .LOCAL
        let driveItem = MSGraphDriveItem()
        driveItem.name = fileName
        previewVC.driveItem = driveItem
        previewVC.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(previewVC, animated: true)
    }
    
    func loadLocalFiles() {
        let manger = FileManager.default
        let cachePath = NSHomeDirectory() + "/Library/Caches/APReader.Local/File"
        do {
            try manger.createDirectory(atPath: cachePath, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("directory make failed")
        }
        do {
            files = try manger.contentsOfDirectory(atPath: cachePath).filter({ (fileName) -> Bool in
                fileName.contains(".pdf")
            })
            if files?.count == 0 {
                let bundlePath = Bundle.main.path(forResource: "Demo", ofType: ".pdf")
                print("\(bundlePath ?? "")") //prints the correct path
                let destPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
                let fileManager = FileManager.default
                let fullDestPath = NSURL(fileURLWithPath: destPath).appendingPathComponent("APReader.Local/File/Demo.pdf")
                let fullDestPathString = fullDestPath?.path
                print(fileManager.fileExists(atPath: bundlePath!)) // prints true
                
                do {
                    try fileManager.copyItem(atPath: bundlePath!, toPath: fullDestPathString ?? "")
                    files = try manger.contentsOfDirectory(atPath: cachePath).filter({ (fileName) -> Bool in
                        fileName.contains(".pdf")
                    })
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                } catch {
                        print(error)
                        self.tableView.reloadData()
                }
            }
        } catch {
            print("\(error)")
        }
        
        do {
            files = try manger.contentsOfDirectory(atPath: cachePath).filter({ (fileName) -> Bool in
                fileName.contains(".pdf")
            })
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        } catch {
            print("\(error)")
            self.tableView.reloadData()
        }
    }
    
    func deleteLocalFiles(_ fileName: String?) {
        guard let fileName = fileName else { return }
        do {
            let fileManager = FileManager.default
            let destPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
            let fullDestPath = NSURL(fileURLWithPath: destPath).appendingPathComponent("APReader.Local/File/\(fileName)")
            let fullDestPathString = fullDestPath?.path
            try fileManager.removeItem(atPath: fullDestPathString ?? "")
        } catch {
            print("\(error)")
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return files?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: tableCellIdentifier, for: indexPath) as! APTestTableViewCell
        cell.titleLabel.text = files?[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let fileName = files?[indexPath.row]
        showPreviewVC(fileName ?? "")
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let index = indexPath.row
            let fileName = files?[indexPath.row]
            files?.remove(at: index)
            tableView.deleteRows(at: [indexPath], with: .left)
            deleteLocalFiles(fileName)
        }
    }
}

extension APTestTableViewController: DZNEmptyDataSetSource {
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return UIImage.init(named: "no_pdf")
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let nofilesStr = "No PDF Files"
        let noAttr = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18.0), NSAttributedString.Key.foregroundColor: UIColor.hex(0xC3C3C3)]
        return NSAttributedString(string: nofilesStr, attributes: noAttr)
    }
}

extension APTestTableViewController: DZNEmptyDataSetDelegate {
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        return true
    }
    
    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView!) -> Bool {
        return true
    }
}
