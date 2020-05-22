//
//  UITabBarTrack.swift
//  testAOPDemo
//
//  Created by 管浩 on 2020/5/21.
//  Copyright © 2020 管浩. All rights reserved.
//

import UIKit

class UITabBarTrack: NSObject {
    
    // MARK: 单例
    
    private static var instance: UITabBarTrack = {
        let track = UITabBarTrack.init()
        return track
    }()
    
    open class var shared: UITabBarTrack {
        get {
            return instance
        }
    }
    
    override class func copy() -> Any {
        return instance
    }
    
    override func mutableCopy() -> Any {
        return UITabBarTrack.instance
    }
    
    override init() {
        super.init()
    }
    
    // MARK: 属性
    
    private var recordParams: Dictionary<String, Dictionary<String, Any?>> = [:]
    
    // MARK: 拦截的方法
    
    open func trackTabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) -> Void {
        TrackingDataAnalysisHelper.analysisUITabBarTrackingData(ofTabBar: tabBar, didSelect: item)
    }
}
