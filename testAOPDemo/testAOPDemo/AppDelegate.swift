//
//  AppDelegate.swift
//  testAOPDemo
//
//  Created by 管浩 on 2020/5/21.
//  Copyright © 2020 管浩. All rights reserved.
//

import UIKit
import WebKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    override init() {
        super.init();
        
        UIApplication.startAOP()
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        UIViewController.startAOP()
        UIControl.startAOP()
        UITapGestureRecognizer.startAOP()
        UITableView.startAOP()
        UICollectionView.startAOP()
        UITabBar.startAOP()
        UITabBarController.startAOP()
        UIAlertController.startAOP()
        WKWebView.startAOP()
        URLSession.startAOP()
        
        return true
    }

}

