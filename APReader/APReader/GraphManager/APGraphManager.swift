//
//  APGraphManager.swift
//  APReader
//
//  Created by Tango on 2020/8/11.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import Foundation
import MSGraphClientSDK
import MSGraphClientModels

class APGraphManager {
    
    static let instance = APGraphManager()
    
    private let client: MSHTTPClient?
    
    private init() {
        client = MSClientFactory.createHTTPClient(with: APAuthManager.instance)
    }
    
    public func getMe(completion: @escaping(MSGraphUser?, Error?) -> Void) {
        // GET /me
        let meRequest = NSMutableURLRequest(url: URL(string: "\(MSGraphBaseURL)/me")!)
        let meDataTask = MSURLSessionDataTask(request: meRequest, client: self.client, completion: {
            (data: Data?, response: URLResponse?, graphError: Error?) in
            guard let meData = data, graphError == nil else {
                completion(nil, graphError)
                return
            }
            
            do {
                // Deserialize response as a user
                let user = try MSGraphUser(data: meData)
                completion(user, nil)
            } catch {
                completion(nil, error)
            }
        })
        
        // Execute the request
        meDataTask?.execute()
    }
    
    public func getFiles(folderName: String?, completion: @escaping([MSGraphDriveItem]?, Error?) -> Void) {
        // GET /me/drive/root/children
        var subFolder: String?
        if folderName?.count ?? 0 > 0 {
            subFolder = "/\(folderName ?? "")"
        }
        let urlString = "\(MSGraphBaseURL)/me/drive/root:/Apps/APDFReader\(subFolder ?? ""):/children".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let filesRequest = NSMutableURLRequest(url: URL(string: urlString)!)
        let filesDataTask = MSURLSessionDataTask(request: filesRequest, client: self.client, completion: {
            (data: Data?, response: URLResponse?, graphError: Error?) in
            guard let filesData = data, graphError == nil else {
                completion(nil, graphError)
                return
            }
            
            do {
                // Deserialize response as events collection
                let filesCollection = try MSCollection(data: filesData)
                var fileArray: [MSGraphDriveItem] = []
                
                filesCollection.value.forEach({
                    (rawFile: Any) in
                    print("used json: \(rawFile)")
                    // Convert JSON to a dictionary
                    guard let filesDict = rawFile as? [String: Any] else {
                        return
                    }
                    // Deserialize event from the dictionary
                    let file = MSGraphDriveItem(dictionary: filesDict)!
                    fileArray.append(file)
                })
                
                // Return the array
                completion(fileArray, nil)
            } catch {
                completion(nil, error)
            }
        })
        
        // Execute the request
        filesDataTask?.execute()
    }
    
    public func getFileContentDownloadUrl(itemid: String, completion: @escaping(String?, Error?) -> Void) {
        // GET /me/drive/root/children
        let filesRequest = NSMutableURLRequest(url: URL(string: "\(MSGraphBaseURL)/me/drive/items/\(itemid)/content")!)
        print("filesRequest: \(filesRequest)")
        let filesDataTask = MSURLSessionDataTask(request: filesRequest, client: self.client, completion: {
            (data: Data?, response: URLResponse?, graphError: Error?) in
            guard let response = response, graphError == nil else {
                completion(nil, graphError)
                return
            }
           
            do {
                print("dic:\(String(describing: response.url?.absoluteString))")
                completion(response.url?.absoluteString, nil)
            } catch _ {
                completion(nil, graphError)
            }

        })
        
        // Execute the request
        filesDataTask?.execute()
    }
    
    
    
}
