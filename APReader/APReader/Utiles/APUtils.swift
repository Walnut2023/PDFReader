//
//  APUtils.swift
//  APReader
//
//  Created by Tango on 2020/8/13.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit

func dateConvertString(date:Date, dateFormat:String="yyyy-MM-dd") -> String {
    let timeZone = TimeZone.init(identifier: "UTC")
    let formatter = DateFormatter()
    formatter.timeZone = timeZone
    formatter.locale = Locale.init(identifier: "zh_CN")
    formatter.dateFormat = dateFormat
    let date = formatter.string(from: date)
    return date.components(separatedBy: " ").first!
}

func checkFileExists(atPath path: String? = nil, fileName: String?) -> Bool {
    let fileManager = FileManager.default
    var filePath: String!
    if path != nil {
        filePath = NSHomeDirectory() + "/Library/Caches/APReader.OneDrive/File/\(path ?? "")/\(fileName ?? "")"
    } else {
        filePath = NSHomeDirectory() + "/Library/Caches/APReader.OneDrive/File/\(fileName ?? "")"
    }
    if fileManager.fileExists(atPath: filePath) {
        return true
    }
    return false
}
