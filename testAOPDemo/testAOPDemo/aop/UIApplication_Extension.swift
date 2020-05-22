//
//  UIApplication_Extension.swift
//  testAOPDemo
//
//  Created by 管浩 on 2020/5/21.
//  Copyright © 2020 管浩. All rights reserved.
//

import UIKit

class GHUIApplicationDelegateProxy: NSObject, UIApplicationDelegate {
    
    weak var delegate: UIApplicationDelegate?
    
    override func responds(to aSelector: Selector!) -> Bool {
        // 指定的方法才转发
        if aSelector == #selector(application(_:didFinishLaunchingWithOptions:)) {
            return true
        }
        if aSelector == #selector(applicationDidBecomeActive(_:)) {
            return true
        }
        if aSelector == #selector(applicationWillResignActive(_:)) {
            return true
        }
        if aSelector == #selector(applicationWillTerminate(_:)) {
            return true
        }
        if aSelector == #selector(applicationDidEnterBackground(_:)) {
            return true
        }
        if aSelector == #selector(applicationWillEnterForeground(_:)) {
            return true
        }
        if aSelector == #selector(application(_:open:options:)) {
            return true
        }
        if aSelector == #selector(application(_:didRegisterForRemoteNotificationsWithDeviceToken:)) {
            return true
        }
        if aSelector == #selector(application(_:didFailToRegisterForRemoteNotificationsWithError:)) {
            return true
        }
        if aSelector == #selector(application(_:didReceiveRemoteNotification:fetchCompletionHandler:)) {
            return true
        }
        if self.delegate == nil {
            return false
        }
        if self.delegate?.responds(to: aSelector) == true {
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
    
    // MARK: UIApplicationDelegate
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        UIApplicationTrack.shared.trackUIApplicationAction("UIApplicationDidFinishLaunchingWithOptions")
        
        if self.delegate == nil {
            return true
        }
        if (self.delegate?.responds(to: #selector(application(_:didFinishLaunchingWithOptions:)))) == false {
            return true
        }
        return self.delegate?.application?(application, didFinishLaunchingWithOptions: launchOptions) ?? true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        
        UIApplicationTrack.shared.trackUIApplicationAction("UIApplicationDidBecomeActive")
        
        if self.delegate == nil {
            return
        }
        if (self.delegate?.responds(to: #selector(applicationDidBecomeActive(_:)))) == false {
            return
        }
        self.delegate?.applicationDidBecomeActive?(application)
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        
        UIApplicationTrack.shared.trackUIApplicationAction("UIApplicationWillResignActive")
        
        if self.delegate == nil {
            return
        }
        if (self.delegate?.responds(to: #selector(applicationWillResignActive(_:)))) == false {
            return
        }
        self.delegate?.applicationWillResignActive?(application)
    }
    
    @available(iOS 9.0, *)
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        UIApplicationTrack.shared.trackUIApplicationAction("OtherUrlOpenUIApplication:" + url.absoluteString)
        
        if self.delegate == nil {
            return true
        }
        if (self.delegate?.responds(to: #selector(application(_:open:options:)))) == false {
            return true
        }
        return self.delegate?.application?(app, open: url, options: options) ?? true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        let tokenStr: String = deviceToken.map{String(format:"%02.2hhx", arguments: [$0])}.joined()
        UIApplicationTrack.shared.trackUIApplicationAction("UIApplicationDeviceToken:" + tokenStr)
        
        if self.delegate == nil {
            return
        }
        if (self.delegate?.responds(to: #selector(application(_:didRegisterForRemoteNotificationsWithDeviceToken:)))) == false {
            return
        }
        self.delegate?.application?(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        
        UIApplicationTrack.shared.trackUIApplicationAction("UIApplicationDeviceTokenFail:" + error.localizedDescription)
        
        if self.delegate == nil {
            return
        }
        if (self.delegate?.responds(to: #selector(application(_:didFailToRegisterForRemoteNotificationsWithError:)))) == false {
            return
        }
        self.delegate?.application?(application, didFailToRegisterForRemoteNotificationsWithError: error)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        if self.delegate == nil {
            return
        }
        if (self.delegate?.responds(to: #selector(application(_:didReceiveRemoteNotification:fetchCompletionHandler:)))) == false {
            return
        }
        self.delegate?.application?(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        
        UIApplicationTrack.shared.trackUIApplicationAction("UIApplicationWillTerminate")
        
        if self.delegate == nil {
            return
        }
        if (self.delegate?.responds(to: #selector(applicationWillTerminate(_:)))) == false {
            return
        }
        self.delegate?.applicationWillTerminate?(application)
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        
        UIApplicationTrack.shared.trackUIApplicationAction("UIApplicationDidEnterBackground")
        
        if self.delegate == nil {
            return
        }
        if (self.delegate?.responds(to: #selector(applicationDidEnterBackground(_:)))) == false {
            return
        }
        self.delegate?.applicationDidEnterBackground?(application)
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        
        UIApplicationTrack.shared.trackUIApplicationAction("UIApplicationWillEnterForeground")
        
        if self.delegate == nil {
            return
        }
        if (self.delegate?.responds(to: #selector(applicationWillEnterForeground(_:)))) == false {
            return
        }
        self.delegate?.applicationWillEnterForeground?(application)
    }
}

private func swizzle(_ application: UIApplication.Type) {
    var selectors: Array<Array<Selector>> = [
        [
            #selector(setter: UIApplication.shared.delegate),
            #selector(UIApplication.shared.gh_setDelegate(_:))
        ],
    ]
    if #available(iOS 10.0, *) {
        selectors.append(contentsOf:
            [
                [
                    #selector(UIApplication.shared.open(_:options:completionHandler:)),
                    #selector(UIApplication.shared.gh_open(_:options:completionHandler:))
                ],
            ]
        )
    } else {
        selectors.append(contentsOf:
            [
                [
                    #selector(UIApplication.shared.openURL(_:)),
                    #selector(UIApplication.shared.gh_openURL(_:))
                ],
            ]
        )
    }

    for item in selectors {
        let originalSelector: Selector = item[0]
        let swizzledSelector: Selector = item[1]

        let originalMethod: Method? = class_getInstanceMethod(application, originalSelector)
        let swizzledMethod: Method? = class_getInstanceMethod(application, swizzledSelector)

        if originalMethod == nil {
            continue
        }

        let didAddMethod: Bool = class_addMethod(application, originalSelector, method_getImplementation(swizzledMethod!), method_getTypeEncoding(swizzledMethod!))
        if didAddMethod {
            class_replaceMethod(application, swizzledSelector, method_getImplementation(originalMethod!), method_getTypeEncoding(originalMethod!))
        } else {
            method_exchangeImplementations(originalMethod!, swizzledMethod!)
        }
    }
}

// runtime key
var ghUIApplicationDelegateProxyKey = "GHUIApplicationDelegateProxyKey"

extension UIApplication {
    var ghUIApplicationDelegateProxy: GHUIApplicationDelegateProxy? {
        set {
            objc_setAssociatedObject(self, &ghUIApplicationDelegateProxyKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
        get {
            return objc_getAssociatedObject(self, &ghUIApplicationDelegateProxyKey) as? GHUIApplicationDelegateProxy
        }
    }
    
    private static let dispatchOnceTime: Void = {
        swizzle(UIApplication.self)
    }()
    
    @objc open class func startAOP() {
        guard self === UIApplication.self else { return }
        UIApplication.dispatchOnceTime
    }
    
    // MARK: 交换的方法
    
    @objc func gh_setDelegate(_ delegate : UIApplicationDelegate?) {
        
        self.ghUIApplicationDelegateProxy = GHUIApplicationDelegateProxy()
        self.ghUIApplicationDelegateProxy?.delegate = delegate
        
        self.gh_setDelegate(self.ghUIApplicationDelegateProxy)
    }
    
    @available(iOS, introduced: 2.0, deprecated: 10.0)
    @objc func gh_openURL(_ url: URL) -> Bool {
        
        UIApplicationTrack.shared.trackUIApplicationAction("UIApplicationOpenURL:" + url.absoluteString)
        
        return self.gh_openURL(url)
    }
    
    @available(iOS 10.0, *)
    @objc func gh_open(_ url: URL, options: [UIApplication.OpenExternalURLOptionsKey : Any] = [:], completionHandler completion: ((Bool) -> Void)? = nil) {
        
        UIApplicationTrack.shared.trackUIApplicationAction("UIApplicationOpenURL:" + url.absoluteString)
        
        self.gh_open(url, options: options, completionHandler: completion)
    }
}
