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

    
    @IBOutlet weak var pageNumberContainer: UIView!
    @IBOutlet weak var tittleLabelContainer: UIView!
    @IBOutlet weak var pageNumberLabel: UILabel!
    @IBOutlet weak var pdfTittleLabel: UILabel!
    @IBOutlet weak var pdfView: APNonSelectablePDFView!
    @IBOutlet weak var thumbnailView: PDFThumbnailView!
    @IBOutlet weak var thumbnailViewContainer: UIView!
    @IBOutlet weak var pageControl: UIView!
    @IBOutlet weak var toolContainer: UIView!
        
    private lazy var backBarButtonItem = UIBarButtonItem(image: UIImage.init(named: "arrow_back"), style: .plain, target: self, action: #selector(backAction))
    private lazy var outlineBarButtonItem = UIBarButtonItem(image: UIImage.init(named: "outline"), style: .plain, target: self, action: #selector(outlineAction))
    private lazy var editBarButtonItem = UIBarButtonItem(image: UIImage.init(named: "edit"), style: .plain, target: self, action: #selector(editAction))
    private lazy var edittingBarButtonItem = UIBarButtonItem(image: UIImage.init(named: "editing"), style: .plain, target: self, action: #selector(editAction))
    private lazy var bookmarkBarButtonItem = UIBarButtonItem(image: UIImage.init(named: "bookmark"), style: .plain, target: self, action: #selector(bookmarkAction))
    private lazy var searchBarButtonItem = UIBarButtonItem(image: UIImage.init(named: "search"), style: .plain, target: self, action: #selector(searchAction))
    private lazy var undoPreviousBarButtonItem = UIBarButtonItem(image: UIImage.init(named: "undopre"), style: .plain, target: self, action: #selector(undoLastAction))
    private lazy var undoNextBarButtonItem = UIBarButtonItem(image: UIImage.init(named: "undonext"), style: .plain, target: self, action: #selector(undoNextAction))

    private lazy var tapFestureRecognizer = UITapGestureRecognizer()
    private lazy var pdfDrawingGestureRecognizer = APDrawingGestureRecognizer()
    private lazy var pdfTextDrawingGestureRecognizer = APTextDrawingGestureRecognizer()
    
    private var topbarActionControl: APPDFToolbarActionControl?
    private var editButtonClicked: Bool = false
    
    private let pdfDrawer = APPDFDrawer()
    private let pdfTextDrawer = APPDFTextDrawer()
    
    private var count = 0
    
    // MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupEvents()
        setupPDFView()
        loadPdfFile()
        setupUI()
    }
    
    override var prefersStatusBarHidden: Bool {
        if editButtonClicked {
            return false
        } else {
            return navigationController?.isNavigationBarHidden == true
        }
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return UIStatusBarAnimation.slide
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    private func setupUI() {
        navigationController?.hidesBarsOnTap = false

        navigationItem.setLeftBarButtonItems([backBarButtonItem, outlineBarButtonItem], animated: true)
        navigationItem.setRightBarButtonItems([bookmarkBarButtonItem, searchBarButtonItem, editBarButtonItem], animated: true)
        
        pdfTittleLabel.text = pdfDocument?.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String ?? pdfDocument?.documentURL?.lastPathComponent
        
        updatePageNumberLabel()

        self.pageControl.isHidden = true
        self.toolContainer.isHidden = true
        self.topbarActionControl = APPDFToolbarActionControl(pdfPreviewController: self)
        self.tapFestureRecognizer = UITapGestureRecognizer()
        tapFestureRecognizer.addTarget(self, action: #selector(tappedAction))
        pdfView.addGestureRecognizer(tapFestureRecognizer)
    }
    
    func setupEvents() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(pdfViewPageChanged),
                                               name: .PDFViewPageChanged,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(pdfViewPageChanged),
                                               name: .PDFViewSelectionChanged,
                                               object: nil)
        
    }
    
    private func setupPDFView() {
        pdfView.displayDirection = .horizontal
        pdfView.usePageViewController(true)
        pdfView.pageBreakMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        pdfView.autoScales = true
        pdfView.backgroundColor = view.backgroundColor!
        
        thumbnailView.pdfView = pdfView
        thumbnailView.thumbnailSize = CGSize(width: 100, height: 100)
        thumbnailView.layoutMode = .horizontal
        thumbnailView.backgroundColor = thumbnailViewContainer.backgroundColor!
                
        pdfDrawer.pdfView = pdfView
        pdfTextDrawer.pdfView = pdfView
    }
    
    private func loadPdfFile() {
        let fileURL = Bundle.main.url(forResource: filePath, withExtension: "pdf")!
        let pdfDocument = PDFDocument(url: fileURL)
        pdfView.document = pdfDocument
        self.pdfDocument = pdfDocument
    }
    
    // MARK: -  Action
    
    @objc func tappedAction() {
        print("tapped")
        UIView.transition(with: self.thumbnailViewContainer, duration: 0.25, options: .transitionCrossDissolve, animations: {
            self.navigationController?.setNavigationBarHidden(!(self.navigationController?.isNavigationBarHidden ?? false) , animated: true)
            self.thumbnailView.isHidden = !self.thumbnailView.isHidden
            self.thumbnailViewContainer.isHidden = !self.thumbnailViewContainer.isHidden
            self.pageNumberContainer.isHidden = !self.pageNumberContainer.isHidden
            self.tittleLabelContainer.isHidden = !self.tittleLabelContainer.isHidden
        }, completion: nil)
    }
    
    @objc func backAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func outlineAction(_ sender: Any) {
        print("Click outline")
        self.topbarActionControl?.showOutlineTableForPFDDocument(for: self.pdfDocument, from: sender)
    }

    @objc func editAction() {
        print("editAction tapped")
        editButtonClicked = !editButtonClicked
        if editButtonClicked {
            navigationItem.setLeftBarButtonItems([backBarButtonItem], animated: true)
            navigationItem.setRightBarButtonItems([bookmarkBarButtonItem, searchBarButtonItem, edittingBarButtonItem, undoNextBarButtonItem, undoPreviousBarButtonItem], animated: true)
            
            self.thumbnailViewContainer.isHidden = true
            self.pageControl.isHidden = false
            self.toolContainer.isHidden = false
            pdfView.removeGestureRecognizer(self.tapFestureRecognizer)
            self.pdfDrawingGestureRecognizer = APDrawingGestureRecognizer()
            pdfView.addGestureRecognizer(pdfDrawingGestureRecognizer)
            pdfDrawingGestureRecognizer.drawingDelegate = pdfDrawer

        } else {
            navigationItem.setLeftBarButtonItems([backBarButtonItem, outlineBarButtonItem], animated: true)
            navigationItem.setRightBarButtonItems([bookmarkBarButtonItem, searchBarButtonItem, editBarButtonItem], animated: true)
            
            self.thumbnailViewContainer.isHidden = false
            self.pageControl.isHidden = true
            self.toolContainer.isHidden = true
            pdfView.removeGestureRecognizer(self.pdfDrawingGestureRecognizer)
            self.tapFestureRecognizer = UITapGestureRecognizer()
            tapFestureRecognizer.addTarget(self, action: #selector(tappedAction))
            pdfView.addGestureRecognizer(tapFestureRecognizer)
        }
    }
    
    @objc func bookmarkAction(_ sender: Any) {
        print("Click bookmark")
        self.topbarActionControl?.showBookmarkTable(from: sender)
    }
    
    @objc func searchAction(_ sender: Any) {
        print("click search")
        self.topbarActionControl?.showSearchViewController(for: self.pdfDocument, from: sender)
    }
    
    @objc func undoLastAction() {
        print("redo last action tapped")
    }
    
    @objc func undoNextAction() {
        print("redo next action tapped")
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
    
    // MARK: - Notification Events
    @objc func pdfViewPageChanged(_ notification: Notification) {
        updatePageNumberLabel()
    }
    
    func updatePageNumberLabel() {
        guard let currentPage = pdfView.visiblePages.first,
            let index = pdfDocument?.index(for: currentPage),
            let pageCount = pdfDocument?.pageCount else {
                pageNumberLabel.text = nil
                return
        }

        if pdfView.displayMode == .singlePage || pdfView.displayMode == .singlePageContinuous {
            pageNumberLabel.text = String("\(index + 1)/\(pageCount)")
        }
    }
}
