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
let sDefaultPort = UInt16(1883)

class MqttClientTests: XCTestCase {
    
    var expConnect: XCTestExpectation?
    
    var expPublish: XCTestExpectation?
    
    var client: MqttClient!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        expConnect = expectation(description: "CONNECT")
        
        client = MqttClient(clientId: "macbookpro-test")
        client.delegate = self
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
    }
    
    func testPublish() {
        expPublish = expectation(description: "PUBLISH")
        
        do {
            try client.publish(topic: "topic1", payload: "hello mqtt server!", qos: .qos2)
        } catch {
            XCTAssert(false, "\(error)")
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
}

extension MqttClientTests: MqttClientDelegate {
    func mqtt(_ mqtt: MqttClient, didRecvConnack packet: ConnAckPacket) {
        XCTAssertEqual(packet.returnCode, .accepted)
        if packet.returnCode == .accepted {
            expConnect?.fulfill()
            expConnect = nil
        }
    }
    
    func mqtt(_ mqtt: MqttClient, didPublish packet: PublishPacket) {
        expPublish?.fulfill()
        expPublish = nil
    }
    
    func mqtt(_ mqtt: MqttClient, didRecvMessage packet: PublishPacket) {
        
    }
}
