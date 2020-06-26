//
//  UITableView_Extension.swift
//  testAOPDemo
//
//  Created by 管浩 on 2020/5/21.
//  Copyright © 2020 管浩. All rights reserved.
//

import UIKit

/// 使用此类替代系统的delegate
class GHUITableViewDelegateProxy: NSObject, UITableViewDelegate {
    
    weak var delegate: UITableViewDelegate?
    
    override func responds(to aSelector: Selector!) -> Bool {
        guard let delegate = self.delegate else {
            return false
        }
        return delegate.responds(to: aSelector)
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
    
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let delegate = self.delegate else {
            return
        }
        guard delegate.responds(to: #selector(tableView(_:didSelectRowAt:))) else {
            return
        }
        
        // 埋点
        UITableViewTrack.shared.trackTableView(tableView, didSelectRowAt: indexPath)
                
        delegate.tableView?(tableView, didSelectRowAt: indexPath)
    }
}

private func swizzle(_ tableView: UITableView.Type) {
    let selectors: [[Selector]] = [
        [
            #selector(setter: tableView.delegate),
            #selector(tableView.gh_setDelegate(_:))
        ],
    ]
    for item in selectors {
        let originalSelector: Selector = item[0]
        let swizzledSelector: Selector = item[1]
        
        guard let originalMethod: Method = class_getInstanceMethod(tableView, originalSelector) else {
            continue
        }
        guard let swizzledMethod: Method = class_getInstanceMethod(tableView, swizzledSelector) else {
            continue
        }
        
        let didAddMethod: Bool = class_addMethod(tableView, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
        if didAddMethod {
            class_replaceMethod(tableView, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
}

var ghUITableViewDelegateProxyKey = "GHUITableViewDelegateProxyKey"

extension UITableView {
    
    var ghUITableViewDelegateProxy: GHUITableViewDelegateProxy? {
        set {
            objc_setAssociatedObject(self, &ghUITableViewDelegateProxyKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
        get {
            return objc_getAssociatedObject(self, &ghUITableViewDelegateProxyKey) as? GHUITableViewDelegateProxy
        }
    }
        
    private static let dispatchOnceTime: Void = {
        swizzle(UITableView.self)
    }()
    
    @objc open class func startAOP() {
        guard self === UITableView.self else {
            return
        }
        UITableView.dispatchOnceTime
    }
    
    // MARK: 交换的方法
    
    // 交换setdelegate的方法
    @objc func gh_setDelegate(_ delegate: UITableViewDelegate?) {
        
        // 使用GHUITableViewDelegateProxy替代原来系统的UITableViewDelegate
        self.ghUITableViewDelegateProxy = GHUITableViewDelegateProxy()
        self.ghUITableViewDelegateProxy?.delegate = delegate
        
        self.gh_setDelegate(self.ghUITableViewDelegateProxy)
    }
}
