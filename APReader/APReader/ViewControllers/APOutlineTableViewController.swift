//
//  APOutlineTableViewController.swift
//  APReader
//
//  Created by tango on 2020/7/29.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit
import PDFKit

protocol APOutlineTableViewControllerDelegate: AnyObject {
    func outlineTableViewControllerDidSelectPdfOutline(pdfOutline: PDFOutline)
}

class APOutlineTableViewController: UITableViewController {

    static let cellID = "APOutlineTableViewCell"
    
    public weak var delegate: APOutlineTableViewControllerDelegate?
    
    public var pdfOutlineRoot: PDFOutline?
    private var outlineArray: [PDFOutline]?
    private var childOutlineArray: [PDFOutline]?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initData()
        self.tableView.reloadData()
    }
    
    func initData() {
        self.outlineArray = [PDFOutline]()
        self.childOutlineArray = [PDFOutline]()
        self.outlineArray?.removeAll()
        guard let pdfOutlineRoot = self.pdfOutlineRoot else { return }
        for index in 0..<pdfOutlineRoot.numberOfChildren {
            let outline = self.pdfOutlineRoot?.child(at: index)
            if outline != nil {
                outline?.isOpen = false
                self.outlineArray?.append(outline!)
            }
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.outlineArray?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: APOutlineTableViewCell = tableView.dequeueReusableCell(withIdentifier: APOutlineTableViewController.cellID, for: indexPath) as! APOutlineTableViewCell
        guard let outlineArray = self.outlineArray else { return UITableViewCell() }
        let outline = outlineArray[indexPath.row]
        
        cell.outlineTextLabel.text = outline.label
        cell.pageNumberLabel.text = outline.destination?.page?.label
        
        if outline.numberOfChildren > 0 {
            cell.openButton.setImage(outline.isOpen ? UIImage(named: "arrow_down") : UIImage(named: "arrow_right"), for: .normal)
            cell.openButton.isEnabled = true
        } else {
            cell.openButton.setImage(nil, for: .normal)
            cell.openButton.isEnabled = false
        }
        cell.openButton.tag = indexPath.row
        cell.openButton.addTarget(self, action: #selector(openButtonAction), for: .touchUpInside)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, indentationLevelForRowAt indexPath: IndexPath) -> Int {
        guard let outlineArray = self.outlineArray else { return 0 }
        let pdfOutline = outlineArray[indexPath.row]
        let depth = self.findDepth(outline: pdfOutline)
        return depth
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let outlineArray = self.outlineArray else { return }
        let pdfOutline = outlineArray[indexPath.row]
        self.delegate?.outlineTableViewControllerDidSelectPdfOutline(pdfOutline: pdfOutline)
        self.dismiss(animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    // MARK:-Action
    
    @objc func openButtonAction(button: UIButton) {
        print("open button tapped")
        button.isSelected = !button.isSelected
        let rowNumber = button.tag
        guard let outlineArray = self.outlineArray else { return }
        let pdfOutline: PDFOutline = outlineArray[rowNumber]
        
        if pdfOutline.numberOfChildren > 0 {
            if button.isSelected {
                pdfOutline.isOpen = true
                insetChildFrom(pdfOutline)
            } else {
                pdfOutline.isOpen = false
                removeChildFrom(pdfOutline)
            }
            self.tableView.reloadData()
        }
    }
    
    // MARK:-Helper
    
    func findDepth(outline pdfOutline: PDFOutline?) -> Int {
        var depth = -1
        guard let outline = pdfOutline else { return -1 }
        var tmpOutline = outline
        while tmpOutline.parent != nil {
            depth += 1
            tmpOutline = tmpOutline.parent!
        }
        return depth
    }
    
    func insetChildFrom(_ parentOutline: PDFOutline) {
        self.childOutlineArray?.removeAll()
        guard let outlineArray = self.outlineArray else { return }
        let baseIdnex = outlineArray.lastIndex(of: parentOutline)
        for index in 0..<parentOutline.numberOfChildren {
            if let pdfOutline = parentOutline.child(at: index) {
                pdfOutline.isOpen = false
                self.childOutlineArray?.append(pdfOutline)
            }
        }
        self.outlineArray?.insert(contentsOf: self.childOutlineArray!, at: (baseIdnex ?? 0) + 1)
    }
    
    func removeChildFrom(_ parentOutline: PDFOutline) {
        if parentOutline.numberOfChildren <= 0 {
            return
        }
        
        for index in 0..<parentOutline.numberOfChildren {
            guard let node = parentOutline.child(at: index) else { return }
            if node.numberOfChildren > 0 {
                self.removeChildFrom(node)
                if self.outlineArray?.contains(node) ?? false {
                    guard let index = self.outlineArray?.lastIndex(of: node) else { return }
                    self.outlineArray?.remove(at: index)
                }
            } else {
                if self.outlineArray?.contains(node) ?? false {
                    guard let index = self.outlineArray?.lastIndex(of: node) else { return }
                    self.outlineArray?.remove(at: index)
                }
            }
        }
    }
    
}
