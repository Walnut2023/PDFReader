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
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var saveBtn: UIBarButtonItem!
    
    public var fileName: String?
    public var pageIndex: Int?
    public var location: CGPoint?
    public var actionHanlder: ((Bool, Bool) -> Void)?
    public var modifier: String? = UIDevice.current.name
    private var userDeleteComment: Bool?
    private var commentString: String?
    private var locationComments: [[String : String]]? = [[String : String]]()
    private let tableCellIdentifier = "APCommentTableViewCell"

    override func viewDidLoad() {
        super.viewDidLoad()
        setupData()
        setupUI()
    }
    
    func setupData() {
        let defaults = UserDefaults.standard
        let fileComments = defaults.object(forKey: fileName ?? "") as? [String: Any] ?? [String: Any]()
        print("fileComments: \(fileComments)")
        let pageComments = fileComments["\(pageIndex ?? 0)"] as? [String: Any] ?? [String: Any]()
        print("pageComments: \(pageComments)")
        let comments = pageComments["\(location ?? CGPoint(x: 0, y: 0))"] as? [String: Any] ?? [String: Any]()
        locationComments = comments["\(location ?? CGPoint(x: 0, y: 0))"] as? [[String: String]] ?? [[String: String]]()
        tableView.reloadData()
    }
    
    func setupUI() {
        commentTextfield.delegate = self
        tableView.rowHeight = 100
        tableView.tableFooterView = UIView()
    }
    
    @IBAction func saveAction(_ sender: Any) {
        if actionHanlder != nil {
            saveCommentData()
            if locationComments?.count ?? 0 > 0 {
                actionHanlder!(true, false)
            } else {
                actionHanlder!(false, true)
            }
        }
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        if actionHanlder != nil {
            actionHanlder!(false, false)
        }
        dismiss(animated: true, completion: nil)
    }
    
    func updateUI() {
        heightConstraint.constant = locationComments?.count ?? 0 > 0 ? 0 : 44
        commentTextfield.isHidden = locationComments?.count ?? 0 > 0 ? true : false
        commentTextfield.text = nil
        saveBtn.isEnabled = (locationComments?.count ?? 0 > 0 ? true : false) || (userDeleteComment ?? false)
    }
    
    func saveCommentData() {
        let defaults = UserDefaults.standard
        var fileComments = defaults.object(forKey: fileName ?? "") as? [String: Any] ?? [String: Any]()
        var pageComments = fileComments["\(pageIndex ?? 0)"] as? [String : Any] ?? [String: Any]()
        var locationComments = pageComments["\(location ?? CGPoint(x: 0, y: 0))"] as? [String : Any] ?? [String: Any]()

        locationComments["\(location ?? CGPoint(x: 0, y: 0))"] = self.locationComments
        pageComments["\(location ?? CGPoint(x: 0, y: 0))"] = locationComments
        fileComments["\(pageIndex ?? 0)"] = pageComments
        
        defaults.set(fileComments, forKey: fileName ?? "")
    }
}

extension APCommentContentViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        print(textField.text ?? "")
        guard let commentText = textField.text else { return false }
        let comment: [String : String] = ["comment" : commentText, "location" : "\(location ?? CGPoint(x: 0, y: 0))", "user" : modifier ?? ""]
        if commentTextfield.isHidden == false {
            locationComments?.append(comment)
        } else {
            locationComments?.removeAll()
            locationComments?.append(comment)
        }
        commentTextfield.isHidden = true
        heightConstraint.constant = 0
        tableView.reloadData()
        return true;
    }
}

extension APCommentContentViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        updateUI()
        return self.locationComments?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: tableCellIdentifier, for: indexPath) as! APCommentTableViewCell
        cell.commentDict = locationComments?[indexPath.row] ?? [:]
        cell.textFiled.delegate = self
        return cell
    }
}

extension APCommentContentViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .normal, title: "Delete") { (action, sourceView, completionHandler) in
            self.locationComments?.remove(at: indexPath.row)
            self.userDeleteComment = true
            tableView.deleteRows(at: [indexPath], with: .automatic)
            completionHandler(true)
        }
        deleteAction.backgroundColor = .systemRed
        
        let config = UISwipeActionsConfiguration(actions: [deleteAction])
        
        config.performsFirstActionWithFullSwipe = false
        return config
    }
}

