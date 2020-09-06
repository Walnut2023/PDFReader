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
        case comment
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
    public var signatureImage: UIImage?
    
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
    private lazy var bookmarkBarButtonItem = UIBarButtonItem(image: UIImage.init(named: "bookmark"), style: .plain, target: self, action: #selector(bookmarkAction))
    private lazy var searchBarButtonItem = UIBarButtonItem(image: UIImage.init(named: "search"), style: .plain, target: self, action: #selector(searchAction))
    private lazy var undoBarButtonItem = UIBarButtonItem(image: UIImage.init(named: "undo"), style: .plain, target: self, action: #selector(undoAction))
    private lazy var redoBarButtonItem = UIBarButtonItem(image: UIImage.init(named: "redo"), style: .plain, target: self, action: #selector(redoAction))
    
    private lazy var tapGestureRecognizer = UITapGestureRecognizer()
    private lazy var pdfDrawingGestureRecognizer = APDrawingGestureRecognizer()
    private lazy var pdfTextDrawingGestureRecognizer = APTextDrawingGestureRecognizer()
    private lazy var pdfCommentDrawingGestureRecognizer = APCommentDrawingGestureRecognizer()
    
    private var toolbarActionControl: APPDFToolbarActionControl?
    private var editButtonClicked: Bool = false
    private var commentButtonClicked: Bool = false
    private var needUpload: Bool = false
    private var tappedOnComment: Bool = false
    private var count = 0
    private var timer: APRepeatingTimer?
    private var currentSelectedAnnotation: PDFAnnotation?
    
    private let pdfDrawer = APPDFDrawer()
    private let pdfTextDrawer = APPDFTextDrawer()
    private let pdfCommentDrawer = APPDFCommentDrawer()
    
    private var editingMode: EditingMode? = .pen
    private var editingColor: UIColor? = .red
    private var menuSelectLevel: MenuSelectLevel? = .root {
        didSet {
            updateBottomContainer()
        }
    }
    
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
    
    // MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupStates()
        setupPDFView()
        loadPdfFile()
        setupUI()
        registerNotification()
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
        
        guard let signatureImage = signatureImage, let page = pdfView.currentPage else { return }
        let pageBounds = page.bounds(for: .cropBox)
        let imageBounds = CGRect(x: pageBounds.midX, y: pageBounds.midY, width: 200, height: 100)
        let imageStamp = APImageStampAnnotation(with: signatureImage, forBounds: imageBounds, withProperties: nil)
        page.addAnnotation(imageStamp)
        registerNotification()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopTimer()
    }
    
    func registerNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(pdfViewPageChanged), name: .PDFViewPageChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(extractAnnotation(notification:)), name: .PDFViewAnnotationHit, object: nil)
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
        
        pageControl.isHidden = true
        toolbarActionControl = APPDFToolbarActionControl(pdfPreviewController: self)
        tapGestureRecognizer = UITapGestureRecognizer()
        tapGestureRecognizer.addTarget(self, action: #selector(tappedAction(sender:)))
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
    
    func updateLeftNavigationBarButtons() {
        switch menuSelectLevel {
        case .root:
            navigationItem.setLeftBarButtonItems([backBarButtonItem, outlineBarButtonItem, thumbnailBarButtonItem], animated: true)
            navigationItem.setRightBarButtonItems([bookmarkBarButtonItem, searchBarButtonItem], animated: true)
        case .middle, .final:
            navigationItem.setLeftBarButtonItems([cancelBarButtonItem], animated: true)
            navigationItem.setRightBarButtonItems([bookmarkBarButtonItem, searchBarButtonItem, redoBarButtonItem, undoBarButtonItem], animated: true)
        default:
            navigationItem.setLeftBarButtonItems([backBarButtonItem, outlineBarButtonItem, thumbnailBarButtonItem], animated: true)
        }
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
        pdfCommentDrawer.pdfView = pdfView
        
        pdfDrawer.delegate = self
        pdfTextDrawer.delegate = self
        pdfCommentDrawer.delegate = self
        
        undoBarButtonItem.isEnabled = pdfDrawer.changesManager.undoEnable
        redoBarButtonItem.isEnabled = pdfDrawer.changesManager.redoEnable
        
        let panAnnotationGesture = UIPanGestureRecognizer(target: self, action: #selector(didPanAnnotation(sender:)))
        pdfView.addGestureRecognizer(panAnnotationGesture)
    }
    
    private func loadPdfFile() {
        let pdfDocument = PDFDocument(url: self.getFileUrl()!)
        pdfView.document = pdfDocument
        self.pdfDocument = pdfDocument
    }
    
    // MARK: -  Action
    
    @objc func extractAnnotation(notification: Notification) {
        print("userInfo: \(notification.userInfo ?? [:])")
        if let note = notification.userInfo?["PDFAnnotationHit"] as? PDFAnnotation {
            print(note)
            if note.isKind(of: APCommentImageStampAnnotation.self) {
                print("click APCommentImageStampAnnotation")
                tappedOnComment = true
            } else if note.isKind(of: APImageStampAnnotation.self) {
                print("click APImageStampAnnotation")
            } else if note.isKind(of: APWidgetAnnotation.self) {
                print("click APWidgetAnnotation")
            } else {
                print("click APDrawingAnnotation")
            }
        }
    }
    
    @objc
    func tappedAction(sender: UITapGestureRecognizer) {
        print("tapped")
        if sender == pdfCommentDrawingGestureRecognizer { return }
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
    func didPanAnnotation(sender: UIPanGestureRecognizer) {
        let touchLocation = sender.location(in: pdfView)
        guard let page = pdfView.page(for: touchLocation, nearest: true) else {
            return
        }
        let locationOnPage = pdfView.convert(touchLocation, to: page)
        switch sender.state {
        case .began:
            guard let annotation = page.annotation(at: locationOnPage) else {
                return
            }
            if annotation.isKind(of: PDFAnnotation.self) {
                currentSelectedAnnotation = annotation
            }
        case .changed:
            guard let annotation = currentSelectedAnnotation else {
                return
            }
            let initialBounds = annotation.bounds
            annotation.bounds = CGRect(x: locationOnPage.x - (initialBounds.width / 2), y: locationOnPage.y - (initialBounds.height / 2), width: initialBounds.width, height: initialBounds.height)
            print("move to \(locationOnPage)")
            
        case .ended, .cancelled, .failed:
            currentSelectedAnnotation = nil
        default:
            break
        }
    }
    
    @objc
    func cancelAction(_ sender: Any) {
        if editButtonClicked && menuSelectLevel == .final {
            menuSelectLevel = .middle
            updateLeftNavigationBarButtons()
            pageControl.isHidden = true
            tittleLabelContainer.isHidden = false
            pdfView.removeGestureRecognizer(pdfDrawingGestureRecognizer)
            pdfView.removeGestureRecognizer(pdfTextDrawingGestureRecognizer)
            tapGestureRecognizer = UITapGestureRecognizer()
            tapGestureRecognizer.addTarget(self, action: #selector(tappedAction(sender:)))
            pdfView.addGestureRecognizer(tapGestureRecognizer)
            stopTimer()
            pdfDrawer.changesManager.clear()
            pdfDrawer.delegate?.pdfDrawerDidFinishDrawing()
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
    
    func commentAction(_ sender: UIButton) {
        print("commentAction tapped")
        commentButtonClicked = !commentButtonClicked
        if commentButtonClicked {
            editingMode = .comment
            pageControl.isHidden = false
            tittleLabelContainer.isHidden = true
            pdfView.removeGestureRecognizer(tapGestureRecognizer)
            pdfCommentDrawingGestureRecognizer = APCommentDrawingGestureRecognizer()
            pdfCommentDrawingGestureRecognizer.addTarget(self, action: #selector(shouldShowCommentViewController(sender:)))
            pdfView.addGestureRecognizer(pdfCommentDrawingGestureRecognizer)
            addTimer()
            edittorMenu.disableOtherButtons(sender)
            navigationItem.leftBarButtonItem?.isEnabled = false
        } else {
            editingMode = .pen
            pageControl.isHidden = true
            tittleLabelContainer.isHidden = false
            pdfView.removeGestureRecognizer(pdfCommentDrawingGestureRecognizer)
            tapGestureRecognizer = UITapGestureRecognizer()
            tapGestureRecognizer.addTarget(self, action: #selector(tappedAction(sender:)))
            pdfView.addGestureRecognizer(tapGestureRecognizer)
            stopTimer()
            edittorMenu.enableOtherButtons()
            pdfCommentDrawer.changesManager.clear()
            pdfCommentDrawer.delegate?.pdfCommentDrawerDidFinishDrawing()
            navigationItem.leftBarButtonItem?.isEnabled = true
        }
    }
    
    func showCommentViewController(complementionHanlder: @escaping (Bool, String) -> Void) {
        let storyBoard = UIStoryboard.init(name: "Main", bundle: nil)
        let commentContentVC: APCommentContentViewController = storyBoard.instantiateViewController(identifier: "CommentContentVC")
        commentContentVC.modalPresentationStyle = .fullScreen
        commentContentVC.actionHanlder = complementionHanlder
        present(commentContentVC, animated: true)
    }
    
    @objc
    func shouldShowCommentViewController(sender: UITapGestureRecognizer) {
        let location = sender.location(in: sender.view)
        guard let page = pdfView.page(for: location, nearest: true) else { return }
        let convertedPoint = pdfView.convert(location, to:page)
        showCommentViewController { (shouldAddAnnotation, testString) in
            if shouldAddAnnotation && !self.tappedOnComment {
                let imageBounds = CGRect(x: convertedPoint.x, y: convertedPoint.y, width: 44, height: 44)
                let imageStamp = APCommentImageStampAnnotation(forBounds: imageBounds, withProperties: nil)
                page.addAnnotation(imageStamp)
            } else {
                print("tapped on comment")
            }
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
        switch editingMode {
        case .comment:
            pdfCommentDrawer.undoAction()
        case .pen:
            pdfDrawer.undoAction()
        case .text:
            pdfTextDrawer.undoAction()
        default:
            print("undo action")
        }
    }
    
    @objc func redoAction() {
        print("redo action tapped")
        pdfDrawer.redoAction()
        switch editingMode {
        case .comment:
            pdfCommentDrawer.redoAction()
        case .pen:
            pdfDrawer.redoAction()
        case .text:
            pdfTextDrawer.redoAction()
        default:
            print("redo Action")
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
            edittorMenu.updateColorBtnColor(color)
        }
    }
    
    // MARK: - Notification Events
    
    @objc func pdfViewPageChanged(_ notification: Notification) {
        updatePageNumberLabel()
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
        undoBarButtonItem.isEnabled = pdfDrawer.changesManager.undoEnable
        redoBarButtonItem.isEnabled = pdfDrawer.changesManager.redoEnable
    }
}

extension APPreviewViewController: APPDFTextDrawerDelegate {
    func pdfTextDrawerDidFinishDrawing() {
        undoBarButtonItem.isEnabled = pdfTextDrawer.changesManager.undoEnable
        redoBarButtonItem.isEnabled = pdfTextDrawer.changesManager.redoEnable
    }
}

extension APPreviewViewController: APPDFCommentDrawerDelegate {
    func pdfCommentDrawerDidFinishDrawing() {
        undoBarButtonItem.isEnabled = pdfCommentDrawer.changesManager.undoEnable
        redoBarButtonItem.isEnabled = pdfCommentDrawer.changesManager.redoEnable
    }
}

extension APPreviewViewController: APPreviewBottomMenuDelegate {
    func didSelectComment() {
        print("didSelectComment")
        menuSelectLevel = .middle
        updateLeftNavigationBarButtons()
        addTimer()
    }
    
    func didSelectSignature() {
        print("didSelectSignature")
        let storyBoard = UIStoryboard.init(name: "Main", bundle: nil)
        let signatureVC: APSignatureViewController = storyBoard.instantiateViewController(identifier: "SignatureVC")
        signatureVC.previousViewController = self
        navigationController?.pushViewController(signatureVC, animated: true)
    }
}

extension APPreviewViewController: APPreviewEditorMenuDelegate {
    func didSelectTextEditAction(_ sender: UIButton) {
        let tag = sender.tag
        switch tag {
        case 2:
            pdfDrawer.addAnnotation(.highlight, markUpType: .highlight)
        case 3:
            pdfDrawer.addAnnotation(.underline, markUpType: .underline)
        case 4:
            pdfDrawer.addAnnotation(.strikeOut, markUpType: .strikeOut)
        default:
            print("HighLight")
        }
    }
    
    func didSelectCommentAction(_ sender: UIButton) {
        commentAction(sender)
    }
    
    func didSelectPenAction(_ sender: UIButton) {
        menuSelectLevel = .final
        editAction()
    }
    
    func didSelectColorInEditorMenu(_ sender: UIButton) {
        toolbarActionControl?.showColorPickerViewController(editingColor!, from: sender)
    }
}

extension APPreviewViewController: APPreviewPenToolMenuDelegate {
    func didSelectPenControl(_ selectedValue: DrawingTool) {
        pdfDrawer.drawingTool = selectedValue
    }
    
    func didSelectColorinPenTool(_ sender: UIButton) {
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
            penControlMenu.disableOtherButtons(sender)
            count = 1
            addTimer()
            navigationItem.leftBarButtonItem?.isEnabled = false
        } else {
            pdfTextDrawer.endEditing()
            editingMode = .pen
            pdfView.removeGestureRecognizer(pdfTextDrawingGestureRecognizer)
            tapGestureRecognizer = UITapGestureRecognizer()
            tapGestureRecognizer.addTarget(self, action: #selector(tappedAction(sender:)))
            pdfView.addGestureRecognizer(tapGestureRecognizer)
            sender.setImage(UIImage.init(named: "edit_begin"), for: .normal)
            penControlMenu.enableOtherButtons()
            count = 0
            pdfTextDrawer.changesManager.clear()
            pdfTextDrawer.delegate?.pdfTextDrawerDidFinishDrawing()
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
        switch editingMode {
        case .comment:
            if !pdfCommentDrawer.changesManager.undoEnable {
                return
            }
        case .text:
            if !pdfTextDrawer.changesManager.undoEnable {
                return
            }
        case .pen:
            if !pdfDrawer.changesManager.undoEnable {
                return
            }
        default:
            print("saving the changes")
        }
        
        print("\(Date()) savePDFDocument")
        let copyPdfDoc = pdfDocument!.copy() as! PDFDocument
        DispatchQueue.global(qos: .background).sync { [weak self] in
            if let data = copyPdfDoc.dataRepresentation() {
                try? data.write(to: (self?.getFileUrl())!, options: .atomicWrite)
            }
        }
    }
    
    func addTimer() {
        timer = APRepeatingTimer(timeInterval: 5)
        timer?.eventHandler = { [weak self] in
            print("\(Date()) timer running")
            self?.savePDFDocument()
        }
        timer?.resume()
    }
    
    func stopTimer() {
        timer?.suspend()
    }
}
