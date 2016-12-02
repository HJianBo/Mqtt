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
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testClient_Init() {
        let exp = expectation(description: "CONNECT")
        
        let client = MqttClient(clientId: "macbookpro-test")
        
        do {
            try client.connect(host: sDefaultHost, port: sDefaultPort)
        } catch {
            XCTAssert(false, "\(error)")
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
}
