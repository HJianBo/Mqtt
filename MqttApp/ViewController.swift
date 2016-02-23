//
//  ViewController.swift
//  MqttApp
//
//  Created by Heee on 16/2/16.
//  Copyright © 2016年 beidouapp. All rights reserved.
//

import UIKit
import Mqtt


class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let client = MqttClient(host: sDefaultHost, port: sDefaultPort, clientId: "iPhone", cleanSession: false)
        client.connect()
    }
}

