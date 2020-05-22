//
//  TrackUtils.swift
//  testAOPDemo
//
//  Created by 管浩 on 2020/5/21.
//  Copyright © 2020 管浩. All rights reserved.
//

import UIKit

public class TrackUtils: NSObject {
    
    /// Date to String
    /// - Parameter date: date
    /// - Parameter format: format
    /// - Returns: string
    public class func stringFromDate(_ date: Date, with formatString: String) -> String {
        let format: DateFormatter = DateFormatter.init()
        format.dateFormat = formatString
        return format.string(from: date)
    }
    
    /// duration from time to time
    /// - Parameters:
    ///   - start: start
    ///   - end: end
    /// - Returns: milliseconds
    public static func duration(From startTime: String, To endTime: String) -> Int {
        let format: DateFormatter = DateFormatter.init()
        format.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        
        let startDate: Date = format.date(from: startTime)!
        let endDate: Date = format.date(from: endTime)!
        
        let duration: TimeInterval = endDate.timeIntervalSince(startDate)
        return Int(duration * 1000);
    }
    
    /// get controller of view
    /// - Parameter view: view
    /// - Returns: UIViewController?
    public static func getController(of view: UIView) -> UIViewController? {
        var controller: UIViewController?
        var next: UIView? = view
        while (next != nil) {
            let nextResponder = next!.next
            if (nextResponder is UIViewController) {
                controller = (nextResponder as! UIViewController)
                break
            }
            next = next!.superview
        }
        return controller
    }
}
