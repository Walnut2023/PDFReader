//
//  APAddFolderAlertViewController.swift
//  APReader
//
//  Created by Tango on 2020/8/31.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit

protocol APAddFolderControllerDelegate: class {
    func didTapCreateNewFolder(_ folderName: String)
}

final class APAddFolderAlertViewController: UIViewController {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var folderNameLabel: UILabel!
    @IBOutlet weak var folderAlertLabel: UILabel!
    @IBOutlet weak var folderNameTextField: UITextField!
    @IBOutlet weak var createFolderButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    weak var delegate: APAddFolderControllerDelegate?
    
    var canUseSecureLock = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupButton()
        setContainer()
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissAlertController)))
        containerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleContainerTap)))
        registerNotifications()
    }
    
    deinit {
        print("add folder is deinitiing...")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLayoutSubviews() {
        layoutContainer()
    }
    
    @objc private func handleContainerTap() {
        view.endEditing(true)
    }
    
    @objc
    func dismissAlertController() {
        dismiss(animated: true, completion: nil)
    }
    
    func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc
    func handleKeyboardWillShow(_ notification: NSNotification) {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseInOut, animations: { [unowned self] in
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    @objc
    func handleKeyboardWillHide(_ notification: NSNotification) {
        view.layoutIfNeeded()
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseInOut, animations: { [unowned self] in
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
    
    @IBAction func createFolderTapped(_ sender: Any) {
        guard let inputText = folderNameTextField.text else { return }
        if inputText.isEmpty {
            folderNameTextField.shake()
            createAlertAnimation(message: "Please Enter Folder Name")
        } else if inputText.contains(".") {
            folderNameTextField.shake()
            createAlertAnimation(message: "Cannot Create Folder Contain '.' ")
        } else {
            delegate?.didTapCreateNewFolder(inputText)
            dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

extension APAddFolderAlertViewController {
    private func createAlertAnimation(message: String) {
        self.folderAlertLabel.isHidden = false
        self.folderAlertLabel.text = message
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseIn, animations: {
            self.folderAlertLabel.alpha = 1
        }, completion: { _ in
            UIView.animate(withDuration: 0.8, delay: 1, options: .curveEaseIn, animations: {
                self.folderAlertLabel.alpha = 0
            }, completion: nil)
        })
    }
}

extension APAddFolderAlertViewController {
    func setupButton() {
        createFolderButton.layer.cornerRadius = 4
        createFolderButton.clipsToBounds = true
        
        cancelButton.layer.borderWidth = 1
        cancelButton.layer.borderColor = UIColor.systemBlue.cgColor
        cancelButton.layer.cornerRadius = 4
        cancelButton.clipsToBounds = true
    }
    
    func setContainer() {
        let shape = CAShapeLayer()
        shape.fillColor = UIColor.white.cgColor
        containerView.backgroundColor = .clear
        containerView.layer.insertSublayer(shape, at: 0)
        
        folderAlertLabel.isHidden = true
    }
}

extension APAddFolderAlertViewController {
    func layoutContainer() {
        let path = UIBezierPath(roundedRect: containerView.bounds, cornerRadius: 10)
        let layer = containerView.layer.sublayers!.first as! CAShapeLayer
        layer.path = path.cgPath
    }
}
