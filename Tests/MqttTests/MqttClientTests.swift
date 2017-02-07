//
//  MqttClientTests.swift
//  Mqtt
//
//  Created by Heee on 16/2/9.
//  Copyright © 2016年 beidouapp. All rights reserved.
//

import XCTest
import Mqtt


let sDefaultHost = "q.emqtt.com"
//let sDefaultHost = "127.0.0.1"
let sDefaultPort = UInt16(1883)

class MqttClientTests: XCTestCase {
    
    var expConnect: XCTestExpectation?
    
    var expPublish: XCTestExpectation?
    
    var expSubscribe: XCTestExpectation?
    
    var expUnsubscribe: XCTestExpectation?
    
    var expPing: XCTestExpectation?
    
    var expDisconnect: XCTestExpectation?
    
    var client: MqttClient!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        expConnect = expectation(description: "CONNECT")
        
        client = MqttClient(clientId: "macbookpro-test", cleanSession: false)
        client.delegate = self
        print("------------ clientId \(client.clientId)")
        do {
            try client.connect(host: sDefaultHost, port: sDefaultPort)
        } catch {
            XCTAssert(false, "\(error)")
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        
        expDisconnect = expectation(description: "DISCONNECT")
        
        do {
            try client.disconnect()
        } catch {
            XCTAssert(false, "\(error)")
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func test001_Publish() {
        expPublish = expectation(description: "PUBLISH")
        
        do {
            try client.publish(topic: "topic2", payload: "hello mqtt server!", qos: .qos2)
        } catch {
            XCTAssert(false, "\(error)")
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func test002_Subscribe() {
        expSubscribe = expectation(description: "SUBSCRIBE")
        
        do {
            try client.subscribe(topic: "topic2", qos: .qos1)
        } catch {
            XCTAssert(false, "\(error)")
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func test003_Unsubscribe() {
        expUnsubscribe = expectation(description: "UNSUBSCRIBE")
        do {
            try client.unsubscribe(topics: ["topic1"])
        } catch {
            XCTAssert(false, "\(error)")
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func test004_Ping() {
        expPing = expectation(description: "PING")
        do {
            try client.ping()
        } catch {
            XCTAssert(false, "\(error)")
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
}

extension MqttClientTests: MqttClientDelegate {
    func mqtt(_ mqtt: MqttClient, didRecvConnack packet: ConnAckPacket) {
        if packet.returnCode == .accepted {
            expConnect?.fulfill()
            expConnect = nil
            XCTAssertEqual(mqtt.sessionState, .connected)
        } else {
            XCTAssertEqual(mqtt.sessionState, .denied)
        }
        
        XCTAssertEqual(packet.returnCode, .accepted)
    }
    
    func mqtt(_ mqtt: MqttClient, didPublish packet: PublishPacket) {
        expPublish?.fulfill()
        expPublish = nil
    }
    
    func mqtt(_ mqtt: MqttClient, didRecvMessage packet: PublishPacket) {
        print("recv message: \(packet)")
    }
    
    func mqtt(_ mqtt: MqttClient, didSubscribe packet: SubscribePacket) {
        expSubscribe?.fulfill()
        expSubscribe = nil
    }
    
    func mqtt(_ mqtt: MqttClient, didUnsubscribe packet: UnsubscribePacket) {
        expUnsubscribe?.fulfill()
        expUnsubscribe = nil
    }
    
    func mqtt(_ mqtt: MqttClient, didRecvPingresp packet: PingRespPacket) {
        expPing?.fulfill()
        expPing = nil
    }
    
    func mqtt(_ mqtt: MqttClient, didDisconnect error: Error?) {
        expDisconnect?.fulfill()
        expDisconnect = nil
        client = nil
        XCTAssertEqual(mqtt.sessionState, .disconnected)
    }
}
