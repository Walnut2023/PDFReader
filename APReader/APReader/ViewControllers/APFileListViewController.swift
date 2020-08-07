//
//  FileListViewController.swift
//  APReader
//
//  Created by Tangos on 2020/7/25.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit

class APFileListViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var filesList: [FileItem] = [FileItem]()
    
    static let cellID = "fileItemID"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDataSource()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.hidesBarsOnTap = false
    }
    
    func setupDataSource() {
        for _ in 0...5 {
            let item = FileItem(name: "test-driven")
            self.filesList.append(item)
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPreview" {
            guard let vc = segue.destination as? APPreviewViewController else { return }
            vc.filePath = self.filesList[tableView.indexPathForSelectedRow!.row].name
        }
    }
    
}

extension APFileListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1;
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.filesList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: APFileListViewController.cellID, for:indexPath)
        let fileItem = self.filesList[indexPath.row]
        cell.textLabel?.text = fileItem.name
        return cell
    }
}

extension APFileListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
}
