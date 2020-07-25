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
    
    @IBOutlet weak var pdfView: PDFView!
    @IBOutlet weak var thumbnailView: PDFThumbnailView!
    @IBOutlet weak var thumbnailViewContainer: UIView!
    @IBOutlet weak var editBtn: UIButton!
    
    private lazy var tapFestureRecognizer = UITapGestureRecognizer()
    private lazy var pdfDrawingGestureRecognizer = APDrawingGestureRecognizer()
    
    private let pdfDrawer = APPDFDrawer()
    
    private var count = 0
    
    // MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupPDFView()
        loadPdfFile()
    }
    
    private func setupUI() {
        self.editBtn.isHidden = true
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
    }
    
    @IBAction func updateDrawingAction(_ sender: Any) {
        if count == 0 {
            pdfView.removeGestureRecognizer(self.tapFestureRecognizer)
            self.pdfDrawingGestureRecognizer = APDrawingGestureRecognizer()
            pdfView.addGestureRecognizer(pdfDrawingGestureRecognizer)
            pdfDrawingGestureRecognizer.drawingDelegate = pdfDrawer
            count = 1
        } else {
            pdfView.removeGestureRecognizer(self.pdfDrawingGestureRecognizer)
            self.tapFestureRecognizer = UITapGestureRecognizer()
            tapFestureRecognizer.addTarget(self, action: #selector(tappedAction))
            pdfView.addGestureRecognizer(tapFestureRecognizer)
            count = 0
        } 
    }
    
    private func updateTapGesture() {
        pdfView.removeGestureRecognizer(self.pdfDrawingGestureRecognizer)
        self.tapFestureRecognizer = UITapGestureRecognizer()
        tapFestureRecognizer.addTarget(self, action: #selector(tappedAction))
        pdfView.addGestureRecognizer(tapFestureRecognizer)
    }
    
    private func loadPdfFile() {
        let fileURL = Bundle.main.url(forResource: filePath, withExtension: "pdf")!
        let pdfDocument = PDFDocument(url: fileURL)
        pdfView.document = pdfDocument
    }
    
    // MARK: -  Action
    // FIXME: view shake
    
    @objc func tappedAction() {
        print("tapped")
        if self.navigationController?.navigationBar.isHidden ?? false {
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            self.editBtn.isHidden = true
        } else {
            self.navigationController?.setNavigationBarHidden(true, animated: true)
            self.editBtn.isHidden = false
        }
    }
    
}
