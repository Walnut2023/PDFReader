//
//  APPDFToolbarActionControl.swift
//  APReader
//
//  Created by tango on 2020/7/29.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit
import PDFKit

class APPDFToolbarActionControl: NSObject {
    public var pdfPreviewController: APPreviewViewController?
    var selectedIndexPath: NSIndexPath?
    
    init(pdfPreviewController: APPreviewViewController) {
        self.pdfPreviewController = pdfPreviewController
        super.init()
    }
    
    func showOutlineTableForPFDDocument(for pdfDocument: PDFDocument?, from sender: Any) {
        guard let pdfDocumentRoot = pdfDocument?.outlineRoot else { return }
        let storyBoard = UIStoryboard.init(name: "Main", bundle: nil)
        let outlineVC: APOutlineTableViewController = storyBoard.instantiateViewController(identifier: "OutlineTableVC")
        outlineVC.delegate = self
        outlineVC.pdfOutlineRoot = pdfDocumentRoot
        let navigationContriller: UINavigationController = UINavigationController.init(rootViewController: outlineVC)
        let horizontalClass = self.pdfPreviewController?.traitCollection.horizontalSizeClass
        if horizontalClass == UIUserInterfaceSizeClass.regular {
            navigationContriller.modalPresentationStyle = .popover
            navigationContriller.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
            self.pdfPreviewController?.present(navigationContriller, animated: true, completion: nil)
            let popController = navigationContriller.popoverPresentationController
            popController?.permittedArrowDirections = .any
        } else {
            self.pdfPreviewController?.present(navigationContriller, animated: true, completion: nil)
        }
    }
    
    func showBookmarkTable(from sender: Any) {
        let storyBoard = UIStoryboard.init(name: "Main", bundle: nil)
        let bookmarkVC: APBookmarkViewController = storyBoard.instantiateViewController(identifier: "BookmarkVC")
        bookmarkVC.delegate = self
        bookmarkVC.pdfView = self.pdfPreviewController?.pdfView
        bookmarkVC.documentName = self.pdfPreviewController?.filePath
        let navigationContriller: UINavigationController = UINavigationController.init(rootViewController: bookmarkVC)
        let horizontalClass = self.pdfPreviewController?.traitCollection.horizontalSizeClass
        if horizontalClass == UIUserInterfaceSizeClass.regular {
            navigationContriller.modalPresentationStyle = .popover
            navigationContriller.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
            self.pdfPreviewController?.present(navigationContriller, animated: true, completion: nil)
            let popController = navigationContriller.popoverPresentationController
            popController?.permittedArrowDirections = .any
        } else {
            self.pdfPreviewController?.present(navigationContriller, animated: true, completion: nil)
        }
    }
    
    func showSearchViewController(for pdfDocument: PDFDocument?, from sender: Any) {
        guard let document = pdfDocument else { return }
        let storyBoard = UIStoryboard.init(name: "Main", bundle: nil)
        let searchVC: APSearchViewController = storyBoard.instantiateViewController(identifier: "SearchVC")
        searchVC.delegate = self
        searchVC.pdfDocument = document
        let navigationContriller: UINavigationController = UINavigationController.init(rootViewController: searchVC)
        let horizontalClass = self.pdfPreviewController?.traitCollection.horizontalSizeClass
        if horizontalClass == UIUserInterfaceSizeClass.regular {
            navigationContriller.modalPresentationStyle = .popover
            navigationContriller.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
            self.pdfPreviewController?.present(navigationContriller, animated: true, completion: nil)
            let popController = navigationContriller.popoverPresentationController
            popController?.permittedArrowDirections = .any
        } else {
            self.pdfPreviewController?.present(navigationContriller, animated: true, completion: nil)
        }
    }
    
}

extension APPDFToolbarActionControl: APOutlineTableViewControllerDelegate {
    func outlineTableViewControllerDidSelectPdfOutline(pdfOutline: PDFOutline) {
        self.pdfPreviewController?.didSelectPdfOutline(pdfOutline)
    }
}

extension APPDFToolbarActionControl: APBookmarkViewControllerDelegate {
    func dismissBookmarkViewController(_ viewController: APBookmarkViewController) {
        self.pdfPreviewController?.dismiss(animated: true, completion: nil)
    }
    
    func bookmarkViewController(_ viewController: APBookmarkViewController, didRequestPageAtIndex pageNumber: Int) {
        let pdfPage = self.pdfPreviewController?.pdfDocument?.page(at: pageNumber - 1)
        self.pdfPreviewController?.didSelectPdfPageFromBookmark(pdfPage)
        self.pdfPreviewController?.dismiss(animated: true, completion: nil)
    }
}

extension APPDFToolbarActionControl: SearchTableViewControllerDelegate {
    func searchTableViewControllerDidSelectPdfSelection(pdfSelection: PDFSelection) {
        self.pdfPreviewController?.didSelectPdfSelection(pdfSelection)
    }
}
