//
//  NSURLSession_Extension.swift
//  testAOPDemo
//
//  Created by 管浩 on 2020/5/21.
//  Copyright © 2020 管浩. All rights reserved.
//

import UIKit

/*
 请求有一个特殊的地方就是多线程，其他空间都是UI层面的，所以不会存在多线程的情况
 为了保证多线程请求的安全性，所以用单例持有一个字典的属性，使用自定义队列同步操作来确保对此字典的线程安全
 */
class GHURLSessionHandersHold: NSObject {
    
    // 单例
    private static var instance: GHURLSessionHandersHold = {
        let track = GHURLSessionHandersHold.init()
        return track
    }()
    open class var shared: GHURLSessionHandersHold {
        get {
            return instance
        }
    }
    override class func copy() -> Any {
        return instance
    }
    override func mutableCopy() -> Any {
        return GHURLSessionHandersHold.instance
    }
    
    private var queue: DispatchQueue!
    private var ghURLSessionHanders: Dictionary<String, Any> = [:]
    
    override init() {
        super.init()
        
        // 初始化自定义队列
        self.queue = DispatchQueue.init(label: "com.urlsession.handers")
    }
    
    /// 保存数据的方法
    func saveValue(_ value: Any, for key: String) {
        _ = self.queue.sync {
            self.ghURLSessionHanders[key] = value
        }
    }
    
    /// 移除数据的方法
    func removeValue(for key: String) {
        _ = self.queue.sync {
            self.ghURLSessionHanders.removeValue(forKey: key)
        }
    }
}

private func swizzle(_ session: URLSession.Type) {
    let selectors: Array<Array<Selector>> = [
        [
            #selector((URLSession.shared.dataTask(with:completionHandler:)) as ((URLRequest, (@escaping (Data?, URLResponse?, Error?) -> Void)) -> URLSessionDataTask)),
            #selector(URLSession.shared.gh_dataTaskWithRequest(_:completionHandler:))
        ],
        [
            #selector((URLSession.shared.dataTask(with:completionHandler:)) as ((URL, (@escaping (Data?, URLResponse?, Error?) -> Void)) -> URLSessionDataTask)),
            #selector(URLSession.shared.gh_dataTaskWithUrl(_:completionHandler:))
        ],
        [
            #selector((URLSession.shared.downloadTask(with:completionHandler:)) as ((URLRequest, (@escaping (URL?, URLResponse?, Error?) -> Void)) -> URLSessionDownloadTask)),
            #selector(URLSession.shared.gh_downloadTaskWithRequest(_:completionHandler:))
        ],
        [
            #selector((URLSession.shared.downloadTask(with:completionHandler:)) as ((URL, (@escaping (URL?, URLResponse?, Error?) -> Void)) -> URLSessionDownloadTask)),
            #selector(URLSession.shared.gh_downloadTaskWithUrl(_:completionHandler:))
        ],
        [
            #selector(URLSession.shared.uploadTask(with:fromFile:completionHandler:)),
            #selector(URLSession.shared.gh_uploadTask(with:fromFile:completionHandler:))
        ],
        [
            #selector(URLSession.shared.uploadTask(with:from:completionHandler:)),
            #selector(URLSession.shared.gh_uploadTask(with:from:completionHandler:))
        ],
    ]

    for item in selectors {
        let originalSelector: Selector = item[0]
        let swizzledSelector: Selector = item[1]

        let originalMethod: Method? = class_getInstanceMethod(session, originalSelector)
        let swizzledMethod: Method? = class_getInstanceMethod(session, swizzledSelector)

        if originalMethod == nil {
            continue
        }

        let didAddMethod: Bool = class_addMethod(session, originalSelector, method_getImplementation(swizzledMethod!), method_getTypeEncoding(swizzledMethod!))
        if didAddMethod {
            class_replaceMethod(session, swizzledSelector, method_getImplementation(originalMethod!), method_getTypeEncoding(originalMethod!))
        } else {
            method_exchangeImplementations(originalMethod!, swizzledMethod!)
        }
    }
}

// 用这两个类替换返回的block
class GHURLSessionDataTaskHander: NSObject {
    var ghTrackId: String!
    var hander: ((Data?, URLResponse?, Error?) -> Void) = {(data: Data?, response: URLResponse?, error: Error?) -> Void in}
}
class GHURLSessionDownloadTaskHander: NSObject {
    var ghTrackId: String!
    var hander: ((URL?, URLResponse?, Error?) -> Void) = {(url: URL?, response: URLResponse?, error: Error?) -> Void in}
}

var ghURLSessionHandersHoldKey = "GHURLSessionHandersHoldKey"
var ghRandomIndexKey = "GHRandomIndexKey"

extension URLSession {
    var ghURLSessionHandersHold: GHURLSessionHandersHold {
        set {
            objc_setAssociatedObject(self, &ghURLSessionHandersHoldKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
        get {
            return (objc_getAssociatedObject(self, &ghURLSessionHandersHoldKey) as? GHURLSessionHandersHold) ?? GHURLSessionHandersHold.shared
        }
    }
    var ghRandomIndex: Int {
        get {
            var index: Int = (objc_getAssociatedObject(self, &ghRandomIndexKey) as? Int) ?? 0
            if index == 1000 {
                index = 0
            }
            index += 1
            objc_setAssociatedObject(self, &ghRandomIndexKey, index, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            return (objc_getAssociatedObject(self, &ghRandomIndexKey) as? Int) ?? 0
        }
    }
    
    /// dispatch once time
    private static let dispatchOnceTime: Void = {
        swizzle(URLSession.self)
        // 再交换URLSessionTask的方法
        URLSessionTask.startAOP()
    }()
    
    /// start AOP
    @objc open class func startAOP() {
        guard self === URLSession.self else { return }
        URLSession.dispatchOnceTime
    }
    
    // MARK: swizzle function
    
    @objc func gh_dataTaskWithRequest(_ request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        
        // 生成一个唯一key标记，将次标记存在请求头中
        var req: URLRequest = request
        req.addValue("DataTask" + String(req.hashValue) + TrackUtils.stringFromDate(Date.init(), with: "yyyy-MM-dd HH:mm:ss.SSS") + String(URLSession.shared.ghRandomIndex), forHTTPHeaderField: "ghTrackIdentifier");
        
        // 使用自定义的实例替换block
        let urlSessionhander = GHURLSessionDataTaskHander()
        urlSessionhander.ghTrackId = req.value(forHTTPHeaderField: "ghTrackIdentifier")
        // 使用单例对象强持有
        URLSession.shared.ghURLSessionHandersHold.saveValue(urlSessionhander, for: urlSessionhander.ghTrackId)
        
        urlSessionhander.hander = {[weak urlSessionhander] (data: Data?, response: URLResponse?, error: Error?) -> Void in
                        
            if urlSessionhander != nil {
                URLSessionTrack.shared.endTrackDataSessionWith(Indentifier: urlSessionhander!.ghTrackId, EndDate:Date.init(), ResponseData: data, Response: response, Error: error)
                // 释放
                URLSession.shared.ghURLSessionHandersHold.removeValue(for: urlSessionhander!.ghTrackId)
            }
            completionHandler(data, response, error)
        }
        return self.gh_dataTaskWithRequest(req, completionHandler: urlSessionhander.hander);
    }
    
    @objc func gh_dataTaskWithUrl(_ url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        
        // 如果使用的url直接访问的话，直接生成request替代url的方法
        var req: URLRequest = URLRequest.init(url: url)
        req.addValue("DataTask" + String(req.hashValue) + TrackUtils.stringFromDate(Date.init(), with: "yyyy-MM-dd HH:mm:ss.SSS") + String(URLSession.shared.ghRandomIndex), forHTTPHeaderField: "ghTrackIdentifier");
        
        // 使用自定义的实例替换block
        let urlSessionhander = GHURLSessionDataTaskHander()
        urlSessionhander.ghTrackId = req.value(forHTTPHeaderField: "ghTrackIdentifier")
        
        // 强持有
        URLSession.shared.ghURLSessionHandersHold.saveValue(urlSessionhander, for: urlSessionhander.ghTrackId)
        
        urlSessionhander.hander = {[weak urlSessionhander] (data: Data?, response: URLResponse?, error: Error?) -> Void in
            
            if urlSessionhander != nil {
                URLSessionTrack.shared.endTrackDataSessionWith(Indentifier: urlSessionhander!.ghTrackId, EndDate:Date.init(), ResponseData: data, Response: response, Error: error)
                
                // release
                URLSession.shared.ghURLSessionHandersHold.removeValue(for: urlSessionhander!.ghTrackId)
            }
            completionHandler(data, response, error)
        }
        
        // 不走url的方法，还是走request
        return self.gh_dataTaskWithRequest(req, completionHandler: urlSessionhander.hander);
    }
    
    @objc func gh_downloadTaskWithRequest(_ request: URLRequest, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask {
        
        var req: URLRequest = request
        req.addValue("DownloadTask" + String(req.hashValue) + TrackUtils.stringFromDate(Date.init(), with: "yyyy-MM-dd HH:mm:ss.SSS") + String(URLSession.shared.ghRandomIndex), forHTTPHeaderField: "ghTrackIdentifier");
        
        let urlSessionhander = GHURLSessionDownloadTaskHander()
        urlSessionhander.ghTrackId = req.value(forHTTPHeaderField: "ghTrackIdentifier")
        
        URLSession.shared.ghURLSessionHandersHold.saveValue(urlSessionhander, for: urlSessionhander.ghTrackId)
        
        urlSessionhander.hander = {[weak urlSessionhander] (url: URL?, response: URLResponse?, error: Error?) -> Void in
                        
            if urlSessionhander != nil {
                URLSessionTrack.shared.endTrackDownloadSessionWith(Indentifier: urlSessionhander!.ghTrackId, EndDate:Date.init(), ResponseURL: url, Response: response, Error: error)
                
                URLSession.shared.ghURLSessionHandersHold.removeValue(for: urlSessionhander!.ghTrackId)
            }
            completionHandler(url, response, error)
        }
        return self.gh_downloadTaskWithRequest(req, completionHandler: urlSessionhander.hander)
    }

    @objc func gh_downloadTaskWithUrl(_ url: URL, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask {
        
        var req: URLRequest = URLRequest.init(url: url)
        req.addValue("DownloadTask" + String(req.hashValue) + TrackUtils.stringFromDate(Date.init(), with: "yyyy-MM-dd HH:mm:ss.SSS") + String(URLSession.shared.ghRandomIndex), forHTTPHeaderField: "ghTrackIdentifier");
        
        let urlSessionhander = GHURLSessionDownloadTaskHander()
        urlSessionhander.ghTrackId = req.value(forHTTPHeaderField: "ghTrackIdentifier")
        
        URLSession.shared.ghURLSessionHandersHold.saveValue(urlSessionhander, for: urlSessionhander.ghTrackId)
        
        urlSessionhander.hander = {[weak urlSessionhander] (url: URL?, response: URLResponse?, error: Error?) -> Void in
            
            if urlSessionhander != nil {
                URLSessionTrack.shared.endTrackDownloadSessionWith(Indentifier: urlSessionhander!.ghTrackId, EndDate:Date.init(), ResponseURL: url, Response: response, Error: error)
                
                // release
                URLSession.shared.ghURLSessionHandersHold.removeValue(for: urlSessionhander!.ghTrackId)
            }
            completionHandler(url, response, error)
        }
        
        return self.gh_downloadTaskWithRequest(req, completionHandler: urlSessionhander.hander)
    }
    
    @objc func gh_uploadTask(with request: URLRequest, fromFile fileURL: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionUploadTask {
        
        var req: URLRequest = request
        req.addValue("UploadTask" + String(req.hashValue) + TrackUtils.stringFromDate(Date.init(), with: "yyyy-MM-dd HH:mm:ss.SSS") + String(URLSession.shared.ghRandomIndex), forHTTPHeaderField: "ghTrackIdentifier");
        
        let urlSessionhander = GHURLSessionDataTaskHander()
        urlSessionhander.ghTrackId = req.value(forHTTPHeaderField: "ghTrackIdentifier")
        
        URLSession.shared.ghURLSessionHandersHold.saveValue(urlSessionhander, for: urlSessionhander.ghTrackId)
        
        urlSessionhander.hander = {[weak urlSessionhander] (data: Data?, response: URLResponse?, error: Error?) -> Void in
                        
            if urlSessionhander != nil {
                URLSessionTrack.shared.endTrackUploadSessionWith(Indentifier: urlSessionhander!.ghTrackId, EndDate:Date.init(), ResponseData: data, Response: response, Error: error)
                
                URLSession.shared.ghURLSessionHandersHold.removeValue(for: urlSessionhander!.ghTrackId)
            }
            completionHandler(data, response, error)
        }
        return self.gh_uploadTask(with: request, fromFile: fileURL, completionHandler: urlSessionhander.hander)
    }

    @objc func gh_uploadTask(with request: URLRequest, from bodyData: Data?, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionUploadTask {
        
        var req: URLRequest = request
        req.addValue("UploadTask" + String(req.hashValue) + TrackUtils.stringFromDate(Date.init(), with: "yyyy-MM-dd HH:mm:ss.SSS") + String(URLSession.shared.ghRandomIndex), forHTTPHeaderField: "ghTrackIdentifier");
        
        let urlSessionhander = GHURLSessionDataTaskHander()
        urlSessionhander.ghTrackId = req.value(forHTTPHeaderField: "ghTrackIdentifier")
        
        URLSession.shared.ghURLSessionHandersHold.saveValue(urlSessionhander, for: urlSessionhander.ghTrackId)
        
        urlSessionhander.hander = {[weak urlSessionhander] (data: Data?, response: URLResponse?, error: Error?) -> Void in
                        
            if urlSessionhander != nil {
                URLSessionTrack.shared.endTrackUploadSessionWith(Indentifier: urlSessionhander!.ghTrackId, EndDate:Date.init(), ResponseData: data, Response: response, Error: error)
                
                URLSession.shared.ghURLSessionHandersHold.removeValue(for: urlSessionhander!.ghTrackId)
            }
            completionHandler(data, response, error)
        }
        return self.gh_uploadTask(with: request, from: bodyData, completionHandler: urlSessionhander.hander)
    }
}

private func swizzleSessionTask(_ sessionTask: URLSessionTask.Type) {
    let selectors: Array<Array<Selector>> = [
        [
            #selector(sessionTask.cancel),
            #selector(sessionTask.gh_cancel)
        ],
        [
            #selector(sessionTask.suspend),
            #selector(sessionTask.gh_suspend)
        ],
        [
            #selector(sessionTask.resume),
            #selector(sessionTask.gh_resume)
        ],
    ]

    for item in selectors {
        let originalSelector: Selector = item[0]
        let swizzledSelector: Selector = item[1]
        
        // WARNING: 测试发现，URLSessionDataTask不是实体类，而且使用runtime无法获取到这个类对应的真实类，而resume方法被私有类重写过，所以直接交换URLSessionTask也不行，经过测试下载、上传、普通请求三种情况，都含有私有类__NSCFLocalSessionTask，所以对__NSCFLocalSessionTask进行交换，重写resume的私有类其实并不是__NSCFLocalSessionTask，只不过不影响
        let originalMethod: Method? = class_getInstanceMethod(NSClassFromString("__NSCFLocalSessionTask"), originalSelector)
        let swizzledMethod: Method? = class_getInstanceMethod(sessionTask, swizzledSelector)

        if originalMethod == nil {
            continue
        }

        let didAddMethod: Bool = class_addMethod(sessionTask, originalSelector, method_getImplementation(swizzledMethod!), method_getTypeEncoding(swizzledMethod!))
        if didAddMethod {
            class_replaceMethod(sessionTask, swizzledSelector, method_getImplementation(originalMethod!), method_getTypeEncoding(originalMethod!))
        } else {
            method_exchangeImplementations(originalMethod!, swizzledMethod!)
        }
    }
}

extension URLSessionTask {
    private static let dispatchOnceTime: Void = {
        swizzleSessionTask(URLSessionTask.self)
    }()
    @objc open class func startAOP() {
        guard self === URLSessionTask.self else { return }
        URLSessionTask.dispatchOnceTime
    }
    
    // MARK: 交换的方法
    
    @objc func gh_cancel() {
        self.gh_cancel()
    }
    
    @objc func gh_suspend() {
        self.gh_suspend()
    }
    
    @objc func gh_resume() {
        URLSessionTrack.shared.startTrackSessionWith(Request: self.currentRequest, StartDate: Date.init())
        self.gh_resume()
    }
}
