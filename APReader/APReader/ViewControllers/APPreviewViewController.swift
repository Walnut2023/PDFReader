//
//  APPreviewViewController.swift
//  APReader
//
//  Created by Tangos on 2020/7/25.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit
import PDFKit
import SVProgressHUD
import MSGraphClientModels

class APPreviewViewController: UIViewController {
    
    enum FileSourceType {
        case LOCAL
        case CLOUD
    }
    
    enum EditingMode {
        case pen
        case text
    }
    
    // menu select level
    enum MenuSelectLevel {
        case root
        case middle
        case final
    }
    
    public var filePath: String?
    public var pdfDocument: PDFDocument?
    public var driveItem: MSGraphDriveItem?
    public var fileSourceType: FileSourceType? = .CLOUD
    var editingMode: EditingMode? = .pen
    var editingColor: UIColor? = .red
    var menuSelectLevel: MenuSelectLevel? = .root {
        didSet {
            updateBottomContainer()
        }
    }
    
    @IBOutlet weak var pageNumberContainer: UIView!
    @IBOutlet weak var tittleLabelContainer: UIView!
    @IBOutlet weak var pageNumberLabel: UILabel!
    @IBOutlet weak var pdfTittleLabel: UILabel!
    @IBOutlet weak var pdfView: APNonSelectablePDFView!
    @IBOutlet weak var thumbnailView: PDFThumbnailView!
    @IBOutlet weak var thumbnailViewContainer: UIView!
    @IBOutlet weak var pageControl: UIView!
    @IBOutlet weak var bottomViewContainer: UIView!
    
    private lazy var backBarButtonItem = UIBarButtonItem(image: UIImage.init(named: "back"), style: .plain, target: self, action: #selector(backAction))
    private lazy var cancelBarButtonItem = UIBarButtonItem(image: UIImage.init(named: "cancelBtn"), style: .plain, target: self, action: #selector(cancelAction))
    private lazy var outlineBarButtonItem = UIBarButtonItem(image: UIImage.init(named: "outline"), style: .plain, target: self, action: #selector(outlineAction))
    private lazy var thumbnailBarButtonItem = UIBarButtonItem(image: UIImage.init(named: "thumbnail"), style: .plain, target: self, action: #selector(thunbnailAction))
    private lazy var editBarButtonItem = UIBarButtonItem(image: UIImage.init(named: "edit"), style: .plain, target: self, action: #selector(editAction))
    private lazy var edittingBarButtonItem = UIBarButtonItem(image: UIImage.init(named: "editing"), style: .plain, target: self, action: #selector(editAction))
    private lazy var bookmarkBarButtonItem = UIBarButtonItem(image: UIImage.init(named: "bookmark"), style: .plain, target: self, action: #selector(bookmarkAction))
    private lazy var searchBarButtonItem = UIBarButtonItem(image: UIImage.init(named: "search"), style: .plain, target: self, action: #selector(searchAction))
    private lazy var undoBarButtonItem = UIBarButtonItem(image: UIImage.init(named: "undo"), style: .plain, target: self, action: #selector(undoAction))
    private lazy var redoBarButtonItem = UIBarButtonItem(image: UIImage.init(named: "redo"), style: .plain, target: self, action: #selector(redoAction))
    
    private lazy var tapGestureRecognizer = UITapGestureRecognizer()
    private lazy var pdfDrawingGestureRecognizer = APDrawingGestureRecognizer()
    private lazy var pdfTextDrawingGestureRecognizer = APTextDrawingGestureRecognizer()
    
    private lazy var bottomMenu: APPreviewBottomMenu = {
        let bottomMenu = APPreviewBottomMenu.initInstanceFromXib()
        bottomMenu.frame.size.height = 54
        bottomMenu.frame.origin.x = bottomViewContainer.frame.origin.x
        bottomMenu.width = view.width
        bottomMenu.delegate = self
        return bottomMenu
    }()
    private lazy var edittorMenu: APPreviewEditorMenu = {
        let edittorMenu = APPreviewEditorMenu.initInstanceFromXib()
        edittorMenu.frame.size.height = 54
        edittorMenu.frame.origin.x = bottomViewContainer.frame.origin.x
        edittorMenu.width = view.width
        edittorMenu.delegate = self
        return edittorMenu
    }()
    private lazy var penControlMenu: APPreviewPenToolMenu = {
        let penControlMenu = APPreviewPenToolMenu.initInstanceFromXib()
        penControlMenu.frame.size.height = 54
        penControlMenu.frame.origin.x = bottomViewContainer.frame.origin.x
        penControlMenu.width = view.width
        penControlMenu.delegate = self
        return penControlMenu
    }()
    
    private var toolbarActionControl: APPDFToolbarActionControl?
    private var editButtonClicked: Bool = false
    private var needUpload: Bool = false
    
    private let pdfDrawer = APPDFDrawer()
    private let pdfTextDrawer = APPDFTextDrawer()
    
    private var count = 0
    
    private var timer: DispatchSourceTimer?
    
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
        return .slide
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        needUpload = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopTimer()
    }
    
    private func setupUI() {
        navigationController?.hidesBarsOnTap = false
        navigationItem.setLeftBarButtonItems([backBarButtonItem, outlineBarButtonItem, thumbnailBarButtonItem], animated: true)
        navigationItem.setRightBarButtonItems([bookmarkBarButtonItem, searchBarButtonItem], animated: true)
        if pdfDocument?.outlineRoot == nil {
            outlineBarButtonItem.isEnabled = false
        }
        pdfTittleLabel.text = pdfDocument?.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String ?? pdfDocument?.documentURL?.lastPathComponent
        
        updatePageNumberLabel()
        
        self.pageControl.isHidden = true
        self.toolbarActionControl = APPDFToolbarActionControl(pdfPreviewController: self)
        self.tapGestureRecognizer = UITapGestureRecognizer()
        tapGestureRecognizer.addTarget(self, action: #selector(tappedAction))
        pdfView.addGestureRecognizer(tapGestureRecognizer)
        setupBottomMenuContainer()
        menuSelectLevel = .root
    }
    
    func setupBottomMenuContainer() {
        bottomMenu = APPreviewBottomMenu.initInstanceFromXib()
        bottomMenu.frame.size.height = 54
        bottomMenu.frame.origin.x = bottomViewContainer.frame.origin.x
        bottomMenu.width = view.width
        bottomMenu.delegate = self

        edittorMenu = APPreviewEditorMenu.initInstanceFromXib()
        edittorMenu.frame.size.height = 54
        edittorMenu.frame.origin.x = bottomViewContainer.frame.origin.x
        edittorMenu.width = view.width
        edittorMenu.delegate = self
    }
    
    func updateBottomContainer() {
        var bottomView: UIView!
        for view in bottomViewContainer.subviews {
            view.removeFromSuperview()
        }
        switch menuSelectLevel {
        case .root:
            bottomView = bottomMenu
        case .middle:
            bottomView = edittorMenu
        case .final:
            bottomView = penControlMenu
        default:
            bottomView = bottomMenu
        }
        bottomViewContainer.addSubview(bottomView)
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
    
    private func setupPDFView() {
        pdfView.displayDirection = .horizontal
        pdfView.displayMode = .singlePage
        pdfView.usePageViewController(true)
        pdfView.pageBreakMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        pdfView.autoScales = true
        pdfView.backgroundColor = view.backgroundColor!
        
        thumbnailView.pdfView = pdfView
        thumbnailView.thumbnailSize = CGSize(width: 44, height: 54)
        thumbnailView.layoutMode = .horizontal
        thumbnailView.backgroundColor = thumbnailViewContainer.backgroundColor!
        thumbnailView.isHidden = true
        thumbnailViewContainer.isHidden = true
        
        pdfDrawer.pdfView = pdfView
        pdfTextDrawer.pdfView = pdfView
        
        pdfDrawer.delegate = self
        
        undoBarButtonItem.isEnabled = pdfDrawer.undoEnable
        redoBarButtonItem.isEnabled = pdfDrawer.redoEnable
    }
    
    private func loadPdfFile() {
        let pdfDocument = PDFDocument(url: self.getFileUrl()!)
        pdfView.document = pdfDocument
        self.pdfDocument = pdfDocument
    }
    
    // MARK: -  Action
    
    @objc
    func tappedAction() {
        print("tapped")
        UIView.transition(with: self.bottomViewContainer, duration: 0.25, options: .transitionCrossDissolve, animations: {
            self.navigationController?.setNavigationBarHidden(!(self.navigationController?.isNavigationBarHidden ?? false) , animated: true)
            self.bottomViewContainer.isHidden = !self.bottomViewContainer.isHidden
            self.pageNumberContainer.isHidden = !self.pageNumberContainer.isHidden
            self.tittleLabelContainer.isHidden = !self.tittleLabelContainer.isHidden
        }, completion: nil)
    }
    
    @objc
    func backAction(_ sender: Any) {
        stopTimer()
        if fileSourceType == .CLOUD {
            uploadPDFFileToOneDrive()
        }
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc
    func cancelAction(_ sender: Any) {
        if editButtonClicked && menuSelectLevel == .final {
            menuSelectLevel = .middle
            updateLeftNavigationBarButtons()
            navigationItem.setRightBarButtonItems([bookmarkBarButtonItem, searchBarButtonItem], animated: true)
            pageControl.isHidden = true
            tittleLabelContainer.isHidden = false
            pdfView.removeGestureRecognizer(pdfDrawingGestureRecognizer)
            pdfView.removeGestureRecognizer(pdfTextDrawingGestureRecognizer)
            tapGestureRecognizer = UITapGestureRecognizer()
            tapGestureRecognizer.addTarget(self, action: #selector(tappedAction))
            pdfView.addGestureRecognizer(tapGestureRecognizer)
            stopTimer()
            editButtonClicked = !editButtonClicked
        } else if menuSelectLevel == .final {
            menuSelectLevel = .middle
            updateLeftNavigationBarButtons()
        } else {
            menuSelectLevel = .root
            updateLeftNavigationBarButtons()
        }
    }
    
    @objc
    func outlineAction(_ sender: Any) {
        print("Click outline")
        toolbarActionControl?.showOutlineTableForPFDDocument(for: pdfDocument, from: sender)
    }
    
    @objc
    func thunbnailAction(_ sender: Any) {
        print("Click thumbnail")
        thumbnailViewContainer.isHidden = !thumbnailViewContainer.isHidden
        thumbnailView.isHidden = !thumbnailView.isHidden
        bottomViewContainer.isHidden = !bottomViewContainer.isHidden
    }
    
    @objc
    func editAction() {
        print("editAction tapped")
        editButtonClicked = !editButtonClicked
        if editButtonClicked {
            needUpload = true
            pageControl.isHidden = false
            tittleLabelContainer.isHidden = true
            menuSelectLevel = .final
            penControlMenu.initPenControl()
            pdfView.removeGestureRecognizer(tapGestureRecognizer)
            pdfDrawingGestureRecognizer = APDrawingGestureRecognizer()
            pdfView.addGestureRecognizer(pdfDrawingGestureRecognizer)
            pdfDrawingGestureRecognizer.drawingDelegate = pdfDrawer
            addTimer()
        }
    }
    
    func updateLeftNavigationBarButtons() {
        switch menuSelectLevel {
        case .root:
            navigationItem.setLeftBarButtonItems([backBarButtonItem, outlineBarButtonItem, thumbnailBarButtonItem], animated: true)
        case .middle:
            navigationItem.setLeftBarButtonItems([cancelBarButtonItem, outlineBarButtonItem, thumbnailBarButtonItem], animated: true)
        case .final:
            navigationItem.setLeftBarButtonItems([cancelBarButtonItem], animated: true)
            navigationItem.setRightBarButtonItems([bookmarkBarButtonItem, searchBarButtonItem, redoBarButtonItem, undoBarButtonItem], animated: true)
        default:
            navigationItem.setLeftBarButtonItems([backBarButtonItem, outlineBarButtonItem, thumbnailBarButtonItem], animated: true)
        }
    }
    
    @objc func bookmarkAction(_ sender: Any) {
        print("Click bookmark")
        toolbarActionControl?.showBookmarkTable(from: sender)
    }
    
    @objc func searchAction(_ sender: Any) {
        print("click search")
        toolbarActionControl?.showSearchViewController(for: self.pdfDocument, from: sender)
    }
    
    @objc func undoAction() {
        print("undo action tapped")
        pdfDrawer.undoAction()
    }
    
    @objc func redoAction() {
        print("redo action tapped")
        pdfDrawer.redoAction()
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
            pdfView.go(to: (pdfOutline.destination?.page)!)
        }
    }
    
    func didSelectPdfPageFromBookmark(_ pdfPage: PDFPage?) {
        if let page = pdfPage {
            pdfView.go(to: page)
        }
    }
    
    func didSelectPdfSelection(_ pdfSelection: PDFSelection?) {
        if let selection = pdfSelection {
            selection.color = .yellow
            pdfView.currentSelection = selection
            pdfView.go(to: selection)
        }
    }
    
    func didSelectColorInColorPicker(_ color: UIColor?) {
        if let color = color {
            if editingMode == .pen {
                pdfDrawer.color = color
            } else {
                pdfTextDrawer.color = color
            }
            editingColor = color
            penControlMenu.updateColorBtnColor(color)
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
    
    func getFileUrl() -> URL? {
        switch fileSourceType {
        case .LOCAL:
            guard let driveItem = driveItem else { return nil }
            return driveItem.localFolderFilePath()
        case .CLOUD:
            guard let driveItem = driveItem else { return nil }
            return driveItem.localFilePath()
        default:
            guard let driveItem = driveItem else { return nil }
            return driveItem.localFilePath()
        }
    }
    
    func updatePageNumberLabel() {
        guard let currentPage = pdfView.currentPage,
            let index = pdfView.document?.index(for: currentPage),
            let pageCount = pdfView.document?.pageCount else {
                pageNumberLabel.text = nil
                return
        }
        pageNumberLabel.text = "\(index + 1)/\(pageCount)"
    }
}

extension APPreviewViewController: APPDFDrawerDelegate {
    func pdfDrawerDidFinishDrawing() {
        undoBarButtonItem.isEnabled = pdfDrawer.undoEnable
        redoBarButtonItem.isEnabled = pdfDrawer.redoEnable
    }
}

extension APPreviewViewController: APPreviewBottomMenuDelegate {
    func didSelectComment() {
        print("didSelectComment")
        menuSelectLevel = .middle
        updateLeftNavigationBarButtons()
    }
    
    func didSelectInsertPage() {
        print("didSelectInsertPage")
    }
    
    func didSelectSignaure() {
        print("didSelectSignaure")
    }
}

extension APPreviewViewController: APPreviewEditorMenuDelegate {
    func didSelectCommentAction(_ sender: UIButton) {

    }
   
    func didSelectPenAction(_ sender: UIButton) {
        menuSelectLevel = .final
        updateLeftNavigationBarButtons()
        editAction()
    }
}

extension APPreviewViewController: APPreviewPenToolMenuDelegate {
    func didSelectPenControl(_ selectedValue: DrawingTool) {
        pdfDrawer.drawingTool = selectedValue
    }
    
    func didSelectColor(_ sender: UIButton) {
        toolbarActionControl?.showColorPickerViewController(editingColor!, from: sender)
    }
    
    func didSelectTextInputMode(_ sender: UIButton) {
        if count == 0 {
            editingMode = .text
            pdfView.removeGestureRecognizer(tapGestureRecognizer)
            pdfTextDrawingGestureRecognizer = APTextDrawingGestureRecognizer()
            pdfView.addGestureRecognizer(pdfTextDrawingGestureRecognizer)
            pdfTextDrawer.color = editingColor!
            pdfTextDrawingGestureRecognizer.drawingDelegate = pdfTextDrawer
            sender.setImage(UIImage.init(named: "edit_done"), for: .normal)
            penControlMenu.disableOtherButtons()
            count = 1
            addTimer()
            navigationItem.leftBarButtonItem?.isEnabled = false
        } else {
            pdfTextDrawer.endEditing()
            editingMode = .pen
            pdfView.removeGestureRecognizer(pdfTextDrawingGestureRecognizer)
            tapGestureRecognizer = UITapGestureRecognizer()
            tapGestureRecognizer.addTarget(self, action: #selector(tappedAction))
            pdfView.addGestureRecognizer(tapGestureRecognizer)
            sender.setImage(UIImage.init(named: "edit_begin"), for: .normal)
            penControlMenu.enableOtherButtons()
            count = 0
            stopTimer()
            navigationItem.leftBarButtonItem?.isEnabled = true
        }
    }
}

// MARK: - Auto Saving

extension APPreviewViewController {
    func uploadPDFFileToOneDrive() {
        guard let selectedFileName = filePath, needUpload == true  else {
            return
        }
        SVProgressHUD.showInfo(withStatus: "Uploading to OneDrive")
        APOneDriveManager.instance.createUploadSession(filePath: driveItem?.fileItemShortRelativePath(), fileName: selectedFileName, completion: { (result: OneDriveManagerResult, uploadUrl, expirationDateTime, nextExpectedRanges) -> Void in
            switch(result) {
            case .Success:
                print("success on creating session (\(String(describing: uploadUrl)) (\(String(describing: expirationDateTime))")
                APOneDriveManager.instance.uploadPDFBytes(driveItem: self.driveItem!, uploadUrl: uploadUrl!, completion: { (result: OneDriveManagerResult, webUrl, fileId) -> Void in
                    switch(result) {
                    case .Success:
                        print ("Web Url of file \(String(describing: webUrl))")
                        print ("FileId of file \(String(describing: fileId))")
                        SVProgressHUD.showInfo(withStatus: "Upload Succeed")
                    case .Failure(let error):
                        print("\(error)")
                        SVProgressHUD.showInfo(withStatus: "Upload Failed")
                    }
                })
            case .Failure(let error):
                print("\(error)")
            }
        })
    }
    
    func savePDFDocument() {
        print("\(Date()) savePDFDocument")
        let copyPdfDoc = pdfDocument!.copy() as! PDFDocument
        DispatchQueue.global(qos: .background).sync { [weak self] in
            if let data = copyPdfDoc.dataRepresentation() {
                try? data.write(to: (self?.getFileUrl())!, options: .atomicWrite)
            }
        }
    }
    
    func addTimer() {
        if timer == nil {
            timer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.global())
            timer?.schedule(deadline: .now() + .seconds(5), repeating: DispatchTimeInterval.seconds(4), leeway: DispatchTimeInterval.seconds(0))
            timer?.setEventHandler { [weak self] in
                print("\(Date()) timer running")
                self?.savePDFDocument()
            }
        } else {
            timer!.resume()
        }
    }
    
    func stopTimer() {
        timer?.suspend()
    }
    
    func cancelTimer() {
        guard let t = timer else {
            return
        }
        t.cancel()
        timer = nil
    }
}
