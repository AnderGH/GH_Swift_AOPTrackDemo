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
    
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if self.delegate == nil {
            return
        }
        if (self.delegate?.responds(to: #selector(tableView(_:didSelectRowAt:)))) == false {
            return
        }
        
        UITableViewTrack.shared.trackTableView(tableView, didSelectRowAt: indexPath)
        
        self.delegate?.tableView?(tableView, didSelectRowAt: indexPath)
    }
}

private func swizzle(_ tableView: UITableView.Type) {
    let selectors: Array<Array<Selector>> = [
        [
            #selector(setter: tableView.delegate),
            #selector(tableView.gh_setDelegate(_:))
        ],
    ]
    for item in selectors {
        let originalSelector: Selector = item[0]
        let swizzledSelector: Selector = item[1]

        let originalMethod: Method? = class_getInstanceMethod(tableView, originalSelector)
        let swizzledMethod: Method? = class_getInstanceMethod(tableView, swizzledSelector)
        
        if originalMethod == nil {
            continue
        }
        
        let didAddMethod: Bool = class_addMethod(tableView, originalSelector, method_getImplementation(swizzledMethod!), method_getTypeEncoding(swizzledMethod!))
        if didAddMethod {
            class_replaceMethod(tableView, swizzledSelector, method_getImplementation(originalMethod!), method_getTypeEncoding(originalMethod!))
        } else {
            method_exchangeImplementations(originalMethod!, swizzledMethod!)
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
        guard self === UITableView.self else { return }
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
