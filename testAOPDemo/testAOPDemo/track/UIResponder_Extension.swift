//
//  UIResponder_Extension.swift
//  testAOPDemo
//
//  Created by 管浩 on 2020/5/21.
//  Copyright © 2020 管浩. All rights reserved.
//

import UIKit

extension UIResponder {
    
    /// get responder path
    /// - Returns: String
    func viewPathIdentifier() -> String {
        
        var viewPath: String = ""
        var responder: UIResponder? = self
        
        repeat {
            let objectClass: AnyClass? = object_getClass(responder!)
            if objectClass == nil {
                responder = responder?.next
                continue
            }
            let name: String = NSStringFromClass(objectClass!).components(separatedBy: ".").last ?? NSStringFromClass(objectClass!)
            viewPath += ("#" + name)
            if responder?.isKind(of: UIView.self) == true {
                let view: UIView? = responder as? UIView
                if view == nil {
                    responder = responder?.next
                    continue
                }
                let index: Int = view!.superview?.subviews.firstIndex(of: view!) ?? 0
                viewPath += ("[" + String(index) + "]")
            }
            responder = responder?.next
            
        } while responder != nil
        return viewPath
    }
}
