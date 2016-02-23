//
//  MqttClientTests.swift
//  Mqtt
//
//  Created by Heee on 16/2/9.
//  Copyright © 2016年 beidouapp. All rights reserved.
//

import XCTest
import Mqtt


let sDefaultHost = "115.28.55.154"
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
        let exp = expectationWithDescription("CONNECT")
        
        let client = MqttClient(host: sDefaultHost, port: sDefaultPort, clientId: "MacbookPro", cleanSession: false)
        
        client.connect()
        
        waitForExpectationsWithTimeout(10, handler: nil)
    }
}
