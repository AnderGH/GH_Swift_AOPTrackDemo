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
    
    private var recordParams: [String : [String : Any?]] = [:]
    
    // MARK: 拦截的方法
    
    func trackViewDidLoad(ofController controller: UIViewController) {
        
        guard let objectClass: AnyClass = object_getClass(controller) else {
            return
        }
        
        let controllerName: String = NSStringFromClass(objectClass)
        let key: String = controllerName + String(self.hashValue)
        
        var infoDic: [String : Any?] = [:]
        infoDic["viewDidLoadTime"] = TrackUtils.stringFromDate(Date.init(), with: "yyyy-MM-dd HH:mm:ss.SSS")
        
        self.recordParams[key] = infoDic
    }
    
    func trackViewWillAppear(ofController controller: UIViewController) {
        
        guard let objectClass: AnyClass = object_getClass(controller) else {
            return
        }
        
        let controllerName: String = NSStringFromClass(objectClass)
        let key: String = controllerName + String(self.hashValue)
        
        guard var infoDic: [String : Any?] = self.recordParams[key] else {
            return
        }
        infoDic["viewWillAppearTime"] = TrackUtils.stringFromDate(Date.init(), with: "yyyy-MM-dd HH:mm:ss.SSS")
        self.recordParams[key] = infoDic
    }
    
    func trackViewDidAppear(ofController controller: UIViewController) {
        
        guard let objectClass: AnyClass = object_getClass(controller) else {
            return
        }
        let controllerName: String = NSStringFromClass(objectClass)
        let key: String = controllerName + String(self.hashValue)
        
        // 获取缓存的数据
        guard let infoDic: [String : Any?] = self.recordParams[key] else {
            return
        }
        // 开始加载的时间字段
        guard let timeString = infoDic["viewDidLoadTime"] else {
            return
        }
        guard let viewDidLoadTime: String = timeString as? String else {
            return
        }
        let viewDidAppearTime: String = TrackUtils.stringFromDate(Date.init(), with: "yyyy-MM-dd HH:mm:ss.SSS")
        let duration = TrackUtils.duration(From: viewDidLoadTime, To: viewDidAppearTime)
        
        // 删除数据
        self.recordParams.removeValue(forKey: key)
        
        // 分析方法
        TrackingDataAnalysisHelper.analysisUIViewControllerTrackingData(ofController: controller, pageDurationTime: String(duration))
    }
}
