//
//  UIControl_Extension.swift
//  testAOPDemo
//
//  Created by 管浩 on 2020/5/21.
//  Copyright © 2020 管浩. All rights reserved.
//

import UIKit

private func swizzle(_ control: UIControl.Type) {
    let selectors: [[Selector]] = [
        [
            #selector(control.sendAction(_:to:for:)),
            #selector(control.gh_sendAction(_:to:for:))
        ],
    ]
    for item in selectors {
        let originalSelector: Selector = item[0]
        let swizzledSelector: Selector = item[1]
                
        guard let originalMethod: Method = class_getInstanceMethod(control, originalSelector) else {
            continue
        }
        guard let swizzledMethod: Method = class_getInstanceMethod(control, swizzledSelector) else {
            continue
        }
        
        let didAddMethod: Bool = class_addMethod(control, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
        if didAddMethod {
            class_replaceMethod(control, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
}

extension UIControl {
    
    // 确保aop不会重复执行
    private static let dispatchOnceTime: Void = {
        // 交换方法
        swizzle(UIControl.self)
    }()
    
    @objc open class func startAOP() {
        guard self === UIControl.self else {
            return
        }
        UIControl.dispatchOnceTime
    }
    
    // MARK: 交换的方法
    
    @objc func gh_sendAction(_ action: Selector, to target: Any?, for event: UIEvent?) {
        
        // 正常的点击方法才需要埋点，非正常的忽略
        if let target = target, let event = event {
            UIControlTrack.shared.trackButtonAction(self, action: action, target: target, event: event)
        }
        
        self.gh_sendAction(action, to: target, for: event)
    }
}
