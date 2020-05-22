//
//  URLSessionTrack.swift
//  testAOPDemo
//
//  Created by 管浩 on 2020/5/21.
//  Copyright © 2020 管浩. All rights reserved.
//

import UIKit

/// track URLSession data
class URLSessionTrack: NSObject {
    
    // MARK: 单例
    
    private static var instance: URLSessionTrack = {
        let track = URLSessionTrack.init()
        return track
    }()
    
    open class var shared: URLSessionTrack {
        get {
            return instance
        }
    }
    
    override class func copy() -> Any {
        return instance
    }
    
    override func mutableCopy() -> Any {
        return URLSessionTrack.instance
    }
    
    override init() {
        super.init()
        
        self.queue = DispatchQueue.init(label: "com.urlsession.track")
    }
    
    // MARK: 属性
    
    private var recordParams: Dictionary<String, Dictionary<String, Any?>> = [:]
    private var queue: DispatchQueue!
    
    // MARK: 拦截的方法
    
    open func startTrackSessionWith(Request request: URLRequest?, StartDate startDate: Date) -> Void {
        self.queue.sync {
            if request == nil {
                return
            }
            let key: String? = request!.value(forHTTPHeaderField: "ghTrackIdentifier")
            if key == nil {
                return
            }
            
            let url: String = request!.url?.absoluteString ?? ""
            let httpMethod: String = request!.httpMethod ?? ""
            let httpBody: Data = request!.httpBody ?? Data.init()
            let requestStartTime: String = TrackUtils.stringFromDate(Date.init(), with: "yyyy-MM-dd HH:mm:ss.SSS")
            
            var infoDic: Dictionary<String, Any?> = [:]
            infoDic["url"] = url
            infoDic["httpMethod"] = httpMethod
            infoDic["httpBody"] = httpBody
            infoDic["requestStartTime"] = requestStartTime
            
            self.recordParams[key!] = infoDic
        }
    }
    
    open func endTrackDataSessionWith(Indentifier identifier: String, EndDate endDate: Date, ResponseData data: Data?, Response response: URLResponse?, Error error: Error?) -> Void {
        
        self.queue.sync {
            let infoDic: Dictionary<String, Any?> = self.recordParams[identifier] ?? [:]
            
            if infoDic.count == 0 {
                return
            }
            
            let requestStartTime: String = (infoDic["requestStartTime"] as? String) ?? ""
            if requestStartTime == "" {
                return
            }
            let duration = TrackUtils.duration(From: requestStartTime, To: TrackUtils.stringFromDate(Date.init(), with: "yyyy-MM-dd HH:mm:ss.SSS"))
            let url: String = (infoDic["url"] as? String) ?? ""
            let httpMethod: String = (infoDic["httpMethod"] as? String) ?? ""
            let httpBody: Data = (infoDic["httpBody"] as? Data) ?? Data.init()
            
            self.recordParams.removeValue(forKey: identifier)
            
            TrackingDataAnalysisHelper.analysisURLDataSessionTrackingData(url, duration: String(duration), httpBodyLength: String(httpBody.count), httpMethod: httpMethod, error: error)
        }
    }
    
    open func endTrackDownloadSessionWith(Indentifier identifier: String, EndDate endDate: Date, ResponseURL responseUrl: URL?, Response response: URLResponse?, Error error: Error?) -> Void {
        
        self.queue.sync {
            let infoDic: Dictionary<String, Any?> = self.recordParams[identifier] ?? [:]
            
            if infoDic.count == 0 {
                return
            }
            
            let requestStartTime: String = (infoDic["requestStartTime"] as? String) ?? ""
            if requestStartTime == "" {
                return
            }
            let duration = TrackUtils.duration(From: requestStartTime, To: TrackUtils.stringFromDate(Date.init(), with: "yyyy-MM-dd HH:mm:ss.SSS"))
            let url: String = (infoDic["url"] as? String) ?? ""
            let httpMethod: String = (infoDic["httpMethod"] as? String) ?? ""
            let httpBody: Data = (infoDic["httpBody"] as? Data) ?? Data.init()
            
            var isImage: Bool = false
            let data: Data? = try? Data.init(contentsOf: responseUrl!)
            if data == nil {
                return
            }
            isImage = self.isImage(file: data!)
            
            self.recordParams.removeValue(forKey: identifier)
            
            TrackingDataAnalysisHelper.analysisURLDownloadSessionTrackingData(url, duration: String(duration), httpBodyLength: String(httpBody.count), httpMethod: httpMethod, isImage: isImage, error: error)
        }
    }
    
    open func endTrackUploadSessionWith(Indentifier identifier: String, EndDate endDate: Date, ResponseData data: Data?, Response response: URLResponse?, Error error: Error?) -> Void {
        
        self.queue.sync {
            let infoDic: Dictionary<String, Any?> = self.recordParams[identifier] ?? [:]
            
            if infoDic.count == 0 {
                return
            }
            
            let requestStartTime: String = (infoDic["requestStartTime"] as? String) ?? ""
            if requestStartTime == "" {
                return
            }
            let duration = TrackUtils.duration(From: requestStartTime, To: TrackUtils.stringFromDate(Date.init(), with: "yyyy-MM-dd HH:mm:ss.SSS"))
            let url: String = (infoDic["url"] as? String) ?? ""
            let httpMethod: String = (infoDic["httpMethod"] as? String) ?? ""
            let httpBody: Data = (infoDic["httpBody"] as? Data) ?? Data.init()
            
            self.recordParams.removeValue(forKey: identifier)
            
            TrackingDataAnalysisHelper.analysisURLUploadSessionTrackingData(url, duration: String(duration), httpBodyLength: String(httpBody.count), httpMethod: httpMethod, error: error)
        }
    }
    
    private func isImage(file: Data) -> Bool {
        var buffer = [UInt8](repeating: 0, count: 1)
        file.copyBytes(to: &buffer, count: 1)
        
        switch buffer {
        case [0xFF]:// JPEG
            return true
        case [0x89]:// PNG
            return true
        case [0x47]:// GIF
            return true
        default:
            return false
        }
    }
}
