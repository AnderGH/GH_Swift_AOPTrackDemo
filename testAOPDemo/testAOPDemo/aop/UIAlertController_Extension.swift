//
//  UIAlertController_Extension.swift
//  testAOPDemo
//
//  Created by 管浩 on 2020/5/21.
//  Copyright © 2020 管浩. All rights reserved.
//

import UIKit

private func swizzleControllerFunctions(_ alertController: UIAlertController.Type) {
    let selectors: [[Selector]] = [
        [
            #selector(setter: alertController.title),
            #selector(alertController.gh_setTitle(_:))
        ],
        [
            #selector(setter: alertController.message),
            #selector(alertController.gh_setMessage(_:))
        ],
        [
            #selector(alertController.addAction(_:)),
            #selector(alertController.gh_addAction(_:))
        ],
    ]
    for item in selectors {
        let originalSelector: Selector = item[0]
        let swizzledSelector: Selector = item[1]
        
        guard let originalMethod: Method = class_getInstanceMethod(alertController, originalSelector) else {
            continue
        }
        guard let swizzledMethod: Method = class_getInstanceMethod(alertController, swizzledSelector) else {
            continue
        }
        
        let didAddMethod: Bool = class_addMethod(alertController, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
        if didAddMethod {
            class_replaceMethod(alertController, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
}

extension UIAlertController {
    
    private static let dispatchOnceTime: Void = {
        swizzleControllerFunctions(UIAlertController.self)
        // 还需要交换UIAlertAction的方法
        UIAlertAction.startAOP()
    }()
    
    @objc open override class func startAOP() {
        guard self === UIAlertController.self else {
            return
        }
        UIAlertController.dispatchOnceTime
    }
    
    // MARK: 交换的方法

    @objc func gh_setTitle(_ title: String?) {
        
        UIAlertControllerTrack.shared.trackAlertController(self, title: title)
        
        self.gh_setTitle(title)
    }
    
    @objc func gh_setMessage(_ message: String?) {
        
        UIAlertControllerTrack.shared.trackAlertController(self, message: message)
        
        self.gh_setMessage(message)
    }
    
    @objc func gh_addAction(_ action: UIAlertAction) {
        
        action.ghControllerId = String(self.hashValue)
        UIAlertControllerTrack.shared.trackAlertController(self, action: action)
        
        self.gh_addAction(action)
    }
}

private func swizzleAlertActionFunctions(_ alertAction: UIAlertAction.Type) {
    let originalSelector: Selector = #selector(UIAlertAction.init(title:style:handler:))
    let swizzledSelector: Selector = #selector(UIAlertAction.gh_init(title:style:handler:))
    
    guard let originalMethod: Method = class_getInstanceMethod(object_getClass(alertAction), originalSelector) else {
        return
    }
    guard let swizzledMethod: Method = class_getInstanceMethod(object_getClass(alertAction), swizzledSelector) else {
        return
    }
    
    let didAddMethod: Bool = class_addMethod(object_getClass(alertAction), originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
    if didAddMethod {
        class_replaceMethod(object_getClass(alertAction), swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}

var ghControllerIdKey = "GHControllerIdKey"
var ghUIAlertActionHanderKey = "GHUIAlertActionHanderKey"

/// 定义一个类替换回调的block
class GHUIAlertAction: NSObject {
    var hander: ((UIAlertAction) -> Void)?
}

extension UIAlertAction {
    var ghControllerId: String {
        set {
            objc_setAssociatedObject(self, &ghControllerIdKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
        get {
            return (objc_getAssociatedObject(self, &ghControllerIdKey) as? String) ?? "ghControllerId"
        }
    }
    static var ghAlertActionHander: GHUIAlertAction? {
        set {
            objc_setAssociatedObject(self, &ghUIAlertActionHanderKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
        get {
            return objc_getAssociatedObject(self, &ghUIAlertActionHanderKey) as? GHUIAlertAction
        }
    }
    
    private static let dispatchOnceTime: Void = {
        swizzleAlertActionFunctions(UIAlertAction.self)
    }()
    
    @objc open class func startAOP() {
        guard self === UIAlertAction.self else {
            return
        }
        UIAlertAction.dispatchOnceTime
    }
    
    // MARK: 交换的方法
    
    @objc class func gh_init(title: String?, style: UIAlertAction.Style, handler: ((UIAlertAction) -> Void)? = nil) -> UIAlertAction {
        
        let actionHander: GHUIAlertAction = GHUIAlertAction.init()
        self.ghAlertActionHander = actionHander
        actionHander.hander = { (alertAction) in
            
            UIAlertControllerTrack.shared.trackAlertControllerActionCall(alertAction)
            
            if let handler = handler {
                handler(alertAction)
            }
        }
        return self.gh_init(title: title, style: style, handler: actionHander.hander)
    }
}
