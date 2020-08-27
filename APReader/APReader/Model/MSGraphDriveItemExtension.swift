//
//  MSGraphDriveItemExtension.swift
//  APReader
//
//  Created by Tango on 2020/8/21.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit
import MSGraphClientModels

extension MSGraphDriveItem {
    func fileItemShortRelativePath() -> String? {
        if self.parentReference?.path?.count ?? 0 <= 13 {
            return ""
        } else {
            let pathString = self.parentReference?.path
            return self.parentReference?.path?.subString(13, pathString?.count ?? 0 - 13).appending("/")
        }
    }
    
    func folderItemShortRelativePath() -> String? {
        guard let _ = self.folder else { return nil }
        if self.parentReference?.path?.count ?? 0 <= 13 {
            return name
        } else {
            let pathString = self.parentReference?.path
            return self.parentReference?.path?.subString(13, pathString?.count ?? 0 - 13).appending("/\(self.name ?? "")")
        }
    }
    
    func tmpLocalFilePath() -> URL {
        let fileManager = FileManager.default
        let docsurl = try! fileManager.url(
            for: .cachesDirectory, in: .userDomainMask,
            appropriateFor: nil, create: true)
        return docsurl.appendingPathComponent("APReader.OneDrive/File/\(self.name ?? "")")
    }
    
    func tmpLocalFolderPath() -> URL {
        let fileManager = FileManager.default
        let docsurl = try! fileManager.url(
            for: .cachesDirectory, in: .userDomainMask,
            appropriateFor: nil, create: true)
        return docsurl.appendingPathComponent("APReader.OneDrive/File/")
    }
    
    func localFolderPath() -> URL {
        let fileManager = FileManager.default
        let docsurl = try! fileManager.url(
            for: .cachesDirectory, in: .userDomainMask,
            appropriateFor: nil, create: true)
        if self.folder != nil {
            return docsurl.appendingPathComponent("APReader.OneDrive/File/\(self.name ?? "")")
        } else {
            return docsurl.appendingPathComponent("APReader.OneDrive/File/\(self.fileItemShortRelativePath() ?? "")")
        }
    }
    
    func localFilePath() -> URL {
        let fileManager = FileManager.default
        let docsurl = try! fileManager.url(
            for: .cachesDirectory, in: .userDomainMask,
            appropriateFor: nil, create: true)
        if self.folder != nil {
            return docsurl.appendingPathComponent("APReader.OneDrive/File/\(self.name ?? "")")
        } else {
            return docsurl.appendingPathComponent("APReader.OneDrive/File/\(self.fileItemShortRelativePath() ?? "")/\(self.name ?? "")")
        }
    }
    
    // for local APReader.Local
    func localFolderFilePath() -> URL {
        let fileManager = FileManager.default
        let docsurl = try! fileManager.url(
            for: .cachesDirectory, in: .userDomainMask,
            appropriateFor: nil, create: true)
        return docsurl.appendingPathComponent("APReader.Local/File/\(self.name ?? "")")
    }
}

