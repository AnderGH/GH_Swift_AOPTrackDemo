//
//  TextTableViewController.swift
//  testAOPDemo
//
//  Created by 管浩 on 2020/5/21.
//  Copyright © 2020 管浩. All rights reserved.
//

import UIKit

class TextTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.white
        
        // table view
        let tableView = UITableView.init(frame: CGRect.zero, style: UITableView.Style.plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(tableView)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "mytestcell")
        
        tableView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        tableView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 100
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "mytestcell", for: indexPath);
        cell.textLabel?.text = String(indexPath.row);
        return cell;
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("UITableView点击了" + String(indexPath.row) + "行")
    }
}
