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
                
        let objectClass: AnyClass? = object_getClass(controller)
        if objectClass == nil {
            return
        }
        let controllerName: String = NSStringFromClass(objectClass!)
        
        var viewPath: String = ""
        viewPath += ("#time=" + pageDurationTime)
        viewPath += controller.viewPathIdentifier()
    }
    
    class func analysisUIControlTrackingData(ofControl control: UIControl, action: Selector, target: Any?, event: UIEvent?) {
        
        let actionName: String = NSStringFromSelector(action)
        let targetClass: String = NSStringFromClass(object_getClass(target)!)
        var viewPath: String = "#" + actionName + control.viewPathIdentifier()
        
        if control.isKind(of: UIButton.self) {
            let button: UIButton? = control as? UIButton
            if button != nil {
                viewPath += ("#currentTitle=" + (button!.currentTitle ?? ""))
                viewPath += ("#state=" + String(button!.state.rawValue))
                viewPath += ("#enabled=" + String(button!.isEnabled))
                viewPath += ("#selected=" + String(button!.isSelected))
            }
        }
    }
    
    class func analysisUITapGestureRecognizerTrackingData(ofGesture gesture: UITapGestureRecognizer, action: Selector, target: UIResponder) {
        
        let actionName: String = action.description
        var viewPath: String = "#" + actionName
        if gesture.view != nil {
            viewPath += gesture.view!.viewPathIdentifier()
        } else {
            viewPath += target.viewPathIdentifier()
        }
        let targetClass: String = NSStringFromClass(object_getClass(target)!)
    }
    
    class func analysisUITableViewTrackingData(ofTableView tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let controller = TrackUtils.getController(of: tableView)
        if controller == nil {
            return
        }
        if object_getClass(controller) == nil {
            return
        }
        let targetClass: String = NSStringFromClass(object_getClass(controller)!)
        let actionName: String = "tableView:didSelectRowAt:"
        var viewPath: String = "#" + actionName
        viewPath += tableView.viewPathIdentifier()
        viewPath += ("#section=" + String(indexPath.section))
        viewPath += ("#row=" + String(indexPath.row))
        
    }
    
    class func analysisUICollectionViewTrackingData(ofCollectionView collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let controller = TrackUtils.getController(of: collectionView)
        if controller == nil {
            return
        }
        if object_getClass(controller) == nil {
            return
        }
        let targetClass: String = NSStringFromClass(object_getClass(controller)!)
        let actionName: String = "collectionView:didSelectItemAt:"
        var viewPath: String = "#" + actionName
        viewPath += collectionView.viewPathIdentifier()
        viewPath += ("#section=" + String(indexPath.section))
        viewPath += ("#item=" + String(indexPath.item))
        
    }
    
    class func analysisUITabBarTrackingData(ofTabBar tabBar: UITabBar, didSelect item: UITabBarItem) {
        
        let controller = TrackUtils.getController(of: tabBar)
        if controller == nil {
            return
        }
        if object_getClass(controller) == nil {
            return
        }
        let targetClass: String = NSStringFromClass(object_getClass(controller)!)
        let actionName: String = "tabBar:didSelect:"
        var viewPath: String = "#" + actionName
        viewPath += tabBar.viewPathIdentifier()
        let index: Int? = tabBar.items?.firstIndex(of: item)
        var actionIndex: String = ""
        if index != nil {
            actionIndex = String(index!)
        }
        viewPath += ("#selectedIndex=" + actionIndex)
        
    }
    
    class func analysisUITabBarControllerTrackingData(ofTabBarController tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        
        if object_getClass(tabBarController) == nil {
            return
        }
        let targetClass: String = NSStringFromClass(object_getClass(tabBarController)!)
        let actionName: String = "tabBarController:didSelect:"
        var viewPath: String = "#" + actionName
        viewPath += tabBarController.viewPathIdentifier()
        viewPath += ("#selectedIndex=" + String(tabBarController.selectedIndex))
        
    }
    
    class func analysisUIAlertControllerTrackingData(withAlertControllerTitle title: String, andAlertControllerMessage message: String, callAlertAction alertAction: UIAlertAction) {
        
        // get last controller
        let window: UIWindow? = UIApplication.shared.delegate?.window ?? nil
        var currentVC: UIViewController? = window?.rootViewController
        if currentVC == nil {
            return
        }
        while currentVC != nil {
            var nextVC: UIViewController?
            if currentVC?.isKind(of: UINavigationController.self) == true {
                nextVC = (currentVC as! UINavigationController).visibleViewController
            } else if (currentVC?.isKind(of: UITabBarController.self)) == true {
                nextVC = (currentVC as! UITabBarController).selectedViewController
            } else if (currentVC?.isKind(of: UIAlertController.self)) == true {
                return
            } else {
                nextVC = currentVC?.presentedViewController
            }
            if nextVC != nil {
                currentVC = nextVC
            } else {
                break
            }
        }
        
        if object_getClass(currentVC) == nil {
            return
        }
        let targetClass: String = NSStringFromClass(object_getClass(currentVC)!)
        
        var viewPath: String = "#UIAlertController"
        viewPath += currentVC!.viewPathIdentifier()
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
