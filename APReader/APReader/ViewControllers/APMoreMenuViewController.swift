//
//  APMoreMenuTableViewController.swift
//  APReader
//
//  Created by Tango on 2020/8/20.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit

protocol APMoreMenuViewControllerDelegate: AnyObject {
    func moreMenuDidSelectRow(index: Int, dict: [String: String])
}

class APMoreMenuViewController: UITableViewController {
    
    private var items: [[String: String]]?
    private let tableCellIdentifier = "APMoreMenuCell"
    
    public weak var delegate: APMoreMenuViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupDataSource()
    }
    
    func setupUI() {
        tableView.tableFooterView = UIView()
    }
    
    func setupDataSource() {
        items = [["storage": "Upload Files"], ["addfolders": "Add Folder"]]
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
        print("did select row")
//        guard let items = items else { return }
        //        let dict = items[indexPath.row]
        
        switch indexPath.row {
        case 0:
            print("file upload")
        case 1:
            print("create folder")
            showCreateFolderOption()
        default:
            print("do nothing")
        }
        
        //        self.delegate?.moreMenuDidSelectRow(index: indexPath.row, dict: dict)
        //        self.dismiss(animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
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
