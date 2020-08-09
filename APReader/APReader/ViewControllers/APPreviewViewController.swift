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
    
    enum EditingMode {
        case pen
        case text
    }
    
    public var filePath: String?
    public var pdfDocument: PDFDocument?
    var editingMode: EditingMode? = .pen
    var editingColor: UIColor? = .red

    @IBOutlet weak var pageNumberContainer: UIView!
    @IBOutlet weak var tittleLabelContainer: UIView!
    @IBOutlet weak var pageNumberLabel: UILabel!
    @IBOutlet weak var pdfTittleLabel: UILabel!
    @IBOutlet weak var pdfView: APNonSelectablePDFView!
    @IBOutlet weak var thumbnailView: PDFThumbnailView!
    @IBOutlet weak var thumbnailViewContainer: UIView!
    @IBOutlet weak var pageControl: UIView!
    @IBOutlet weak var toolContainer: UIView!
        
    @IBOutlet weak var pencilBtn: UIButton!
    @IBOutlet weak var penBtn: UIButton!
    @IBOutlet weak var paintBtn: UIButton!
    @IBOutlet weak var eraserBtn: UIButton!
    @IBOutlet weak var colorBtn: UIButton!
    @IBOutlet weak var moreBtn: UIButton!
    
    private lazy var backBarButtonItem = UIBarButtonItem(image: UIImage.init(named: "arrow_back"), style: .plain, target: self, action: #selector(backAction))
    private lazy var outlineBarButtonItem = UIBarButtonItem(image: UIImage.init(named: "outline"), style: .plain, target: self, action: #selector(outlineAction))
    private lazy var editBarButtonItem = UIBarButtonItem(image: UIImage.init(named: "edit"), style: .plain, target: self, action: #selector(editAction))
    private lazy var edittingBarButtonItem = UIBarButtonItem(image: UIImage.init(named: "editing"), style: .plain, target: self, action: #selector(editAction))
    private lazy var bookmarkBarButtonItem = UIBarButtonItem(image: UIImage.init(named: "bookmark"), style: .plain, target: self, action: #selector(bookmarkAction))
    private lazy var searchBarButtonItem = UIBarButtonItem(image: UIImage.init(named: "search"), style: .plain, target: self, action: #selector(searchAction))
    private lazy var undoBarButtonItem = UIBarButtonItem(image: UIImage.init(named: "undo"), style: .plain, target: self, action: #selector(undoAction))
    private lazy var redoBarButtonItem = UIBarButtonItem(image: UIImage.init(named: "redo"), style: .plain, target: self, action: #selector(redoAction))

    private lazy var tapGestureRecognizer = UITapGestureRecognizer()
    private lazy var pdfDrawingGestureRecognizer = APDrawingGestureRecognizer()
    private lazy var pdfTextDrawingGestureRecognizer = APTextDrawingGestureRecognizer()
    
    private var toolbarActionControl: APPDFToolbarActionControl?
    private var penControl: APPencilControl?
    private var editButtonClicked: Bool = false
    
    private let pdfDrawer = APPDFDrawer()
    private let pdfTextDrawer = APPDFTextDrawer()
    
    private var count = 0
    
    // MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupStates()
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
        
        setupPenControl()
        updatePageNumberLabel()

        self.pageControl.isHidden = true
        self.toolContainer.isHidden = true
        self.toolbarActionControl = APPDFToolbarActionControl(pdfPreviewController: self)
        self.tapGestureRecognizer = UITapGestureRecognizer()
        tapGestureRecognizer.addTarget(self, action: #selector(tappedAction))
        pdfView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    func setupStates() {
        switch editingMode {
        case .pen:
            editingColor = pdfDrawer.color
        case .text:
            editingColor = pdfTextDrawer.color
        default:
            editingColor = pdfDrawer.color
        }
    }
    
    func setupEvents() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(pdfViewPageChanged),
                                               name: .PDFViewPageChanged,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(orientationChanged),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object:nil)
    }
    
    func setupPenControl() {
        penControl = APPencilControl(buttonsArray: [penBtn, pencilBtn, paintBtn, eraserBtn])
        penControl?.defaultButton = pencilBtn
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
        
        pdfDrawer.delegate = self
        
        undoBarButtonItem.isEnabled = pdfDrawer.undoEnable
        redoBarButtonItem.isEnabled = pdfDrawer.redoEnable
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
        self.toolbarActionControl?.showOutlineTableForPFDDocument(for: self.pdfDocument, from: sender)
    }

    @objc func editAction() {
        print("editAction tapped")
        editButtonClicked = !editButtonClicked
        if editButtonClicked {
            navigationItem.setLeftBarButtonItems([backBarButtonItem], animated: true)
            navigationItem.setRightBarButtonItems([bookmarkBarButtonItem, searchBarButtonItem, edittingBarButtonItem, redoBarButtonItem, undoBarButtonItem], animated: true)
            
            self.thumbnailViewContainer.isHidden = true
            self.pageControl.isHidden = false
            self.toolContainer.isHidden = false
            self.tittleLabelContainer.isHidden = true
            pdfView.removeGestureRecognizer(self.tapGestureRecognizer)
            self.pdfDrawingGestureRecognizer = APDrawingGestureRecognizer()
            pdfView.addGestureRecognizer(pdfDrawingGestureRecognizer)
            pdfDrawingGestureRecognizer.drawingDelegate = pdfDrawer
        } else {
            navigationItem.setLeftBarButtonItems([backBarButtonItem, outlineBarButtonItem], animated: true)
            navigationItem.setRightBarButtonItems([bookmarkBarButtonItem, searchBarButtonItem, editBarButtonItem], animated: true)
            
            thumbnailViewContainer.isHidden = false
            self.pageControl.isHidden = true
            self.toolContainer.isHidden = true
            self.tittleLabelContainer.isHidden = false
            pdfView.removeGestureRecognizer(pdfDrawingGestureRecognizer)
            pdfView.removeGestureRecognizer(pdfTextDrawingGestureRecognizer)
            self.tapGestureRecognizer = UITapGestureRecognizer()
            tapGestureRecognizer.addTarget(self, action: #selector(tappedAction))
            pdfView.addGestureRecognizer(tapGestureRecognizer)
            
            savePDFDocument()
        }
    }
    
    @objc func bookmarkAction(_ sender: Any) {
        print("Click bookmark")
        self.toolbarActionControl?.showBookmarkTable(from: sender)
    }
    
    @objc func searchAction(_ sender: Any) {
        print("click search")
        self.toolbarActionControl?.showSearchViewController(for: self.pdfDocument, from: sender)
    }
    
    @objc func undoAction() {
        print("undo action tapped")
        pdfDrawer.undoAction()
    }
    
    @objc func redoAction() {
        print("redo action tapped")
        pdfDrawer.redoAction()
    }
    
    @IBAction func penControlClicked(_ sender: UIButton) {
        print("penControlClicked")
        penControl?.buttonArrayUpdated(buttonSelected: sender)
        self.pdfDrawer.drawingTool = penControl!.selectedValue
    }
    
    @IBAction func colorBtnClicked(_ sender: Any) {
        print("colorBtnClicked")
        self.toolbarActionControl?.showColorPickerViewController(editingColor!, from: sender)
    }
    
    @IBAction func moreBtnClicked(_ sender: Any) {
        print("moreBtnClicked")
        if count == 0 {
            editingMode = .text
            pdfView.removeGestureRecognizer(self.tapGestureRecognizer)
            pdfTextDrawingGestureRecognizer = APTextDrawingGestureRecognizer()
            pdfView.addGestureRecognizer(pdfTextDrawingGestureRecognizer)
            pdfTextDrawer.color = editingColor!
            pdfTextDrawingGestureRecognizer.drawingDelegate = pdfTextDrawer
            moreBtn.setTitle("Done", for: .normal)
            moreBtn.setTitleColor(.systemBlue, for: .normal)
            penControl?.disableButtonArray()
            count = 1
        } else {
            pdfTextDrawer.endEditing()
            editingMode = .pen
            pdfView.removeGestureRecognizer(self.pdfTextDrawingGestureRecognizer)
            tapGestureRecognizer = UITapGestureRecognizer()
            tapGestureRecognizer.addTarget(self, action: #selector(tappedAction))
            pdfView.addGestureRecognizer(tapGestureRecognizer)
            moreBtn.setTitle("Text", for: .normal)
            moreBtn.setTitleColor(.systemBlue, for: .normal)
            penControl?.enableButtonArray()
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
    
    func didSelectColor(_ color: UIColor?) {
        if let color = color {
            if editingMode == .pen {
                self.pdfDrawer.color = color
            } else {
                self.pdfTextDrawer.color = color
            }
            editingColor = color
            self.colorBtn.backgroundColor = color
        }
    }
    
    // MARK: - Notification Events
    @objc func pdfViewPageChanged(_ notification: Notification) {
        updatePageNumberLabel()
    }
    
    @objc func orientationChanged(_ notification: Notification) {
        let device = UIDevice.current
        switch device.orientation {
        case .portrait:
            print("portrait")
        case .portraitUpsideDown:
            print("portraitUpsideDown")
        case .landscapeLeft:
            print("landscapeLeft")
        case.landscapeRight:
            print("landscapeRight")
        default:
            print("unknown")
        }
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
    
    func savePDFDocument() {
        let path = Bundle.main.url(forResource: filePath, withExtension: "pdf")
        pdfView.document?.write(to: path!)
    }
}

extension APPreviewViewController: APPDFDrawerDelegate {
    func pdfDrawerDidFinishDrawing() {
        undoBarButtonItem.isEnabled = pdfDrawer.undoEnable
        redoBarButtonItem.isEnabled = pdfDrawer.redoEnable
    }
}
