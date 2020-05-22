//
//  WKWebViewTrack.swift
//  testAOPDemo
//
//  Created by 管浩 on 2020/5/21.
//  Copyright © 2020 管浩. All rights reserved.
//

import UIKit
import WebKit

class WKWebViewTrack: NSObject {
    
    // MARK: 单例
    
    private static var instance: WKWebViewTrack = {
        let track = WKWebViewTrack.init()
        return track
    }()
    
    open class var shared: WKWebViewTrack {
        get {
            return instance
        }
    }
    
    override class func copy() -> Any {
        return instance
    }
    
    override func mutableCopy() -> Any {
        return WKWebViewTrack.instance
    }
    
    override init() {
        super.init()
    }
    
    // MARK: 属性
    
    private var recordParams: Dictionary<String, Dictionary<String, Any?>> = [:]
    
    // MARK: 拦截的方法
    
    open func startTrackWKWebView(_ webView: WKWebView, startLoadWith request: URLRequest) -> Void {
        
        let key: String? = webView.ghWKWebViewId
        if key == nil {
            return
        }
        
        let startLoadTime: String = TrackUtils.stringFromDate(Date.init(), with: "yyyy-MM-dd HH:mm:ss.SSS")
        let url: String? = request.url?.absoluteString
        
        var infoDic: Dictionary<String, Any?> = [:]
        infoDic["url"] = url
        infoDic["startLoadTime"] = startLoadTime
        
        self.recordParams[key!] = infoDic
    }
    
    open func endTrackWKWebView(_ webView: WKWebView, error: Error?) -> Void {
        
        let key: String = webView.ghWKWebViewId
        
        let infoDic: Dictionary<String, Any?> = self.recordParams[key] ?? [:]
        if infoDic.count == 0 {
            return
        }
        
        let startLoadTime: String = (infoDic["startLoadTime"] as? String) ?? ""
        if startLoadTime == "" {
            return
        }
        let duration = TrackUtils.duration(From: startLoadTime, To: TrackUtils.stringFromDate(Date.init(), with: "yyyy-MM-dd HH:mm:ss.SSS"))
        let url: String = (infoDic["url"] as? String) ?? ""
        
        self.recordParams.removeValue(forKey: key)
        
        TrackingDataAnalysisHelper.analysisWKWebViewTrackingData(webView, url: url, duration: String(duration), error: error)
    }
}
