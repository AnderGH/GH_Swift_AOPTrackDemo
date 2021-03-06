//
//  UICollectionViewTrack.swift
//  testAOPDemo
//
//  Created by 管浩 on 2020/5/21.
//  Copyright © 2020 管浩. All rights reserved.
//

import UIKit

class UICollectionViewTrack: NSObject {
    
    // MARK: 单例
    
    private static var instance: UICollectionViewTrack = {
        let track = UICollectionViewTrack.init()
        return track
    }()
    
    open class var shared: UICollectionViewTrack {
        get {
            return instance
        }
    }
    
    override class func copy() -> Any {
        return instance
    }
    
    override func mutableCopy() -> Any {
        return UICollectionViewTrack.instance
    }
    
    override init() {
        super.init()
    }
    
    // MARK: 属性
    
    private var recordParams: [String : [String : Any?]] = [:]
    
    // MARK: 拦截的方法
    
    func trackCollectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) -> Void {
        TrackingDataAnalysisHelper.analysisUICollectionViewTrackingData(ofCollectionView: collectionView, didSelectItemAt: indexPath)
    }
}
