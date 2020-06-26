//
//  UITabBarControllerTrack.swift
//  testAOPDemo
//
//  Created by 管浩 on 2020/5/21.
//  Copyright © 2020 管浩. All rights reserved.
//

import UIKit

class UITabBarControllerTrack: NSObject {
    
    // MARK: 单例
    
    private static var instance: UITabBarControllerTrack = {
        let track = UITabBarControllerTrack.init()
        return track
    }()
    
    open class var shared: UITabBarControllerTrack {
        get {
            return instance
        }
    }
    
    override class func copy() -> Any {
        return instance
    }
    
    override func mutableCopy() -> Any {
        return UITabBarControllerTrack.instance
    }
    
    override init() {
        super.init()
    }
    
    // MARK: 属性
    
    private var recordParams: [String : [String : Any?]] = [:]
    
    // MARK: 拦截的方法
    
    func trackTabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) -> Void {
        TrackingDataAnalysisHelper.analysisUITabBarControllerTrackingData(ofTabBarController: tabBarController, didSelect: viewController)
    }
}
