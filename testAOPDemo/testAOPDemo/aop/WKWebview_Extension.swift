//
//  WKWebview_Extension.swift
//  testAOPDemo
//
//  Created by 管浩 on 2020/5/21.
//  Copyright © 2020 管浩. All rights reserved.
//

import UIKit
import WebKit

class GHWKNavigationDelegateProxy: NSObject, WKNavigationDelegate {
    
    weak var delegate: WKNavigationDelegate?
        
    override func responds(to aSelector: Selector!) -> Bool {
        if aSelector == #selector(webView(_:didFinish:)) {
            return true
        }
        if aSelector == #selector(webView(_:didFail:withError:)) {
            return true
        }
        if self.delegate == nil {
            return false
        }
        if self.delegate!.responds(to: aSelector) {
            return true
        }
        return false
    }
    
    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if self.delegate == nil {
            return super.forwardingTarget(for: aSelector)
        }
        if self.delegate?.responds(to: aSelector) == false {
            return super.forwardingTarget(for: aSelector)
        }
        return self.delegate
    }
    
    // MARK: WKNavigationDelegate
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        WKWebViewTrack.shared.endTrackWKWebView(webView, error: nil)
        
        if self.delegate == nil {
            return
        }
        if (self.delegate?.responds(to: #selector(webView(_:didFinish:)))) == false {
            return
        }
        self.delegate?.webView?(webView, didFinish: navigation)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        
        WKWebViewTrack.shared.endTrackWKWebView(webView, error: error)
        
        if self.delegate == nil {
            return
        }
        if (self.delegate?.responds(to: #selector(webView(_:didFail:withError:)))) == false {
            return
        }
        self.delegate?.webView?(webView, didFail: navigation, withError: error)
    }
}

private func swizzle(_ webView: WKWebView.Type) {
    let selectors: Array<Array<Selector>> = [
        [
            #selector(webView.load(_:)),
            #selector(webView.gh_load(_:))
        ],
        [
            #selector(setter: webView.navigationDelegate),
            #selector(webView.gh_setNavigationDelegate(_:))
        ],
    ]
    
    for item in selectors {
        let originalSelector: Selector = item[0]
        let swizzledSelector: Selector = item[1]

        let originalMethod: Method? = class_getInstanceMethod(webView, originalSelector)
        let swizzledMethod: Method? = class_getInstanceMethod(webView, swizzledSelector)
        
        if originalMethod == nil {
            continue
        }
        
        let didAddMethod: Bool = class_addMethod(webView, originalSelector, method_getImplementation(swizzledMethod!), method_getTypeEncoding(swizzledMethod!))
        if didAddMethod {
            class_replaceMethod(webView, swizzledSelector, method_getImplementation(originalMethod!), method_getTypeEncoding(originalMethod!))
        } else {
            method_exchangeImplementations(originalMethod!, swizzledMethod!)
        }
    }
}

var ghWKNavigationDelegateProxyKey = "GHWKNavigationDelegateProxyKey"
var ghWKWebViewIdKey = "GHWKWebViewIdKey"

extension WKWebView {
    var ghWKNavigationDelegateProxy: GHWKNavigationDelegateProxy? {
        set {
            objc_setAssociatedObject(self, &ghWKNavigationDelegateProxyKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
        get {
            return objc_getAssociatedObject(self, &ghWKNavigationDelegateProxyKey) as? GHWKNavigationDelegateProxy
        }
    }
    var ghWKWebViewId: String! {
        set {
            objc_setAssociatedObject(self, &ghWKWebViewIdKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
        get {
            return objc_getAssociatedObject(self, &ghWKWebViewIdKey) as? String
        }
    }
    
    private static let dispatchOnceTime: Void = {
        swizzle(WKWebView.self)
    }()
    
    @objc open class func startAOP() {
        guard self === WKWebView.self else { return }
        WKWebView.dispatchOnceTime
    }
    
    // MARK: 交换的方法
    
    @objc func gh_load(_ request: URLRequest) -> WKNavigation? {
        
        if self.ghWKNavigationDelegateProxy == nil {
            self.ghWKNavigationDelegateProxy = GHWKNavigationDelegateProxy()
        }
        self.navigationDelegate = self.ghWKNavigationDelegateProxy
                
        self.ghWKWebViewId = "WKWebView" + String(self.hashValue) + TrackUtils.stringFromDate(Date.init(), with: "yyyy-MM-dd HH:mm:ss.SSS")
        
        WKWebViewTrack.shared.startTrackWKWebView(self, startLoadWith: request)
        
        return self.gh_load(request)
    }
    
    @objc func gh_setNavigationDelegate(_ navigationDelegate : WKNavigationDelegate?) {
        
        if object_getClass(navigationDelegate) === GHWKNavigationDelegateProxy.self {
            self.gh_setNavigationDelegate(self.ghWKNavigationDelegateProxy)
        } else {
            if self.ghWKNavigationDelegateProxy == nil {
                self.ghWKNavigationDelegateProxy = GHWKNavigationDelegateProxy()
            }
            self.ghWKNavigationDelegateProxy?.delegate = navigationDelegate
            if self.navigationDelegate == nil {
                self.gh_setNavigationDelegate(self.ghWKNavigationDelegateProxy)
            }
        }
    }
}
