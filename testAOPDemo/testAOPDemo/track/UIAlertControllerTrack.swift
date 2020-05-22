//
//  UIAlertControllerTrack.swift
//  testAOPDemo
//
//  Created by 管浩 on 2020/5/21.
//  Copyright © 2020 管浩. All rights reserved.
//

import UIKit

class UIAlertControllerTrack: NSObject {
    
    // MARK: 单例
    
    private static var instance: UIAlertControllerTrack = {
        let track = UIAlertControllerTrack.init()
        return track
    }()
    
    open class var shared: UIAlertControllerTrack {
        get {
            return instance
        }
    }
    
    override class func copy() -> Any {
        return instance
    }
    
    override func mutableCopy() -> Any {
        return UIAlertControllerTrack.instance
    }
    
    override init() {
        super.init()
    }
    
    // MARK: 属性
    
    private var recordParams: Dictionary<String, Dictionary<String, Any?>> = [:]
    
    // MARK: 拦截的方法
    
    open func trackAlertController(_ alertController: UIAlertController, title: String?) -> Void {
        
        if title == nil {
            return
        }
        
        let key: String = "UIAlertController" + String(alertController.hashValue)
        
        var infoDic: Dictionary<String, Any?> = self.recordParams[key] ?? [:]
        infoDic["title"] = title

        self.recordParams[key] = infoDic
    }
    
    open func trackAlertController(_ alertController: UIAlertController, message: String?) -> Void {
        
        if message == nil {
            return
        }
        
        let key: String = "UIAlertController" + String(alertController.hashValue)

        var infoDic: Dictionary<String, Any?> = self.recordParams[key] ?? [:]
        infoDic["message"] = message

        self.recordParams[key] = infoDic
    }
    
    open func trackAlertController(_ alertController: UIAlertController, action: UIAlertAction) -> Void {
        
        if action.title == nil {
            return
        }

        let key: String = "UIAlertController" + String(alertController.hashValue)

        var infoDic: Dictionary<String, Any?> = self.recordParams[key] ?? [:]
        if infoDic.count == 0 {
            return
        }
        var actions: Array<Dictionary<String, Any?>> = (infoDic["actions"] as? Array<Dictionary<String, Any?>>) ?? []
        var actionState: Dictionary<String, Any?> = [:]
        actionState["title"] = action.title!
        actionState["state"] = false
        actions.append(actionState)
        infoDic["actions"] = actions

        self.recordParams[key] = infoDic
    }
    
    open func trackAlertControllerActionCall(_ action: UIAlertAction) -> Void {
        
        if action.title == nil {
            return
        }
        
        let key: String = "UIAlertController" + action.ghControllerId

        let infoDic: Dictionary<String, Any?> = self.recordParams[key] ?? [:]
        if infoDic.count == 0 {
            return
        }
        
        let title: String = (infoDic["title"] as? String) ?? ""
        let message: String = (infoDic["message"] as? String) ?? ""
        
        self.recordParams.removeValue(forKey: key)
        
        TrackingDataAnalysisHelper.analysisUIAlertControllerTrackingData(withAlertControllerTitle: title, andAlertControllerMessage: message, callAlertAction: action)
    }
}
