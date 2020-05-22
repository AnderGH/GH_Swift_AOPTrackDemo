//
//  UITabBar_Extension.swift
//  testAOPDemo
//
//  Created by 管浩 on 2020/5/21.
//  Copyright © 2020 管浩. All rights reserved.
//

import UIKit

class GHUITabBarDelegateProxy: NSObject, UITabBarDelegate {
    
    weak var delegate: UITabBarDelegate?
        
    override func responds(to aSelector: Selector!) -> Bool {
        var hasSelector: Bool = false
        if self.delegate == nil {
            return hasSelector
        }
        hasSelector = self.delegate?.responds(to: aSelector) ?? true
        return hasSelector
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
    
    // MARK: UITabBarDelegate
    
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        print("tabBar点击item方法")
        
        if self.delegate == nil {
            return
        }
        if (self.delegate?.responds(to: #selector(tabBar(_:didSelect:)))) == false {
            return
        }
        
        UITabBarTrack.shared.trackTabBar(tabBar, didSelect: item)
        
        self.delegate?.tabBar?(tabBar, didSelect: item)
    }
}

private func swizzle(_ tabBar: UITabBar.Type) {
    let selectors: Array<Array<Selector>> = [
        [
            #selector(setter: tabBar.delegate),
            #selector(tabBar.gh_setDelegate(_:))
        ],
    ]
    for item in selectors {
        let originalSelector: Selector = item[0]
        let swizzledSelector: Selector = item[1]

        let originalMethod: Method? = class_getInstanceMethod(tabBar, originalSelector)
        let swizzledMethod: Method? = class_getInstanceMethod(tabBar, swizzledSelector)
        
        if originalMethod == nil {
            continue
        }
        
        let didAddMethod: Bool = class_addMethod(tabBar, originalSelector, method_getImplementation(swizzledMethod!), method_getTypeEncoding(swizzledMethod!))
        if didAddMethod {
            class_replaceMethod(tabBar, swizzledSelector, method_getImplementation(originalMethod!), method_getTypeEncoding(originalMethod!))
        } else {
            method_exchangeImplementations(originalMethod!, swizzledMethod!)
        }
    }
}

// runtime key
var ghUITabBarDelegateProxyKey = "GHUITabBarDelegateProxyKey"

extension UITabBar {
    
    var ghUITabBarDelegateProxy: GHUITabBarDelegateProxy? {
        set {
            objc_setAssociatedObject(self, &ghUITabBarDelegateProxyKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
        get {
            return objc_getAssociatedObject(self, &ghUITabBarDelegateProxyKey) as? GHUITabBarDelegateProxy
        }
    }
    
    private static let dispatchOnceTime: Void = {
        swizzle(UITabBar.self)
    }()
    
    @objc open class func startAOP() {
        guard self === UITabBar.self else { return }
        UITabBar.dispatchOnceTime
    }
    
    // MARK: 交换的方法

    @objc func gh_setDelegate(_ delegate: UITabBarDelegate?) {
        
        self.ghUITabBarDelegateProxy = GHUITabBarDelegateProxy()
        self.ghUITabBarDelegateProxy?.delegate = delegate
        
        self.gh_setDelegate(self.ghUITabBarDelegateProxy)
    }
}
