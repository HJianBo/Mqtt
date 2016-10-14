//
//  ViewController.swift
//  MqttClient
//
//  Created by HJianBo on 2016/10/14.
//  Copyright © 2016年 beidouapp. All rights reserved.
//

import Cocoa
import Mqtt

//let defaultHost = "q.emqtt.com"
let defaultHost = "120.25.145.3"
let defaultPort: UInt16 = 1883

class ViewController: NSViewController {

    var client: MqttClient!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        client = MqttClient(host: defaultHost, port: defaultPort, clientId: "macbook pro", cleanSession: true)
        
        
        client.connect()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
}

