//
//  APPreviewViewController.swift
//  APReader
//
//  Created by Tangos on 2020/7/25.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit
import PDFKit

class APPreviewViewController: UIViewController {
    
    public var filePath: String?
    public var pdfDocument: PDFDocument?

    @IBOutlet weak var pdfTittleLabel: UILabel!
    @IBOutlet weak var pdfView: APNonSelectablePDFView!
    @IBOutlet weak var thumbnailView: PDFThumbnailView!
    @IBOutlet weak var thumbnailViewContainer: UIView!
    @IBOutlet weak var pageControl: UIView!
    @IBOutlet weak var topToolBar: UIToolbar!
    @IBOutlet weak var toolContainer: UIView!
    @IBOutlet weak var topToolbarHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var pdfViewLeftMarginConstraint: NSLayoutConstraint!
    
    private lazy var tapFestureRecognizer = UITapGestureRecognizer()
    private lazy var pdfDrawingGestureRecognizer = APDrawingGestureRecognizer()
    private lazy var pdfTextDrawingGestureRecognizer = APTextDrawingGestureRecognizer()
    
    private var topbarActionControl: APPDFToolbarActionControl?

    private let pdfDrawer = APPDFDrawer()
    private let pdfTextDrawer = APPDFTextDrawer()
    
    private var count = 0
    
    // MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupPDFView()
        loadPdfFile()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = true
        super.viewWillAppear(animated)
    }
    
    private func setupUI() {
        self.pageControl.isHidden = true
        self.topbarActionControl = APPDFToolbarActionControl(pdfPreviewController: self)
        self.pdfViewLeftMarginConstraint.constant = 120
        self.tapFestureRecognizer = UITapGestureRecognizer()
        tapFestureRecognizer.addTarget(self, action: #selector(tappedAction))
        pdfView.addGestureRecognizer(tapFestureRecognizer)
    }
    
    private func setupPDFView() {
        pdfView.displayDirection = .vertical
        pdfView.usePageViewController(true)
        pdfView.pageBreakMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        pdfView.autoScales = true
        pdfView.backgroundColor = view.backgroundColor!
        
        thumbnailView.pdfView = pdfView
        thumbnailView.thumbnailSize = CGSize(width: 100, height: 100)
        thumbnailView.layoutMode = .vertical
        thumbnailView.backgroundColor = thumbnailViewContainer.backgroundColor!
                
        pdfDrawer.pdfView = pdfView
        pdfTextDrawer.pdfView = pdfView
    }
    
    private func loadPdfFile() {
        let fileURL = Bundle.main.url(forResource: filePath, withExtension: "pdf")!
        let pdfDocument = PDFDocument(url: fileURL)
        pdfView.document = pdfDocument
        self.pdfDocument = pdfDocument
        pdfTittleLabel.text = self.filePath
    }
    
    // MARK: -  Action
    
    @objc func tappedAction() {
        print("tapped")
        UIView.transition(with: self.topToolBar, duration: 0.25, options: .transitionCrossDissolve, animations: {
            self.topToolBar.isHidden = !self.topToolBar.isHidden
            self.toolContainer.isHidden = !self.toolContainer.isHidden
            self.thumbnailView.isHidden = !self.thumbnailView.isHidden
            self.pdfViewLeftMarginConstraint.constant = self.pdfViewLeftMarginConstraint.constant > 0 ? 0 : 120
        }, completion: nil)
    }
    
    @IBAction func annotateAction(_ sender: Any) {
        if count == 0 {
            self.pageControl.isHidden = false
            pdfView.removeGestureRecognizer(self.tapFestureRecognizer)
            self.pdfDrawingGestureRecognizer = APDrawingGestureRecognizer()
            pdfView.addGestureRecognizer(pdfDrawingGestureRecognizer)
            pdfDrawingGestureRecognizer.drawingDelegate = pdfDrawer
            count = 1
        } else {
            self.pageControl.isHidden = true
            pdfView.removeGestureRecognizer(self.pdfDrawingGestureRecognizer)
            self.tapFestureRecognizer = UITapGestureRecognizer()
            tapFestureRecognizer.addTarget(self, action: #selector(tappedAction))
            pdfView.addGestureRecognizer(tapFestureRecognizer)
            count = 0
        }
    }
    
    @IBAction func textAnnoateAction(_ sender: Any) {
        if count == 0 {
            self.pageControl.isHidden = false
            pdfView.removeGestureRecognizer(self.tapFestureRecognizer)
            self.pdfTextDrawingGestureRecognizer = APTextDrawingGestureRecognizer()
            pdfView.addGestureRecognizer(pdfTextDrawingGestureRecognizer)
            pdfTextDrawingGestureRecognizer.drawingDelegate = pdfTextDrawer
            count = 1
        } else {
            self.pageControl.isHidden = true
            pdfView.removeGestureRecognizer(self.pdfTextDrawingGestureRecognizer)
            self.tapFestureRecognizer = UITapGestureRecognizer()
            tapFestureRecognizer.addTarget(self, action: #selector(tappedAction))
            pdfView.addGestureRecognizer(tapFestureRecognizer)
            count = 0
        }
    }
    
    @IBAction func saveAction(_ sender: Any) {
        let path = Bundle.main.url(forResource: filePath, withExtension: "pdf")
        pdfView.document?.write(to: path!)
    }
    
    @IBAction func pageUpAction(_ sender: Any) {
        print("page up action")
        pdfView.goToPreviousPage(sender)
    }
    
    @IBAction func pageDownAction(_ sender: Any) {
        print("page down action")
        pdfView.goToNextPage(sender)
    }
    
    @IBAction func switchPenAction(_ sender: Any) {
        print("switchPenAction")
        self.pdfDrawer.drawingTool = .pencil
    }
    
    @IBAction func switchPenColor(_ sender: Any) {
        print("switchPenColor")
        self.pdfDrawer.color = .blue
    }
    
    @IBAction func backAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func outlineClickAction(_ sender: Any) {
        print("Click outline")
        self.topbarActionControl?.showOutlineTableForPFDDocument(for: self.pdfDocument, from: sender)
    }
    
    @IBAction func bookmarkAction(_ sender: Any) {
        print("Click bookmark")
        self.topbarActionControl?.showBookmarkTable(from: sender)
    }
    
    @IBAction func searchAction(_ sender: Any) {
        print("click search")
        self.topbarActionControl?.showSearchViewController(for: self.pdfDocument, from: sender)
    }
    
    func didSelectPdfOutline(_ pdfOutline: PDFOutline?) {
        if let pdfOutline = pdfOutline {
            self.pdfView.go(to: (pdfOutline.destination?.page)!)
        }
    }
    
    func didSelectPdfPageFromBookmark(_ pdfPage: PDFPage?) {
        if let page = pdfPage {
            self.pdfView.go(to: page)
        }
    }
    
    func didSelectPdfSelection(_ pdfSelection: PDFSelection?) {
        if let selection = pdfSelection {
            selection.color = .yellow
            self.pdfView.currentSelection = selection
            self.pdfView.go(to: selection)
        }
    }
}

