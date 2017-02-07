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

        mqtt = MqttClient(clientId: "iosclient")
        mqtt.delegate = self
    }
    @IBAction func touchedGetClientState(_ sender: Any) {
        log("\(mqtt.sessionState)")
    }
}

extension ClientSessionViewController {
    
    @IBAction func touchedConnect(_ sender: Any) {
        do {
            try mqtt.connect(host: "q.emqtt.com")
        } catch {
            log("\(#function) throw a error: \(error)")
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
        do {
            let topic = txtTopic.text ?? ""
            let qos   = Qos(rawValue: UInt8(segQos.selectedSegmentIndex)) ?? .qos0
            try mqtt.subscribe(topic: topic, qos: qos)
        } catch {
            log("\(#function) throw a error: \(error)")
        }
    }
    @IBAction func touchedPublish(_ sender: Any) {
        do {
            let topic = txtTopic.text ?? ""
            let payload = txtPayload.text ?? ""
            let qos   = Qos(rawValue: UInt8(segQos.selectedSegmentIndex)) ?? .qos0
            try mqtt.publish(topic: topic, payload: payload, qos: qos)
        } catch {
            log("\(#function) throw a error: \(error)")
        }
    }
    
    @IBAction func segmentValueChanged(_ sender: Any) {
        // ...
    }
    
    @IBAction func touchedUnsubscribe(_ sender: Any) {
        do {
            let topic = txtTopic.text ?? ""
            try mqtt.unsubscribe(topics: [topic])
        } catch {
            log("\(#function) throw a error: \(error)")
        }
    }
}

extension ClientSessionViewController: MqttClientDelegate {
    
    func mqtt(_ mqtt: MqttClient, didRecvConnack packet: ConnAckPacket) {
        log("recevie connack: \(packet.returnCode)")
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
    
    func mqtt(_ mqtt: MqttClient, didSubscribe packet: SubscribePacket) {
        log("did subscribe topics: \(packet.topics)")
    }
    
    func mqtt(_ mqtt: MqttClient, didRecvPingresp packet: PingRespPacket) {
        log("recevie pong")
    }
    
    func mqtt(_ mqtt: MqttClient, didUnsubscribe packet: UnsubscribePacket) {
        log("did unsubscribe topics: \(packet.topics)")
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
