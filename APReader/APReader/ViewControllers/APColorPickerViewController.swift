//
//  APColorPickerViewController.swift
//  APReader
//
//  Created by Tango on 2020/8/8.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit

protocol APColorPickerViewControllerDelegate: AnyObject {
    func colorPickerDidSelectColor(color: UIColor)
}

class APColorPickerViewController: UIViewController {

    weak var delegate: APColorPickerViewControllerDelegate?
    var colorPicker: ChromaColorPicker!
    var selectedColor: UIColor?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Select Color"
        view.backgroundColor = .white
        
        setupColorPickerView()
    }
    
    func setupColorPickerView() {
        colorPicker = ChromaColorPicker()
        colorPicker.delegate = self
        colorPicker.padding = 10
        colorPicker.stroke = 3
        colorPicker.currentColor = selectedColor ?? .red
        view.addSubview(colorPicker)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard colorPicker.frame.width != view.bounds.width * 0.8 else { return }
        colorPicker.translatesAutoresizingMaskIntoConstraints = false
        colorPicker.centerXAnchor.constraint(equalToSystemSpacingAfter: view.centerXAnchor,
                                             multiplier: 1).isActive = true
        colorPicker.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        colorPicker.widthAnchor.constraint(equalToConstant: view.bounds.width * 0.8).isActive = true
        colorPicker.heightAnchor.constraint(equalToConstant: view.bounds.width * 0.8).isActive = true

        navigationController?.preferredContentSize = CGSize(width: 0, height: view.bounds.width * 0.8)
        
    }
}

extension APColorPickerViewController: ChromaColorPickerDelegate {
    func colorPickerDidChooseColor(_ colorPicker: ChromaColorPicker, color: UIColor) {
        self.delegate?.colorPickerDidSelectColor(color: color)
    }
}
