//
//  UICollectionView_Extension.swift
//  testAOPDemo
//
//  Created by 管浩 on 2020/5/21.
//  Copyright © 2020 管浩. All rights reserved.
//

import UIKit

class GHUICollectionViewDelegateProxy: NSObject, UICollectionViewDelegate {
    
    weak var delegate: UICollectionViewDelegate?
    
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
    
    // MARK: UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard let delegate = self.delegate else {
            return
        }
        guard delegate.responds(to: #selector(collectionView(_:didSelectItemAt:))) else {
            return
        }
        
        UICollectionViewTrack.shared.trackCollectionView(collectionView, didSelectItemAt: indexPath)
        
        delegate.collectionView?(collectionView, didSelectItemAt: indexPath)
    }
}

private func swizzle(_ collectionView: UICollectionView.Type) {
    let selectors: [[Selector]] = [
        [
            #selector(setter: collectionView.delegate),
            #selector(collectionView.gh_setDelegate(_:))
        ],
    ]
    for item in selectors {
        let originalSelector: Selector = item[0]
        let swizzledSelector: Selector = item[1]
        
        guard let originalMethod: Method = class_getInstanceMethod(collectionView, originalSelector) else {
            continue
        }
        guard let swizzledMethod: Method = class_getInstanceMethod(collectionView, swizzledSelector) else {
            continue
        }
        
        let didAddMethod: Bool = class_addMethod(collectionView, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
        if didAddMethod {
            class_replaceMethod(collectionView, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
}

var ghUICollectionViewDelegateProxyKey = "GHUICollectionViewDelegateProxyKey"

extension UICollectionView {
    var ghUICollectionViewDelegateProxy: GHUICollectionViewDelegateProxy? {
        set {
            objc_setAssociatedObject(self, &ghUICollectionViewDelegateProxyKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
        get {
            return objc_getAssociatedObject(self, &ghUICollectionViewDelegateProxyKey) as? GHUICollectionViewDelegateProxy
        }
    }
    
    private static let dispatchOnceTime: Void = {
        swizzle(UICollectionView.self)
    }()
    
    @objc open class func startAOP() {
        guard self === UICollectionView.self else {
            return
        }
        UICollectionView.dispatchOnceTime
    }
    
    // MARK: 交换的方法

    @objc func gh_setDelegate(_ delegate: UICollectionViewDelegate?) {
        
        self.ghUICollectionViewDelegateProxy = GHUICollectionViewDelegateProxy()
        self.ghUICollectionViewDelegateProxy?.delegate = delegate
        
        self.gh_setDelegate(self.ghUICollectionViewDelegateProxy)
    }
}
