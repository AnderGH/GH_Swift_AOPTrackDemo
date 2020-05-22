//
//  UIViewController_Extension.swift
//  testAOPDemo
//
//  Created by 管浩 on 2020/5/21.
//  Copyright © 2020 管浩. All rights reserved.
//

import UIKit

private func swizzle(_ viewController: UIViewController.Type) {
    let selectors: Array<Array<Selector>> = [
        [
            #selector(viewController.viewDidLoad),
            #selector(viewController.gh_viewDidLoad)
        ],
        [
            #selector(viewController.viewWillAppear(_:)),
            #selector(viewController.gh_viewWillAppear(animated:))
        ],
        [
            #selector(viewController.viewDidAppear(_:)),
            #selector(viewController.gh_viewDidAppear(animated:))
        ],
    ]
    
    for item in selectors {
        let originalSelector: Selector = item[0]
        let swizzledSelector: Selector = item[1]
        
        let originalMethod = class_getInstanceMethod(viewController, originalSelector)
        let swizzledMethod = class_getInstanceMethod(viewController, swizzledSelector)
        
        let didAddMethod: Bool = class_addMethod(viewController, originalSelector, method_getImplementation(swizzledMethod!), method_getTypeEncoding(swizzledMethod!))
        if didAddMethod {
            class_replaceMethod(viewController, swizzledSelector, method_getImplementation(originalMethod!), method_getTypeEncoding(originalMethod!))
        } else {
            method_exchangeImplementations(originalMethod!, swizzledMethod!)
        }
    }
}

extension UIViewController {
    
    // 确保aop不会重复执行
    private static let dispatchOnceTime: Void = {
        // 交换方法
        swizzle(UIViewController.self)
    }()
    
    @objc open class func startAOP() {
        guard self === UIViewController.self else { return }
        UIViewController.dispatchOnceTime
    }
    
    // MARK: 交换的方法
    
    @objc func gh_viewDidLoad() {
        
        UIViewControllerTrack.shared.trackViewDidLoad(ofController: self)
        
        self.gh_viewDidLoad()
    }
    
    @objc func gh_viewWillAppear(animated: Bool) {
        
        UIViewControllerTrack.shared.trackViewWillAppear(ofController: self)
        
        self.gh_viewWillAppear(animated: animated)
    }
    
    @objc func gh_viewDidAppear(animated: Bool) {
        
        UIViewControllerTrack.shared.trackViewDidAppear(ofController: self)
        
        self.gh_viewDidAppear(animated: animated)
    }
}
