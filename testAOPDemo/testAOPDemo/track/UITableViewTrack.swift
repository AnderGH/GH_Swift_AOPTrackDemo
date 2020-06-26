//
//  UITableViewTrack.swift
//  testAOPDemo
//
//  Created by 管浩 on 2020/5/21.
//  Copyright © 2020 管浩. All rights reserved.
//

import UIKit

class UITableViewTrack: NSObject {
    
    // MARK: 单例
    
    private static var instance: UITableViewTrack = {
        let track = UITableViewTrack.init()
        return track
    }()
    
    open class var shared: UITableViewTrack {
        get {
            return instance
        }
    }
    
    override class func copy() -> Any {
        return instance
    }
    
    override func mutableCopy() -> Any {
        return UITableViewTrack.instance
    }
    
    override init() {
        super.init()
    }
    
    // MARK: 属性
    
    private var recordParams: [String : [String : Any?]] = [:]
    
    // MARK: 拦截的方法
    
    func trackTableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) -> Void {
        
        TrackingDataAnalysisHelper.analysisUITableViewTrackingData(ofTableView: tableView, didSelectRowAt: indexPath)
    }
}
