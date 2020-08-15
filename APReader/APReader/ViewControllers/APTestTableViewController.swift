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
    private var files: [MSGraphDriveItem]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.rowHeight = 200
        
        loadFileData()
    }
    
    func loadFileData() {
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
                
                self.files = files
                self.tableView.reloadData()
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
        return cell
    }

//    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let file = files?[indexPath.row]
//        print(file?.webUrl as Any)
//        let storyBoard = UIStoryboard.init(name: "Main", bundle: nil)
//        let previewVC: APPreviewViewController = storyBoard.instantiateViewController(identifier: "PreviewVC")
//        previewVC.fileurl = URL(string: file!.webUrl!)
//        self.navigationController?.pushViewController(previewVC, animated: true)
//    }
}
