//
//  APBookmarkViewController.swift
//  APReader
//
//  Created by tango on 2020/7/29.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit
import PDFKit

enum EditStatus: Int {
    case NORMAL = 0
    case EDITING = 1
}

protocol APBookmarkViewControllerDelegate: AnyObject {
    func dismissBookmarkViewController(_ viewController: APBookmarkViewController)
    func bookmarkViewController(_ viewController: APBookmarkViewController, didRequestPageAtIndex: Int)
}

class APBookmarkViewController: UIViewController {

    static let cellID = "APBookmarkTableViewCell"

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    public weak var delegate: APBookmarkViewControllerDelegate?
    public var documentName: String?
    public var pdfView: PDFView?
    
    private var status: EditStatus?
    private var bookmarks: [String]?
    private var bookmarkNames: [String]?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.status = EditStatus.NORMAL
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initData()
        self.tableView.reloadData()
    }
    
    func initData() {
        self.bookmarks = [String]()
        self.bookmarkNames = [String]()
        self.bookmarks = loadBookmarks()
        self.bookmarkNames = loadBookmarkNames()
    }
    
    func loadBookmarks() -> [String] {
        var res = [String]()
        let defaults = UserDefaults.standard
        let array = defaults.object(forKey:"pdf_\(self.documentName ?? "")") as? [String] ?? [String]()
        if array.count > 0 {
            res.append(contentsOf: array)
        }
        return res
    }
    
    func loadBookmarkNames() -> [String] {
        var res = [String]()
        let defaults = UserDefaults.standard
        let array = defaults.object(forKey:"pdf_name_\(self.documentName ?? "")") as? [String] ?? [String]()
        if array.count > 0 {
            res.append(contentsOf: array)
        } else {
            guard let bookmarks = self.bookmarks else { return res }
            for item in bookmarks {
                bookmarkNames?.append("Page \(item)")
            }
        }
        return res
    }
    
    func enableEditing() {
        self.editButton.title = "Done"
        self.tableView.isEditing = true
        self.status = EditStatus.EDITING
    }

    func disableEditing() {
        self.editButton.title = "Edit"
        self.tableView.isEditing = false
        self.status = EditStatus.NORMAL
    }
    
    func saveBookmarks() {
        let defaults = UserDefaults.standard
        defaults.set(self.bookmarks, forKey: "pdf_\(self.documentName ?? "")")
        defaults.set(self.bookmarkNames, forKey: "pdf_name_\(self.documentName ?? "")")
        defaults.synchronize()
    }
    
    // MARK-: Action
    @IBAction func addBookmarkAction(_ sender: Any) {
        let pageNumberText = self.pdfView?.currentPage?.label
        self.bookmarks?.append(pageNumberText ?? "0")
        self.bookmarkNames?.append("Page \(pageNumberText ?? "")")
        self.saveBookmarks()
        self.tableView.reloadData()
    }
    
    @IBAction func editBookmarkAction(_ sender: Any) {
        if self.status == EditStatus.NORMAL {
            self.enableEditing()
        } else if self.status == EditStatus.EDITING {
            self.disableEditing()
            self.saveBookmarks()
        }
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        if self.status == EditStatus.EDITING {
            self.disableEditing()
        }
        self.saveBookmarks()
        self.delegate?.dismissBookmarkViewController(self)
    }
    
}

extension APBookmarkViewController: UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let bookmarks = self.bookmarks else {
            self.disableEditing()
            return 0
        }
        self.editButton.isEnabled = bookmarks.count > 0
        return bookmarks.count
    }
}

extension APBookmarkViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let bookmarkNames = self.bookmarkNames else { return UITableViewCell() }
        let bookmarkName = "\(bookmarkNames[indexPath.row])"
        let cell: APBookmarkTableViewCell = tableView.dequeueReusableCell(withIdentifier: APBookmarkViewController.cellID, for: indexPath) as! APBookmarkTableViewCell
        cell.bookmarkTextfield.text = bookmarkName
        cell.bookmarkTextfield.tag = indexPath.row
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let index = indexPath.row
            self.bookmarks?.remove(at: index)
            self.bookmarkNames?.remove(at: index)
            tableView.deleteRows(at: [indexPath], with: .left)
            self.saveBookmarks()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let index = indexPath.row
        guard let bookmarks = self.bookmarks else { return }
        let pageNumber = bookmarks[index]
        self.delegate?.bookmarkViewController(self, didRequestPageAtIndex: Int(pageNumber) ?? 0)
    }
}

extension APBookmarkViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if !self.tableView.isEditing {
            let index = textField.tag
            guard let bookmarks = self.bookmarks else { return false }
            let pageNumber = bookmarks[index]
            self.delegate?.bookmarkViewController(self, didRequestPageAtIndex: Int(pageNumber) ?? 0)
        }
        return self.tableView.isEditing
    }
    
    @IBAction func textfieldEditingChangedAction(_ sender: UITextField) {
        let tag = sender.tag
        self.bookmarkNames?.remove(at: tag)
        self.bookmarkNames?.insert(sender.text ?? "", at: tag)
    }

}
