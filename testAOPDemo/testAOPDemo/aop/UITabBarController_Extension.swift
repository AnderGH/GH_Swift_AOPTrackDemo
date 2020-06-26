//
//  UITabBarController_Extension.swift
//  testAOPDemo
//
//  Created by 管浩 on 2020/5/21.
//  Copyright © 2020 管浩. All rights reserved.
//

import UIKit

class GHUITabBarControllerDelegateProxy: NSObject, UITabBarControllerDelegate {
    
    weak var delegate: UITabBarControllerDelegate?
    
    override func responds(to aSelector: Selector!) -> Bool {
        if aSelector == #selector(tabBarController(_:didSelect:)) {
            return true
        }
        guard let delegate = self.delegate else {
            return false
        }
        if delegate.responds(to: aSelector) {
            return true
        }
        return false
    }
    
    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        guard let delegate = self.delegate else {
            return super.forwardingTarget(for: aSelector)
        }
        if delegate.responds(to: aSelector) == false {
            return super.forwardingTarget(for: aSelector)
        }
        return delegate
    }
    
    // MARK: UITabBarControllerDelegate
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        
        // 此方法有可能存在不实现的情况，所以这里先拦截埋点
        UITabBarControllerTrack.shared.trackTabBarController(tabBarController, didSelect: viewController)
        
        guard let delegate = self.delegate else {
            return
        }
        if delegate.responds(to: #selector(tabBarController(_:didSelect:))) {
            delegate.tabBarController?(tabBarController, didSelect: viewController)
        }
    }
}

private func swizzle(_ tabBarController: UITabBarController.Type) {
    let selectors: [[Selector]] = [
        [
            #selector(setter: tabBarController.delegate),
            #selector(tabBarController.gh_setDelegate(_:))
        ],
        [
            #selector(setter: tabBarController.viewControllers),
            #selector(tabBarController.gh_setViewControllers(_:))
        ],
        [
            #selector(tabBarController.setViewControllers(_:animated:)),
            #selector(tabBarController.gh_setViewControllers(_:animated:))
        ],
    ]
    for item in selectors {
        let originalSelector: Selector = item[0]
        let swizzledSelector: Selector = item[1]
        
        guard let originalMethod: Method = class_getInstanceMethod(tabBarController, originalSelector) else {
            continue
        }
        guard let swizzledMethod: Method = class_getInstanceMethod(tabBarController, swizzledSelector) else {
            continue
        }
        
        let didAddMethod: Bool = class_addMethod(tabBarController, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
        if didAddMethod {
            class_replaceMethod(tabBarController, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
}

var ghUITabBarControllerDelegateProxyKey = "GHUITabBarControllerDelegateProxyKey"

extension UITabBarController {
    var ghUITabBarControllerDelegateProxy: GHUITabBarControllerDelegateProxy? {
        set {
            objc_setAssociatedObject(self, &ghUITabBarControllerDelegateProxyKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
        get {
            return objc_getAssociatedObject(self, &ghUITabBarControllerDelegateProxyKey) as? GHUITabBarControllerDelegateProxy
        }
    }
    
    private static let dispatchOnceTime: Void = {
        swizzle(UITabBarController.self)
    }()
    
    @objc open override class func startAOP() {
        guard self === UITabBarController.self else {
            return
        }
        UITabBarController.dispatchOnceTime
    }
    
    // MARK: 交换的方法
    
    @objc func gh_setViewControllers(_ viewControllers: [UIViewController]?) {
        
        if self.ghUITabBarControllerDelegateProxy == nil {
            self.ghUITabBarControllerDelegateProxy = GHUITabBarControllerDelegateProxy()
        }
        
        self.delegate = self.ghUITabBarControllerDelegateProxy
        
        self.gh_setViewControllers(viewControllers)
    }
    
    
    @objc func gh_setViewControllers(_ viewControllers: [UIViewController]?, animated: Bool) {
        
        if self.ghUITabBarControllerDelegateProxy == nil {
            self.ghUITabBarControllerDelegateProxy = GHUITabBarControllerDelegateProxy()
        }
        
        self.delegate = self.ghUITabBarControllerDelegateProxy
        
        self.gh_setViewControllers(viewControllers, animated: animated)
    }
    
    @objc func gh_setDelegate(_ delegate: UITabBarControllerDelegate?) {
        
        if object_getClass(delegate) === GHUITabBarControllerDelegateProxy.self {
            self.gh_setDelegate(self.ghUITabBarControllerDelegateProxy)
        } else {
            if self.ghUITabBarControllerDelegateProxy == nil {
                self.ghUITabBarControllerDelegateProxy = GHUITabBarControllerDelegateProxy.init()
            }
            self.ghUITabBarControllerDelegateProxy?.delegate = delegate
            if self.delegate == nil {
                self.gh_setDelegate(self.ghUITabBarControllerDelegateProxy)
            }
        }
    }
}


