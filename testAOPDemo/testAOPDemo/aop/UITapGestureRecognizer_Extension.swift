//
//  UITapGestureRecognizer_Extension.swift
//  testAOPDemo
//
//  Created by 管浩 on 2020/5/21.
//  Copyright © 2020 管浩. All rights reserved.
//

import UIKit

/// 自定义一个action类，由此类的实例对象替代外部传入的action
class GHUITapGestureRecognizerAction: NSObject {
    
    // 弱应用，防止循环应用
    weak var target: UIResponder?
    var action: Selector?
    
    @objc func ghGestureRecognizerAction(sender: UIGestureRecognizer?) -> Void {
        if self.target == nil {
            return
        }
        if self.action == nil {
            return
        }
        
        UITapGestureRecognizerTrack.shared.trackGRAction(sender as? UITapGestureRecognizer, action: self.action!, target: self.target)
        
        if ((target?.responds(to: action)) == true) {
            target?.perform(action, with: sender)
        }
    }
}

var ghGestureActionsKey: String = "GHGestureActionsKey"

extension UIResponder {
    /// 使用runtime给UIResponder扩展一个属性
    var ghGestureActions: Array<GHUITapGestureRecognizerAction>? {
        set {
            objc_setAssociatedObject(self, &ghGestureActionsKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
        get {
            return objc_getAssociatedObject(self, &ghGestureActionsKey) as? Array<GHUITapGestureRecognizerAction>
        }
    }
}

private func swizzle(_ gesture: UITapGestureRecognizer.Type) {
    let selectors: Array<Array<Selector>> = [
        [
            #selector(UITapGestureRecognizer.init(target:action:)),
            #selector(gesture.gh_init(target:action:))
        ],
        [
            #selector(gesture.addTarget(_:action:)),
            #selector(gesture.gh_addTarget(_:action:))
        ],
    ]
    for item in selectors {
        let originalSelector: Selector = item[0]
        let swizzledSelector: Selector = item[1]
        
        let originalMethod: Method? = class_getInstanceMethod(gesture, originalSelector)
        let swizzledMethod: Method? = class_getInstanceMethod(gesture, swizzledSelector)
        
        if originalMethod == nil {
            continue
        }
        
        let didAddMethod: Bool = class_addMethod(gesture, originalSelector, method_getImplementation(swizzledMethod!), method_getTypeEncoding(swizzledMethod!))
        if didAddMethod {
            class_replaceMethod(gesture, swizzledSelector, method_getImplementation(originalMethod!), method_getTypeEncoding(originalMethod!))
        } else {
            method_exchangeImplementations(originalMethod!, swizzledMethod!)
        }
    }
}

extension UITapGestureRecognizer {
    private static let dispatchOnceTime: Void = {
        swizzle(UITapGestureRecognizer.self)
    }()
    
    @objc open class func startAOP() {
        guard self === UITapGestureRecognizer.self else { return }
        UITapGestureRecognizer.dispatchOnceTime
    }
    
    // MARK: 交换的方法
    
    @objc func gh_init(target: Any?, action: Selector?) -> UIGestureRecognizer {
        if target == nil {
            return self.gh_init(target: target, action: action);
        }
        if (target as? UIResponder) == nil {
            return self.gh_init(target: target, action: action);
        }
        
        // 初始化判断
        if (target as? UIResponder)?.ghGestureActions == nil {
            (target as? UIResponder)?.ghGestureActions = []
        }
        
        // 一个手势对应一个GHUITapGestureRecognizerAction属性，再由target去强制有所有的GHUITapGestureRecognizerAction
        let ghAction = GHUITapGestureRecognizerAction()
        ghAction.target = (target as? UIResponder)
        ghAction.action = action
        
        (target as? UIResponder)?.ghGestureActions?.append(ghAction)
        
        return self.gh_init(target: ghAction, action: #selector(ghAction.ghGestureRecognizerAction(sender:)))
    }
    
    @objc func gh_addTarget(_ target: Any, action: Selector) {
        if (target as? UIResponder) == nil {
            return self.gh_addTarget(target, action: action);
        }
        
        if (target as? UIResponder)?.ghGestureActions == nil {
            (target as? UIResponder)?.ghGestureActions = []
        }
        
        let ghAction = GHUITapGestureRecognizerAction()
        ghAction.target = (target as? UIResponder)
        ghAction.action = action
        
        (target as? UIResponder)?.ghGestureActions?.append(ghAction)
        
        return self.gh_addTarget(ghAction, action: #selector(ghAction.ghGestureRecognizerAction(sender:)))
    }
}
