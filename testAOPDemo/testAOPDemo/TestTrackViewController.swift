//
//  TestTrackViewController.swift
//  testAOPDemo
//
//  Created by 管浩 on 2020/5/21.
//  Copyright © 2020 管浩. All rights reserved.
//

import UIKit

class TestTrackViewController: UIViewController {

    private var resultTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.white
        
        // send request
        let requestBtn = UIButton.init(type: UIButton.ButtonType.system)
        requestBtn.setTitle("send one request", for: UIControl.State.normal)
        requestBtn.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(requestBtn)
        requestBtn.addTarget(self, action: #selector(sendRequest), for: UIControl.Event.touchUpInside)
        
        requestBtn.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        requestBtn.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 30).isActive = true
        
        // test table view
        let tableViewBtn = UIButton.init(type: UIButton.ButtonType.system)
        tableViewBtn.setTitle("open table view", for: UIControl.State.normal)
        tableViewBtn.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(tableViewBtn)
        tableViewBtn.addTarget(self, action: #selector(openTestTableView), for: UIControl.Event.touchUpInside)
        
        tableViewBtn.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        tableViewBtn.topAnchor.constraint(equalTo: requestBtn.topAnchor, constant: 40).isActive = true
        
        // test web view
        let webViewBtn = UIButton.init(type: UIButton.ButtonType.system)
        webViewBtn.setTitle("open web view", for: UIControl.State.normal)
        webViewBtn.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(webViewBtn)
        webViewBtn.addTarget(self, action: #selector(openTestWebView), for: UIControl.Event.touchUpInside)
        
        webViewBtn.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        webViewBtn.topAnchor.constraint(equalTo: tableViewBtn.topAnchor, constant: 40).isActive = true
        
        // test alert controller
        let alertBtn = UIButton.init(type: UIButton.ButtonType.system)
        alertBtn.setTitle("open alert window", for: UIControl.State.normal)
        alertBtn.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(alertBtn)
        alertBtn.addTarget(self, action: #selector(openAlertView), for: UIControl.Event.touchUpInside)
        
        alertBtn.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        alertBtn.topAnchor.constraint(equalTo: webViewBtn.topAnchor, constant: 40).isActive = true
        
        // test alert controller
        let asyncRequestBtn = UIButton.init(type: UIButton.ButtonType.system)
        asyncRequestBtn.setTitle("send async request at same time", for: UIControl.State.normal)
        asyncRequestBtn.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(asyncRequestBtn)
        asyncRequestBtn.addTarget(self, action: #selector(sendAsyncRequest), for: UIControl.Event.touchUpInside)
        
        asyncRequestBtn.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        asyncRequestBtn.topAnchor.constraint(equalTo: alertBtn.topAnchor, constant: 40).isActive = true
        
        // test download file
        let downloadBtn = UIButton.init(type: UIButton.ButtonType.system)
        downloadBtn.setTitle("download file", for: UIControl.State.normal)
        downloadBtn.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(downloadBtn)
        downloadBtn.addTarget(self, action: #selector(downloadFile), for: UIControl.Event.touchUpInside)
        
        downloadBtn.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        downloadBtn.topAnchor.constraint(equalTo: asyncRequestBtn.topAnchor, constant: 40).isActive = true
        
        // test tap gesture
        let label = UILabel.init()
        label.text = "tap gesture"
        label.isUserInteractionEnabled = true
        label.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(label)
        let tapGR: UITapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(tapClick))
        label.addGestureRecognizer(tapGR)
        
        label.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        label.topAnchor.constraint(equalTo: downloadBtn.topAnchor, constant: 50).isActive = true
    }
    
    @objc func sendRequest() -> Void {
//        var request = URLRequest.init(url: URL.init(string: "http://192.168.0.163:8888")!)
//        request.timeoutInterval = 5
//        let task = URLSession.shared.dataTask(with: request) { (data, respons, error) in
//            print(error as Any)
//        }
//        task.resume()
//        for _ in 1 ... 10 {
            var request = URLRequest.init(url: URL.init(string: "http://192.168.0.163:8888")!)
            request.timeoutInterval = 5
            let task = URLSession.shared.dataTask(with: request) { (data, respons, error) in
                print(error as Any)
            }
            task.resume()
//        }
    }
    
    @objc func openTestTableView() -> Void {
        let vc = TextTableViewController.init()
        self.present(vc, animated: true, completion: nil)
    }
    
    @objc func openTestWebView() -> Void {
        let vc = TextWebViewController.init()
        self.present(vc, animated: true, completion: nil)
    }
    
    @objc func openAlertView() -> Void {
        let alertController = UIAlertController.init(title: "title", message: "message", preferredStyle: UIAlertController.Style.alert);
        
        alertController.addAction(UIAlertAction.init(title: "action1", style: UIAlertAction.Style.default, handler: { (action) in
            print("click action1");
        }))
        
        alertController.addAction(UIAlertAction.init(title: "action2", style: UIAlertAction.Style.cancel, handler: { (action) in
            print("click action2");
        }))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    @objc func sendAsyncRequest() -> Void {
        
        for _ in 1 ... 20 {
            DispatchQueue.global().async {
                var request = URLRequest.init(url: URL.init(string: "http://192.168.0.163:8888")!)
                request.timeoutInterval = 5
                let task = URLSession.shared.dataTask(with: request) { (data, respons, error) in
                    print(error as Any)
                }
                task.resume()
            }
        }
    }
    
    @objc func downloadFile() -> Void {
        let request = URLRequest(url: URL(string: "https://andergh.github.io/img/your's%20name.JPG")!)
        let session = URLSession.shared
        let task = session.downloadTask(with: request, completionHandler: { (location: URL?, response: URLResponse?, error: Error?) -> Void in

            if error != nil {
                print(error as Any)
                return
            }
            if location == nil {
                return
            }
            let documnet:String = NSHomeDirectory() + "/Documents/test.png"
            try? FileManager.default.moveItem(atPath: location!.path, toPath: documnet)
            print("location：" + documnet)
        })
        task.resume()
    }
    
    @objc func uploadFile() -> Void {
        let request = URLRequest(url: URL(string: "http://192.168.0.163:8888")!)
        let data: Data? = try? Data.init(contentsOf: URL.init(fileURLWithPath: (NSHomeDirectory() + "/Documents/test.png")))
        let task = URLSession.shared.uploadTask(with: request, from: data) { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            
            if error != nil {
                print(error as Any)
                return
            }
        }
        task.resume()
    }
    
    @objc func tapClick() -> Void {
        print("test tap gesture")
    }
}
