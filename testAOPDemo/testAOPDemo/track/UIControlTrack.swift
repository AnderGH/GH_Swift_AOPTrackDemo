//
//  UIControlTrack.swift
//  testAOPDemo
//
//  Created by 管浩 on 2020/5/21.
//  Copyright © 2020 管浩. All rights reserved.
//

import UIKit

class UIControlTrack: NSObject {
    
    // MARK: 单例
    
    private static var instance: UIControlTrack = {
        let track = UIControlTrack.init()
        return track
    }()
    
    open class var shared: UIControlTrack {
        get {
            return instance
        }
    }
    
    override class func copy() -> Any {
        return instance
    }
    
    override func mutableCopy() -> Any {
        return UIControlTrack.instance
    }
    
    override init() {
        super.init()
    }
    
    // MARK: 属性
    
    private var recordParams: Dictionary<String, Dictionary<String, Any?>> = [:]
    
    // MARK: 拦截的方法
    
    open func trackButtonAction(_ control: UIControl, action: Selector, target: Any?, event: UIEvent?) -> Void {
        if target == nil {
            return
        }
        
        if object_getClass(target) == nil {
            return
        }
        
        TrackingDataAnalysisHelper.analysisUIControlTrackingData(ofControl: control, action: action, target: target, event: event)
    }
}
