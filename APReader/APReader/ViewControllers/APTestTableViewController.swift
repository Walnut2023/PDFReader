//
//  APTestTableViewController.swift
//  APReader
//
//  Created by Tango on 2020/8/11.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit
import MSGraphClientModels

class APTestTableViewController: UITableViewController {

    private let tableCellIdentifier = "APTestTableViewCell"
    private var files: [String]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        loadLocalFiles()
        navigationItem.title = "Files"
        tableView.rowHeight = 100
    }

    func loadLocalFiles() {
        let cachePath = NSHomeDirectory() + "/Library/Caches/APReader.Local/File"
        let manger = FileManager.default

        if !manger.fileExists(atPath: cachePath.appending("/final.pdf")) {
            do {
                try manger.createDirectory(atPath: cachePath, withIntermediateDirectories: true, attributes: nil)
                let fileUrl = Bundle.main.url(forResource: "final", withExtension: "pdf")
                let documentsDirectory = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
                let docURL = URL(string: documentsDirectory)!
                let dataPath = docURL.appendingPathComponent("APReader.Local/File/final.pdf")
                try manger.moveItem(atPath: fileUrl!.path, toPath: dataPath.path)
                
                do {
                    files = try manger.contentsOfDirectory(atPath: cachePath).filter({ (fileName) -> Bool in
                        fileName.contains(".pdf")
                    })
                } catch {
                    print("\(error)")
                }
            } catch {
                print("\(error)")
            }
        } else {
            let manger = FileManager.default
            do {
                files = try manger.contentsOfDirectory(atPath: cachePath).filter({ (fileName) -> Bool in
                    fileName.contains(".pdf")
                })
            } catch {
                print("\(error)")
            }
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
        let storyBoard = UIStoryboard.init(name: "Main", bundle: nil)
        let previewVC: APPreviewViewController = storyBoard.instantiateViewController(identifier: "PreviewVC")
        previewVC.fileSourceType = .LOCAL
        let driveItem = MSGraphDriveItem()
        driveItem.name = fileName
        previewVC.driveItem = driveItem
        previewVC.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(previewVC, animated: true)
    }
}
