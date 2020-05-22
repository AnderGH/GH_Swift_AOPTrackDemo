//
//  UIApplicationTrack.swift
//  testAOPDemo
//
//  Created by 管浩 on 2020/5/21.
//  Copyright © 2020 管浩. All rights reserved.
//

import UIKit

class UIApplicationTrack: NSObject {
    
    // MARK: 单例
    
    private static var instance: UIApplicationTrack = {
        let track = UIApplicationTrack.init()
        return track
    }()
    
    open class var shared: UIApplicationTrack {
        get {
            return instance
        }
    }
    
    override class func copy() -> Any {
        return instance
    }
    
    override func mutableCopy() -> Any {
        return UIApplicationTrack.instance
    }
    
    override init() {
        super.init()
    }
    
    // MARK: 属性
    
    private var recordParams: Array<String> = []
    
    // MARK: 拦截的方法
    
    func trackUIApplicationAction(_ action: String) -> Void {
        TrackingDataAnalysisHelper.analysisUIApplicationTrackingData(action)
    }
}
