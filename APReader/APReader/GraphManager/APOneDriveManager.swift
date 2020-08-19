//
//  APOneDriveManager.swift
//  APReader
//
//  Created by Tango on 2020/8/18.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import Foundation
import MSGraphClientSDK
import MSGraphClientModels
import PDFKit

enum OneDriveManagerResult {
    case Success
    case Failure(OneDriveAPIError)
}

enum OneDriveAPIError: Error {
    case ResourceNotFound
    case JSONParseError
    case UnspecifiedError(URLResponse?)
    case GeneralError(Error?)
}

struct UploadTaskObj : Decodable {
    let expirationDateTime: String
    let nextExpectedRanges: [String]?
}

class APOneDriveManager {
    
    static let instance = APOneDriveManager()
    
    static let partSize: Int = 327680
    
    private let client: MSHTTPClient?
    
    private var accessToken = APAuthManager.instance.accessToken
    
    private init() {
        client = MSClientFactory.createHTTPClient(with: APAuthManager.instance)
    }
    
    func createUploadSession(fileName: String, completion: @escaping (OneDriveManagerResult, _ uploadUrl: String?, _ expirationDateTime: String?, _ nextExpectedRanges: [String]?) -> Void) {
        
        let request = NSMutableURLRequest(url: URL(string: "\(MSGraphBaseURL)/me/drive/special/approot:/\(fileName):/createUploadSession")!)
        request.httpMethod = "POST"
        let params = ["item": ["name": fileName]] as [String : Any]
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try! JSONSerialization.data(withJSONObject: params, options: JSONSerialization.WritingOptions())
        
        let uploadTask = MSURLSessionDataTask(request: request, client: self.client, completion: {
            (data: Data?, response: URLResponse?, graphError: Error?) in
            
            guard let _ = data, graphError == nil else {
                completion(OneDriveManagerResult.Failure(OneDriveAPIError.UnspecifiedError(response)), nil, nil, nil)
                return
            }
            
            let statusCode = (response as! HTTPURLResponse).statusCode
            print("status code = \(statusCode)")
            
            switch(statusCode) {
            case 200, 201:
                do {
                    let jsonResponse = try JSONSerialization.jsonObject(with: data!, options: [])  as? [String: Any]
                    print((jsonResponse?.description)!) // outputs whole JSON
                    
                    guard let uploadUrl = jsonResponse!["uploadUrl"] as? String else {
                        completion(OneDriveManagerResult.Failure(OneDriveAPIError.UnspecifiedError(response)), nil, nil, nil)
                        return
                    }
                    
                    guard let expirationDateTime = jsonResponse!["expirationDateTime"] as? String else {
                        completion(OneDriveManagerResult.Failure(OneDriveAPIError.UnspecifiedError(response)), nil, nil, nil)
                        return
                    }
                    
                    guard let nextExpectedRanges = jsonResponse!["nextExpectedRanges"] as? [String] else {
                        completion(OneDriveManagerResult.Failure(OneDriveAPIError.UnspecifiedError(response)), nil, nil, nil)
                        return
                    }
                    
                    completion(OneDriveManagerResult.Success, uploadUrl, expirationDateTime, nextExpectedRanges)
                }
                catch{
                    completion(OneDriveManagerResult.Failure(OneDriveAPIError.JSONParseError), nil, nil, nil)
                }
            case 400:
                completion(OneDriveManagerResult.Failure(OneDriveAPIError.UnspecifiedError(response)), nil, nil, nil)
            default:
                completion(OneDriveManagerResult.Failure(OneDriveAPIError.UnspecifiedError(response)), nil, nil, nil)
            }
        })
        
        uploadTask?.execute()
    }
    
    func uploadPDFBytes(fileName: String, uploadUrl: String, completion: @escaping (OneDriveManagerResult, _ webUrl: String?, _ fileId: String?) -> Void) {
        let fileManager = FileManager.default
        let docsurl = try! fileManager.url(
            for: .cachesDirectory, in: .userDomainMask,
            appropriateFor: nil, create: true)
        let fileUrl = docsurl.appendingPathComponent("APReader.OneDrive/File/\(fileName)")
        let pdfDocument = PDFDocument(url: fileUrl)
        
        let data = pdfDocument?.dataRepresentation()
        let imageSize: Int = data!.count
        
        var returnWebUrl: String?
        var returnFileId: String?
        var returnNextExpectedRange: Int = 0
        
        let dispatchGroup = DispatchGroup()
        let dispatchQueue = DispatchQueue(label: "taskQueue")
        let dispatchSemaphore = DispatchSemaphore(value: 0)
        
        let urlSessionConfiguration: URLSessionConfiguration = URLSessionConfiguration.default.copy() as! URLSessionConfiguration
        urlSessionConfiguration.httpMaximumConnectionsPerHost = 1
        let defaultSession = URLSession(configuration: urlSessionConfiguration)
        
        let uploadBytePartsCompletionHandler: (OneDriveManagerResult, Int?, String?, String?) -> Void = {
            (result: OneDriveManagerResult, nextExpectedRange, webUrl, fileId) in
            switch(result) {
            case .Success:
                if (nextExpectedRange != nil) {returnNextExpectedRange = nextExpectedRange!}
                if (webUrl != nil) { returnWebUrl = webUrl}
                if (fileId != nil) { returnFileId = fileId}
                dispatchSemaphore.signal()
                dispatchGroup.leave()
            case .Failure(let error):
                completion(OneDriveManagerResult.Failure(OneDriveAPIError.GeneralError(error)), nil, nil)
            }
        }
        
        dispatchQueue.async {
            while (returnWebUrl == nil) {
                dispatchGroup.enter()
                self.uploadByteParts(defaultSession: defaultSession, uploadUrl: uploadUrl, data: data!, startPointer: returnNextExpectedRange, endPointer: returnNextExpectedRange + APOneDriveManager.partSize - 1, imageSize: imageSize, completion: uploadBytePartsCompletionHandler)
                dispatchSemaphore.wait()
            }
        }
        
        dispatchGroup.notify(queue: dispatchQueue) {
            DispatchQueue.main.async {
                completion(OneDriveManagerResult.Success, returnWebUrl, returnFileId)
            }
        }
    }
    
    func uploadByteParts(defaultSession: URLSession, uploadUrl:String, data:Data,startPointer:Int, endPointer:Int, imageSize:Int, completion: @escaping (OneDriveManagerResult, _ nextExpectedRangeStart: Int?, _ webUrl: String?, _ fileId: String?) -> Void) {
        
        var dataEndPointer = endPointer
        if (endPointer + 1 >= imageSize){
            dataEndPointer = imageSize - 1
        }
        let strContentRange = "bytes \(startPointer)-\(dataEndPointer)/\(imageSize)"
        print(strContentRange)
        
        var request = URLRequest(url: URL(string: uploadUrl)!)
        request.httpMethod = "PUT"
        request.setValue(strContentRange, forHTTPHeaderField: "Content-Range")
        request.setValue("\(imageSize)", forHTTPHeaderField: "Content-Length")
        
        let uploadTaskCompletionHandler: (Data?, URLResponse?, Error?) -> Void = {
            (data, response, error) in
            
            guard error == nil else {
                print("error calling upload")
                print(error!)
                return
            }
            guard let responseData = data else {
                print("Error: did not receive data")
                return
            }
            do {
                guard let json = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any] else {
                    print("error trying to convert data to JSON")
                    return
                }
                print("The json is: " + json.description)
                
                guard let webUrl = json["webUrl"] as? String else {
                    let decoder = JSONDecoder()
                    let uploadTaskObj = try decoder.decode(UploadTaskObj.self, from: responseData)
                    
                    let strNextExpectedRanges = uploadTaskObj.nextExpectedRanges![0]
                    let index = strNextExpectedRanges.firstIndex(of: "-")!
                    let strNextExpectedRangeStart = strNextExpectedRanges.substring(to: index)
                    completion(OneDriveManagerResult.Success, Int(strNextExpectedRangeStart), nil, nil)
                    return
                }
                
                let fileId = json["id"] as? String
                completion(OneDriveManagerResult.Success, nil, webUrl, fileId)
            } catch  {
                print("error trying to convert data to JSON")
                completion(OneDriveManagerResult.Failure(OneDriveAPIError.GeneralError(error)), nil, nil, nil)
            }
        }
        
        let uploadTask = defaultSession.uploadTask(with: request, from: data[startPointer ... dataEndPointer], completionHandler: uploadTaskCompletionHandler)
        uploadTask.resume()
    }
    
}
