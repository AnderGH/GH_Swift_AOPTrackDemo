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
        
        // 如果没有target和action，那么可能是被提前释放了
        guard let target = self.target, let action = self.action else {
            return
        }
        
        // 目前只对点击手势进行埋点，其他手势很多是系统的手势，暂不处理
        if let gesture = sender as? UITapGestureRecognizer {
            UITapGestureRecognizerTrack.shared.trackGRAction(gesture, action: action, target: target)
        }
        
        // 执行方法
        if ((target.responds(to: action)) == true) {
            target.perform(action, with: sender)
        }
    }
}

var ghGestureActionsKey: String = "GHGestureActionsKey"

extension UIResponder {
    /// 使用runtime给UIResponder扩展一个属性
    var ghGestureActions: [GHUITapGestureRecognizerAction]? {
        set {
            objc_setAssociatedObject(self, &ghGestureActionsKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
        get {
            return objc_getAssociatedObject(self, &ghGestureActionsKey) as? [GHUITapGestureRecognizerAction]
        }
    }
}

private func swizzle(_ gesture: UITapGestureRecognizer.Type) {
    let selectors: [[Selector]] = [
        [
            #selector(UITapGestureRecognizer.init(target:action:)),
            #selector(gesture.gh_init(target:action:))
        ],
        [
            #selector(gesture.addTarget(_:action:)),
            #selector(gesture.gh_addTarget(_:action:))
        ],
        [
            #selector(gesture.removeTarget(_:action:)),
            #selector(gesture.gh_removeTarget(_:action:))
        ],
    ]
    for item in selectors {
        let originalSelector: Selector = item[0]
        let swizzledSelector: Selector = item[1]
        
        guard let originalMethod: Method = class_getInstanceMethod(gesture, originalSelector) else {
            continue
        }
        guard let swizzledMethod: Method = class_getInstanceMethod(gesture, swizzledSelector) else {
            continue
        }
        
        let didAddMethod: Bool = class_addMethod(gesture, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
        if didAddMethod {
            class_replaceMethod(gesture, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
}

extension UITapGestureRecognizer {
    private static let dispatchOnceTime: Void = {
        swizzle(UITapGestureRecognizer.self)
    }()
    
    @objc open class func startAOP() {
        guard self === UITapGestureRecognizer.self else {
            return
        }
        UITapGestureRecognizer.dispatchOnceTime
    }
    
    // MARK: 交换的方法
    
    @objc func gh_init(target: Any?, action: Selector?) -> UIGestureRecognizer {
                
        if let target = target, let responder = target as? UIResponder {
            // 初始化判断
            if responder.ghGestureActions == nil {
                responder.ghGestureActions = []
            }
            
            // 一个手势对应一个GHUITapGestureRecognizerAction属性，再由target去强制有所有的GHUITapGestureRecognizerAction
            let ghAction = GHUITapGestureRecognizerAction()
            ghAction.target = (target as? UIResponder)
            ghAction.action = action
            responder.ghGestureActions?.append(ghAction)
            
            return self.gh_init(target: ghAction, action: #selector(ghAction.ghGestureRecognizerAction(sender:)))
        }
        return self.gh_init(target: target, action: action)
    }
    
    @objc func gh_addTarget(_ target: Any, action: Selector) {
        
        guard let responder = target as? UIResponder else {
            self.gh_addTarget(target, action: action)
            return
        }
        
        if responder.ghGestureActions == nil {
            responder.ghGestureActions = []
        }
        
        let ghAction = GHUITapGestureRecognizerAction()
        ghAction.target = (target as? UIResponder)
        ghAction.action = action
        responder.ghGestureActions?.append(ghAction)
        
        self.gh_addTarget(ghAction, action: #selector(ghAction.ghGestureRecognizerAction(sender:)))
    }
    
    @objc func gh_removeTarget(_ target: Any?, action: Selector?) {
        
        // 移除ghGestureActions数组中相应的GHUITapGestureRecognizerAction
        if let target = target, let responder = target as? UIResponder, let action = action {
            
            if let actions: [GHUITapGestureRecognizerAction] = responder.ghGestureActions {
                for index in 0 ..< actions.count {
                    let item: GHUITapGestureRecognizerAction = actions[index]
                    
                    // 非空判断
                    guard let ghTarget = item.target, let ghAction = item.action else {
                        continue
                    }
                    
                    // 对比classname和actiondescription
                    guard let objectClass: AnyClass = object_getClass(responder) else {
                        continue
                    }
                    let targetClass: String = NSStringFromClass(objectClass)
                    
                    guard let ghObjectClass: AnyClass = object_getClass(ghTarget) else {
                        continue
                    }
                    let ghTargetClass: String = NSStringFromClass(ghObjectClass)
                    
                    if (ghAction.description == action.description) && (targetClass == ghTargetClass) {
                        responder.ghGestureActions?.remove(at: index)
                        break
                    }
                }
            }
        }
        
        self.gh_removeTarget(target, action: action)
    }
}
