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

    var mqtt: MqttClient!
    
    // Views
    
    @IBOutlet weak var txtTopic: UITextField!
    @IBOutlet weak var segQos: UISegmentedControl!
    @IBOutlet weak var txtPayload: UITextField!
    @IBOutlet weak var txtLogConsole: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mqtt = MqttClient(clientId: "iosclient", cleanSession: false, keepAlive: 10)
        mqtt.delegate = self
    }
    
    @IBAction func touchedGetClientState(_ sender: Any) {
        log("\(mqtt.sessionState)")
    }
}

extension ClientSessionViewController {
    
    @IBAction func touchedConnect(_ sender: Any) {
        mqtt.connect(host: "q.emqtt.com") { [weak self] address, error in
            guard let weakSelf = self else { return }
            guard error == nil else {
                weakSelf.log("connect \(address) error: \(error!)")
                return
            }
            weakSelf.log("connect suceess \(address)")
        }
    }
    
    @IBAction func touchedDisconnect(_ sender: Any) {
        do {
            try mqtt.disconnect()
        } catch {
            log("\(#function) throw a error: \(error)")
        }
    }
    
    @IBAction func touchedPing(_ sender: Any) {
        do {
            try mqtt.ping()
        } catch {
            log("\(#function) throw a error: \(error)")
        }
    }
    
    @IBAction func touchedSubscribe(_ sender: Any) {
        let topic = txtTopic.text ?? ""
        let qos   = Qos(rawValue: UInt8(segQos.selectedSegmentIndex)) ?? .qos0
        mqtt.subscribe(topicFilters: [topic: qos]) { [weak self] result, error in
            guard let weakSelf = self else { return }
            guard error == nil else {
                weakSelf.log("subscribe error \(error)")
                return
            }
            weakSelf.log("subscribe success \(result)")
        }
    }
    
    @IBAction func touchedPublish(_ sender: Any) {
        let topic = txtTopic.text ?? ""
        let payload = txtPayload.text ?? ""
        let qos   = Qos(rawValue: UInt8(segQos.selectedSegmentIndex)) ?? .qos0
        mqtt.publish(topic: topic, payload: payload, qos: qos) { [weak self] error in
            guard let weakSelf = self else { return }
            guard error == nil else {
                weakSelf.log("publish error \(error)")
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
        mqtt.unsubscribe(topicFilters: [topic]) { [weak self] error in
            guard let weakSelf = self else { return }
            guard error == nil else {
                weakSelf.log("unsubscribe error \(error)")
                return
            }
            
            weakSelf.log("unsubscribe success \(topic)")
        }
    }
}

extension ClientSessionViewController: MqttClientDelegate {
    func mqtt(_ mqtt: MqttClient, didConnect address: String) {
        log("mqtt did connect: \(address)")
    }
    
    func mqtt(_ mqtt: MqttClient, didDisconnect error: Error?) {
        log("did disconnect: \(error)")
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
