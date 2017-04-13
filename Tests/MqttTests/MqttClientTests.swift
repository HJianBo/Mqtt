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
        client.connect(host: sDefaultHost, port: sDefaultPort) { (address, error) in
            guard error == nil else {
                XCTAssert(false, "\(String(describing: error))")
                return
            }
            
            XCTAssertEqual(address, "\(sDefaultHost):\(sDefaultPort)")
            self.expConnect?.fulfill()
            self.expConnect = nil
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
        
        client.publish(topic: "topic2", payload: "hello mqtt server", qos: .qos2) { error in
            guard error == nil else {
                XCTAssert(false, "\(String(describing: error))")
                return
            }
            self.expPublish?.fulfill()
            self.expPublish = nil
        }

        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func test002_Subscribe() {
        expSubscribe = expectation(description: "SUBSCRIBE")
        
        client.subscribe(topicFilters: ["topic2": .qos1]) { (res, error) in
            guard error == nil else {
                XCTAssert(false)
                return
            }
            
            guard let authcatiedQos = res["topic2"] else {
                XCTAssert(false)
                return
            }
            
            XCTAssertEqual(authcatiedQos, .maxQos1)
            self.expSubscribe?.fulfill()
            self.expSubscribe = nil
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func test003_Unsubscribe() {
        expUnsubscribe = expectation(description: "UNSUBSCRIBE")
        client.unsubscribe(topicFilters: ["topic1"]) { error in
            guard error == nil else {
                assert(false)
                return
            }
            self.expUnsubscribe?.fulfill()
            self.expUnsubscribe = nil
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
    
    func mqtt(_ mqtt: MqttClient, didPublish publish: PublishPacket) {
        print("did publish \(publish)")
    }
    
    func mqtt(_ mqtt: MqttClient, didRecvMessage packet: PublishPacket) {
        print("recv message: \(packet)")
    }
    
    func mqtt(_ mqtt: MqttClient, didRecvPong packet: PingRespPacket) {
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
