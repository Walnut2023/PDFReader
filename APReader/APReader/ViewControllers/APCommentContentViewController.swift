//
//  APCommentContentViewController.swift
//  APReader
//
//  Created by Tango on 2020/9/5.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit

class APCommentContentViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var commentTextfield: UITextField!
    
    public var actionHanlder: ((Bool, String) -> Void)?
    public var location: CGPoint?
    private var commentString: String?
    private var comments: [String]? = [String]()

    private let tableCellIdentifier = "APCommentTableViewCell"

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        print("location: \(location)")
    }
    
    func setupUI() {
        commentTextfield.delegate = self
        tableView.rowHeight = 80
    }
    
    @IBAction func saveAction(_ sender: Any) {
        if actionHanlder != nil {
            actionHanlder!(true, "test Hello world")
        }
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        if actionHanlder != nil {
            actionHanlder!(false, "an empty string")
        }
        dismiss(animated: true, completion: nil)
    }
}

extension APCommentContentViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        print(textField.text ?? "")
        comments?.append(textField.text ?? "")
        tableView.reloadData()
        return true;
    }
}

extension APCommentContentViewController: UITableViewDelegate {
    
}

extension APCommentContentViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.comments?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: tableCellIdentifier, for: indexPath) as! APCommentTableViewCell
        cell.commentString = comments?[indexPath.row] ?? ""
        return cell
    }
}
