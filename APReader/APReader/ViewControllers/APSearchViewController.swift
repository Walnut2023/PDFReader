//
//  APSearchViewController.swift
//  APReader
//
//  Created by tango on 2020/7/30.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit
import PDFKit

protocol SearchTableViewControllerDelegate: AnyObject {
    func searchTableViewControllerDidSelectPdfSelection(pdfSelection: PDFSelection)
}

class APSearchViewController: UITableViewController {

    static let CellID = "APSearchTableViewCell"
    
    public weak var delegate: SearchTableViewControllerDelegate?
    public var pdfDocument: PDFDocument?

    var searchBar: UISearchBar?
    var searchResultArray: [PDFSelection]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initData()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.searchBar?.becomeFirstResponder()
    }
    
    func initData() {
        self.searchResultArray = [PDFSelection]()
    }
    
    func setupUI() {
        self.searchBar = UISearchBar()
        self.searchBar?.delegate = self
        self.searchBar?.sizeToFit()
        self.searchBar?.searchBarStyle = .minimal
        self.navigationItem.titleView = searchBar
    }

}

// MARK: - Table view data source

extension APSearchViewController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let searchResults = self.searchResultArray else { return 0 }
        return searchResults.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: APSearchTableViewCell = tableView.dequeueReusableCell(withIdentifier: APSearchViewController.CellID, for: indexPath) as! APSearchTableViewCell
        if let searchResults = self.searchResultArray, searchResults.count > 0 {
            let selection = searchResults[indexPath.row]
            let outline = pdfDocument?.outlineItem(for: selection)
            cell.outlineLabel.text = outline?.label
            let page = selection.pages[0]
            let pagestr = page.label ?? ""
            cell.pageNumberLabel.text = pagestr

            let extendSelection = selection.copy() as! PDFSelection
            extendSelection.extend(atStart: 10)
            extendSelection.extend(atEnd: 90)
            extendSelection.extendForLineBoundaries()

            let range = (extendSelection.string! as NSString).range(of: selection.string!, options: .caseInsensitive)
            let attrstr = NSMutableAttributedString(string: extendSelection.string!)
            attrstr.addAttribute(NSAttributedString.Key.backgroundColor, value: UIColor.yellow, range: range)

            cell.searchResultTextLabel.attributedText = attrstr
        }
        return cell
    }
    
}

// MARK: - Table view delegate

extension APSearchViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let searchResults = self.searchResultArray else { return }
        let pdfSelection = searchResults[indexPath.row]
        self.delegate?.searchTableViewControllerDidSelectPdfSelection(pdfSelection: pdfSelection)
        self.dismiss(animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 82
    }
}

// MARK: - search bar delegate

extension APSearchViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.searchBar?.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.pdfDocument?.cancelFindString()
        self.navigationItem.setRightBarButton(nil, animated: true)
        self.dismiss(animated: true, completion: nil)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard searchText.count > 2 else {
            return
        }
        
        self.searchResultArray?.removeAll()
        self.tableView.reloadData()
        self.pdfDocument?.cancelFindString()
        self.pdfDocument?.delegate = self
        self.pdfDocument?.beginFindString(searchText, withOptions: .caseInsensitive)
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        let cancelBarButton = UIBarButtonItem.init(title: "Cancel", style: .plain, target: self, action: #selector(cancelBarButtonItemClicked))
        self.navigationItem.setRightBarButton(cancelBarButton, animated: true)
        return true
    }
    
    @objc func cancelBarButtonItemClicked(_ sender: Any) {
        guard let searchBar = self.searchBar else { return }
        self.searchBarCancelButtonClicked(searchBar)
    }
}

// MARK: - UIScrollview delegate

extension APSearchViewController {
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.searchBar?.resignFirstResponder()
    }
}

// MARK: - PDFDocument Delegate

extension APSearchViewController: PDFDocumentDelegate {
    func didMatchString(_ instance: PDFSelection) {
        self.searchResultArray?.append(instance)
        self.tableView.reloadData()
    }
}


