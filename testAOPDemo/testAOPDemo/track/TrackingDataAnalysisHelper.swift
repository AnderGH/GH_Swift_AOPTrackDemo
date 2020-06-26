//
//  TrackingDataAnalysisHelper.swift
//  testAOPDemo
//
//  Created by 管浩 on 2020/5/21.
//  Copyright © 2020 管浩. All rights reserved.
//

import UIKit
import WebKit

class TrackingDataAnalysisHelper: NSObject {
    
    class func analysisUIViewControllerTrackingData(ofController controller: UIViewController, pageDurationTime: String) {
        
        guard let objectClass: AnyClass = object_getClass(controller) else {
            return
        }
        
        let controllerName: String = NSStringFromClass(objectClass)
        
        var viewPath: String = ""
        viewPath += ("#time=" + pageDurationTime)
        viewPath += controller.viewPathIdentifier()
    }
    
    class func analysisUIControlTrackingData(ofControl control: UIControl, action: Selector, target: Any, event: UIEvent) {
        
        guard let objectClass: AnyClass = object_getClass(target) else {
            return
        }
        
        let actionName: String = NSStringFromSelector(action)
        let targetClass: String = NSStringFromClass(objectClass)
        var viewPath: String = "#" + actionName + control.viewPathIdentifier()
        
        // 如果是按钮，加上额外参数
        guard control.isKind(of: UIButton.self) == true else {
            return
        }
        guard let button: UIButton = control as? UIButton else {
            return
        }
        viewPath += ("#currentTitle=" + (button.currentTitle ?? ""))
        viewPath += ("#state=" + String(button.state.rawValue))
        viewPath += ("#enabled=" + String(button.isEnabled))
        viewPath += ("#selected=" + String(button.isSelected))
    }
    
    class func analysisUITapGestureRecognizerTrackingData(ofGesture gesture: UITapGestureRecognizer, action: Selector, target: UIResponder) {
        
        let actionName: String = action.description
        var viewPath: String = "#" + actionName
        
        if gesture.view != nil {
            viewPath += (gesture.view?.viewPathIdentifier() ?? "")
        } else {
            viewPath += target.viewPathIdentifier()
        }
        
        guard let objectClass: AnyClass = object_getClass(target) else {
            return
        }
        let targetClass: String = NSStringFromClass(objectClass)
    }
    
    class func analysisUITableViewTrackingData(ofTableView tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let controller = TrackUtils.getController(of: tableView) else {
            return
        }
        guard let objectClass = object_getClass(controller) else {
            return
        }
        let targetClass: String = NSStringFromClass(objectClass)
        let actionName: String = "tableView:didSelectRowAt:"
        var viewPath: String = "#" + actionName
        viewPath += tableView.viewPathIdentifier()
        viewPath += ("#section=" + String(indexPath.section))
        viewPath += ("#row=" + String(indexPath.row))
        
    }
    
    class func analysisUICollectionViewTrackingData(ofCollectionView collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard let controller = TrackUtils.getController(of: collectionView) else {
            return
        }
        guard let objectClass = object_getClass(controller) else {
            return
        }
        let targetClass: String = NSStringFromClass(objectClass)
        let actionName: String = "collectionView:didSelectItemAt:"
        var viewPath: String = "#" + actionName
        viewPath += collectionView.viewPathIdentifier()
        viewPath += ("#section=" + String(indexPath.section))
        viewPath += ("#item=" + String(indexPath.item))
        
    }
    
    class func analysisUITabBarTrackingData(ofTabBar tabBar: UITabBar, didSelect item: UITabBarItem) {
        
        guard let controller = TrackUtils.getController(of: tabBar) else {
            return
        }
        guard let objectClass = object_getClass(controller) else {
            return
        }
        let targetClass: String = NSStringFromClass(objectClass)
        let actionName: String = "tabBar:didSelect:"
        var viewPath: String = "#" + actionName
        viewPath += tabBar.viewPathIdentifier()
        var actionIndex: String = ""
        if let index: Int = tabBar.items?.firstIndex(of: item) {
            actionIndex = String(index)
        }
        viewPath += ("#selectedIndex=" + actionIndex)
        
    }
    
    class func analysisUITabBarControllerTrackingData(ofTabBarController tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        
        guard let objectClass = object_getClass(tabBarController) else {
            return
        }
        let targetClass: String = NSStringFromClass(objectClass)
        let actionName: String = "tabBarController:didSelect:"
        var viewPath: String = "#" + actionName
        viewPath += tabBarController.viewPathIdentifier()
        viewPath += ("#selectedIndex=" + String(tabBarController.selectedIndex))
        
    }
    
    class func analysisUIAlertControllerTrackingData(withAlertControllerTitle title: String, andAlertControllerMessage message: String, callAlertAction alertAction: UIAlertAction) {
        
        // 获取弹出UIAlertController的控制器
        let window = UIApplication.shared.delegate?.window
        if window == nil {
            return
        }
        guard var currentVC = window??.rootViewController else {
            return
        }
        while true {
            var nextVC: UIViewController?
            if currentVC.isKind(of: UINavigationController.self) {
                nextVC = (currentVC as? UINavigationController)?.visibleViewController
            } else if currentVC.isKind(of: UITabBarController.self) {
                nextVC = (currentVC as? UITabBarController)?.selectedViewController
            } else if currentVC.isKind(of: UIAlertController.self) {
                return
            } else {
                nextVC = currentVC.presentedViewController
            }
            guard let next = nextVC else {
                break
            }
            currentVC = next
        }
        
        guard let objectClass = object_getClass(currentVC) else {
            return
        }
        let targetClass: String = NSStringFromClass(objectClass)
        var viewPath: String = "#UIAlertController"
        viewPath += currentVC.viewPathIdentifier()
        viewPath += ("#UIAlertControllerTitle=" + title)
        viewPath += ("#UIAlertControllerMessage=" + message)
        viewPath += "#UIAlertAction"
        viewPath += ("#UIAlertAction.Style=" + String(alertAction.style.rawValue))
        viewPath += ("#UIAlertActionTitle=" + (alertAction.title ?? ""))
        
    }
    
    class func analysisUIApplicationTrackingData(_ action: String) {
        
    }
    
    class func analysisWKWebViewTrackingData(_ webView: WKWebView, url: String, duration: String, error: Error?) {
        
    }
    
    class func analysisURLDataSessionTrackingData(_ url: String, duration: String, httpBodyLength: String, httpMethod: String, error: Error?) {
        
    }
    
    class func analysisURLDownloadSessionTrackingData(_ url: String, duration: String, httpBodyLength: String, httpMethod: String, isImage: Bool, error: Error?) {
        
    }
    
    class func analysisURLUploadSessionTrackingData(_ url: String, duration: String, httpBodyLength: String, httpMethod: String, error: Error?) {
        
    }
}
