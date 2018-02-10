//
//  ClientSessionViewController.swift
//  SimpleClient
//
//  Created by HJianBo on 2017/1/8.
//  Copyright © 2017年 beidouapp. All rights reserved.
//

import UIKit
import Mqtt

class ClientSessionViewController: UIViewController {

    var configurationVC: ClientConfigurationViewController?
    
    var mqtt: MqttClient?
    
    // Views
    
    @IBOutlet weak var txtTopic: UITextField!
    @IBOutlet weak var segQos: UISegmentedControl!
    @IBOutlet weak var txtPayload: UITextField!
    @IBOutlet weak var txtLogConsole: UITextView!
    @IBOutlet weak var segRetain: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Config",
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(touchedToConfigurationVC))
    }
}

extension ClientSessionViewController {
    
    @objc func touchedToConfigurationVC() {
        if configurationVC == nil {
            let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = mainStoryboard.instantiateViewController(withIdentifier: "ClientConfigurationViewController")
            configurationVC = (vc as! ClientConfigurationViewController)
        }
        navigationController?.pushViewController(configurationVC!, animated: true)
    }
    
    @IBAction func touchedConnect(_ sender: Any) {
        
        if mqtt == nil {
            guard let config = configurationVC?.configuration else {
                log("configuration is nil, please set it by configuration view controller")
                return
            }
            
            mqtt = MqttClient(clientId: config.clientId,
                              cleanSession: config.cleanSession,
                              keepAlive: config.keepAlive,
                              username: config.username,
                              password: config.password)
            
            mqtt!.willTopic = "test"
            mqtt!.willMessage = "This is will message"
            //mqtt!.willRetain = true
            
            mqtt!.delegate = self
            mqtt!.connect(host: config.host, port: config.port) { [weak self] address, error in
                guard let weakSelf = self else { return }
                guard error == nil else {
                    weakSelf.log("connect \(address) error: \(error!)")
                    return
                }
                weakSelf.log("connect suceess \(address)")
            }
        } else {
           log("mqtt client has connect!")
        }
    }
    
    @IBAction func touchedDisconnect(_ sender: Any) {
        do {
            try mqtt?.disconnect()
        } catch {
            log("\(#function) throw a error: \(error)")
        }
    }
    
    @IBAction func touchedPing(_ sender: Any) {
        do {
            try mqtt?.ping()
        } catch {
            log("\(#function) throw a error: \(error)")
        }
    }
    
    @IBAction func touchedSubscribe(_ sender: Any) {
        let topic = txtTopic.text ?? ""
        let qos   = Qos(rawValue: UInt8(segQos.selectedSegmentIndex)) ?? .qos0
        mqtt?.subscribe(topicFilters: [topic: qos]) { [weak self] result, error in
            guard let weakSelf = self else { return }
            guard error == nil else {
                weakSelf.log("subscribe error \(String(describing: error))")
                return
            }
            weakSelf.log("subscribe success \(result)")
        }
    }
    
    @IBAction func touchedPublish(_ sender: Any) {
        let topic = txtTopic.text ?? ""
        let payload = txtPayload.text ?? ""
        let qos   = Qos(rawValue: UInt8(segQos.selectedSegmentIndex)) ?? .qos0
        mqtt?.publish(topic: topic, payload: payload, qos: qos, retain: segRetain.isOn) { [weak self] error in
            guard let weakSelf = self else { return }
            guard error == nil else {
                weakSelf.log("publish error \(String(describing: error))")
                return
            }
            
            weakSelf.log("publish success, topic: \(topic), payload: \(payload)")
        }
    }
    
    @IBAction func segmentValueChanged(_ sender: Any) {
        // ...
    }
    
    @IBAction func touchedUnsubscribe(_ sender: Any) {
        let topic = txtTopic.text ?? ""
        mqtt?.unsubscribe(topicFilters: [topic]) { [weak self] error in
            guard let weakSelf = self else { return }
            guard error == nil else {
                weakSelf.log("unsubscribe error \(String(describing: error))")
                return
            }
            
            weakSelf.log("unsubscribe success \(topic)")
        }
    }
    
    @IBAction func touchedGetClientState(_ sender: Any) {
        log("\(String(describing: mqtt?.sessionState))")
    }
}

extension ClientSessionViewController: MqttClientDelegate {
    func mqtt(_ mqtt: MqttClient, didConnect address: String) {
        log("mqtt did connect: \(address)")
    }
    
    func mqtt(_ mqtt: MqttClient, didDisconnect error: Error?) {
        log("did disconnect: \(String(describing: error))")
        self.mqtt = nil
    }
    
    func mqtt(_ mqtt: MqttClient, didPublish packet: PublishPacket) {
        log("did publish topic: \(packet.topicName), payload: \(packet.payloadStringValue)")
    }
    
    func mqtt(_ mqtt: MqttClient, didRecvMessage packet: PublishPacket) {
        log("recevie message: topic: \(packet.topicName), payload: \(packet.payloadStringValue)")
    }
    
    func mqtt(_ mqtt: MqttClient, didSubscribe result: [String : SubsAckReturnCode]) {
        log("did subscribe: \(result)")
    }
    
    func mqtt(_ mqtt: MqttClient, didUnsubscribe topics: [String]) {
        log("did unsubscribe topics: \(topics)")
    }
    
    func mqtt(_ mqtt: MqttClient, didRecvPong packet: PingRespPacket) {
        log("recevie pong")
    }
}

extension ClientSessionViewController {
    
    func log(_ s: String) {
        if txtLogConsole.text.utf8.count > 1000 {
           txtLogConsole.text = ""
        }
        txtLogConsole.text = s + "\n" + txtLogConsole.text
    }
}

extension ClientSessionViewController {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(false)
    }
}
