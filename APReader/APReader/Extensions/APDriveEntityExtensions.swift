//
//  APDriveEntityExtensions.swift
//  APReader
//
//  Created by Tango on 2020/8/13.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import MSGraphClientModels

extension MSGraphDriveItem {
    func graphDownloadUrl() -> String? {
        return self.getDictionary()?["@microsoft.graph.downloadUrl"] as? String
    }
    
    func lastModifiedTimeString() -> String? {
        return dateConvertString(date: self.lastModifiedDateTime, dateFormat: "MM-dd")
    }
}
