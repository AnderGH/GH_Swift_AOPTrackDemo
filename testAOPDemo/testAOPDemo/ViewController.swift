//
//  ViewController.swift
//  testAOPDemo
//
//  Created by 管浩 on 2020/5/21.
//  Copyright © 2020 管浩. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        
        // send request
        let button = UIButton.init(type: UIButton.ButtonType.system)
        button.setTitle("open test page", for: UIControl.State.normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(button)
        button.addTarget(self, action: #selector(openTestPage), for: UIControl.Event.touchUpInside)
        
        button.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        button.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        
    }
   
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    @objc func openTestPage() -> Void {
        let vc = TestTrackViewController.init()
        self.present(vc, animated: true, completion: nil)
    }
}

