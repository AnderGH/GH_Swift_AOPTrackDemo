//
//  TextWebViewController.swift
//  testAOPDemo
//
//  Created by 管浩 on 2020/5/21.
//  Copyright © 2020 管浩. All rights reserved.
//

import UIKit
import WebKit

class TextWebViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.white
        
        let request = URLRequest.init(url: URL.init(string: "https://www.baidu.com/")!)
        let webView = WKWebView.init()
        webView.load(request)
        webView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(webView)
        
        webView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        webView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        webView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
    }
}
