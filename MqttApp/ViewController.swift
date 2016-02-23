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

    @IBOutlet weak var txtHost: UITextField!
    @IBOutlet weak var txtPort: UITextField!
    @IBOutlet weak var txtTopic: UITextField!
    @IBOutlet weak var txtPayload: UITextField!
    @IBOutlet weak var txtLogs: UITextView!

    var mqtt: MqttClient?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }
    
    func log(s: String) {
        txtLogs.text = txtLogs.text + "\n\(s)"
    }
}

extension ViewController {

    @IBAction func touchedConnect(sender: AnyObject) {
        mqtt = MqttClient(host: txtHost.text!, port: UInt16(txtPort.text!)!, clientId: "iPhone", cleanSession: false)
        
        mqtt?.connect()
    }
    
    @IBAction func touchedPublish(sender: AnyObject) {
        mqtt?.publish()
    }

    @IBAction func touchedSubscribe(sender: AnyObject) {
        mqtt?.subscribe()
    }

    @IBAction func touchedUnSubs(sender: AnyObject) {
        mqtt?.unsubscribe()
    }

    @IBAction func touchedPing(sender: AnyObject) {
        mqtt?.ping()
    }
    
    @IBAction func touchedDisconnect(sender: AnyObject) {
        mqtt?.disconnect()
    }
}

