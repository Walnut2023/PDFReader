//
//  APCloudManager.swift
//  APReader
//
//  Created by Tango on 2020/8/20.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit

class APCloudManager {

    public static func iCouldEnable() -> Bool {
        let url = FileManager.default.url(forUbiquityContainerIdentifier: nil)
        if url != nil {
            return true
        } else {
            return false
        }
        
    }
    
    public static func downloadFile(forDocumentUrl url: URL, completion: ((Data) -> Void)? = nil) {
        let document = APPDFDocument.init(fileURL: url)
        document.open { (success) in
            if success {
                document.close(completionHandler: nil)
            }
            if let callback = completion {
                callback(document.data)
            }
        }
    }
}

class APPDFDocument: UIDocument {
    public var data = Data.init()
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        self.data = contents as! Data
    }
}
