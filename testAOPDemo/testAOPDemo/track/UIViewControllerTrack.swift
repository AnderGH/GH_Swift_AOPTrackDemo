//
//  UIViewControllerTrack.swift
//  testAOPDemo
//
//  Created by 管浩 on 2020/5/21.
//  Copyright © 2020 管浩. All rights reserved.
//

import UIKit

class UIViewControllerTrack: NSObject {
    
    // MARK: 单例
    
    private static var instance: UIViewControllerTrack = {
        let track = UIViewControllerTrack.init()
        return track
    }()
    
    open class var shared: UIViewControllerTrack {
        get {
            return instance
        }
    }
    
    override class func copy() -> Any {
        return instance
    }
    
    override func mutableCopy() -> Any {
        return UIViewControllerTrack.instance
    }
    
    override init() {
        super.init()
    }
    
    // MARK: 属性
    
    private var recordParams: Dictionary<String, Dictionary<String, Any?>> = [:]
    
    // MARK: 拦截的方法
    
    open func trackViewDidLoad(ofController controller: UIViewController) {
        let objectClass: AnyClass? = object_getClass(controller)
        if objectClass == nil {
            return
        }
        let controllerName: String = NSStringFromClass(objectClass!)
        let key: String = controllerName + String(self.hashValue)
        
        var infoDic: Dictionary<String, Any?> = [:]
        infoDic["viewDidLoadTime"] = TrackUtils.stringFromDate(Date.init(), with: "yyyy-MM-dd HH:mm:ss.SSS")
        
        self.recordParams[key] = infoDic
    }
    
    open func trackViewWillAppear(ofController controller: UIViewController) {
        let objectClass: AnyClass? = object_getClass(controller)
        if objectClass == nil {
            return
        }
        let controllerName: String = NSStringFromClass(objectClass!)
        let key: String = controllerName + String(self.hashValue)
        
        var infoDic: Dictionary<String, Any?> = self.recordParams[key] ?? [:]
        if infoDic.count == 0 {
            return
        }
        infoDic["viewWillAppearTime"] = TrackUtils.stringFromDate(Date.init(), with: "yyyy-MM-dd HH:mm:ss.SSS")
        self.recordParams[key] = infoDic
    }
    
    open func trackViewDidAppear(ofController controller: UIViewController) {
        let objectClass: AnyClass? = object_getClass(controller)
        if objectClass == nil {
            return
        }
        let controllerName: String = NSStringFromClass(objectClass!)
        let key: String = controllerName + String(self.hashValue)
        
        // 获取缓存的数据
        let infoDic: Dictionary<String, Any?> = self.recordParams[key] ?? [:]
        if infoDic.count == 0 {
            return
        }
        // count the duration time
        let viewDidLoadTime: String? = infoDic["viewDidLoadTime"] as? String
        if viewDidLoadTime == nil {
            return
        }
        let viewDidAppearTime: String = TrackUtils.stringFromDate(Date.init(), with: "yyyy-MM-dd HH:mm:ss.SSS")
        let duration = TrackUtils.duration(From: viewDidLoadTime!, To: viewDidAppearTime)
        if (duration > 10000) || (duration < 0) {
            return
        }
        
        // 删除数据
        self.recordParams.removeValue(forKey: key)
        
        // 分析方法
        TrackingDataAnalysisHelper.analysisUIViewControllerTrackingData(ofController: controller, pageDurationTime: String(duration))
    }
}
