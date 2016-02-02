//
//  MqttTests.swift
//  MqttTests
//
//  Created by Heee on 16/2/2.
//  Copyright © 2016年 jianbo. All rights reserved.
//

import XCTest
@testable import Mqtt


class MqttTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testConnectPacket_Init() {
        let clientId = "iPhone6s"
        
        var connetPacket = ConnectPacket(clientId: clientId)
        // FIX HEADER
        XCTAssert(connetPacket.fixHeader.type == .CONNECT, "packet type is error")
        XCTAssert(connetPacket.fixHeader.flag == 0, "fixheader flag should  reserved!")
        
        // VARIABLE HEADER
        XCTAssert(connetPacket.protocolName == DefaultProtocolName, "protocol name should be default")
        XCTAssert(connetPacket.protocolLevel == DefaultProtocolLevel, "protocol level should be default")
        XCTAssert(connetPacket.connectFlags == 0, "connect flag should be 0")
        XCTAssert(connetPacket.keepAlive == DefaultKeepAlive, "keep alive should be default")
        
        // XXX: connectFlags Default is 0 ??
        XCTAssert(connetPacket.userNameFlag == false, "username flag should be false")
        XCTAssert(connetPacket.passwordFlag == false, "password flag should be false")
        XCTAssert(connetPacket.willRetain == false, "will retain should be 0")
        XCTAssert(connetPacket.willQos == .Qos0, "will qos should be 0")
        XCTAssert(connetPacket.willFlag == false, "will flag should be 0")
        XCTAssert(connetPacket.cleanSession == false, "clean session should be 0")
        XCTAssert(connetPacket.reserved == false, "connect flag's reserved should be 0")
        
        // PAYLOAD
        XCTAssert(connetPacket.clientId == clientId, "clientId not match!")
        XCTAssert(connetPacket.userName == nil, "username should be nil")
        XCTAssert(connetPacket.password == nil, "password should be nil")
        
        //XCTAssert(connetPacket.remainLength == [], "remain length should be 0")
        print(connetPacket.description)
    }
    
    func testConnectPacket_property() {
        let clientId = "iPhone6s"
        let username = "HJianBo"
        let password = "123abc"
        
        let willTopic   = "This is will topic"
        let willMessage = "This is will message"
        
        var connetPacket = ConnectPacket(clientId: clientId)
        
        let newClientId = "Macbook Pro 15"
        connetPacket.clientId = newClientId
        XCTAssert(connetPacket.clientId == newClientId, "clientId should be \(newClientId)")
        
        connetPacket.userName = username
        XCTAssert(connetPacket.userName == username, "username should be \(username)")
        XCTAssert(connetPacket.userNameFlag, "username flag should be 1")
        
        connetPacket.password = password
        XCTAssert(connetPacket.password == password, "password should be \(password)")
        XCTAssert(connetPacket.passwordFlag, "password flag should be 1")
        
        connetPacket.willTopic = willTopic
        XCTAssert(connetPacket.willTopic == willTopic, "will topic should be \(willTopic)")
        XCTAssert(connetPacket.willFlag, "will flag should be ture")
        XCTAssert(connetPacket.willQos == .Qos1, "will qos default should be .Qos1")
        XCTAssert(connetPacket.willRetain == false, "will retain default should be false")
        
        connetPacket.willMessage = willMessage
        XCTAssert(connetPacket.willMessage == willMessage, "will message should be \(willMessage)")
        XCTAssert(connetPacket.willFlag, "will flag should be ture")
        XCTAssert(connetPacket.willQos == .Qos1, "will qos default should be .Qos1")
        XCTAssert(connetPacket.willRetain == false, "will retain default should be false")
        
        connetPacket.userName = nil
        XCTAssert(connetPacket.userName == nil, "username should be nil")
        XCTAssert(connetPacket.userNameFlag == false, "username flag should be 0")
        
        connetPacket.password = nil
        XCTAssert(connetPacket.password == nil, "password should be nil")
        XCTAssert(connetPacket.passwordFlag == false, "password flag should be 0")
        
        connetPacket.willTopic = nil
        XCTAssert(connetPacket.willTopic == nil, "will topic should be nil")
        XCTAssert(connetPacket.willFlag == false, "will flag should be false")
        XCTAssert(connetPacket.willQos == .Qos0, "will qos default should be .Qos0")
        XCTAssert(connetPacket.willRetain == false, "will retain default should be false")
        
        connetPacket.willMessage = nil
        XCTAssert(connetPacket.willMessage == nil, "will message should be nil")
        XCTAssert(connetPacket.willFlag == false, "will flag should be false")
        XCTAssert(connetPacket.willQos == .Qos0, "will qos default should be .Qos0")
        XCTAssert(connetPacket.willRetain == false, "will retain default should be false")
        
        connetPacket.userNameFlag = true
        XCTAssert(connetPacket.userNameFlag, "username flag should be true")
        
        connetPacket.passwordFlag = true
        XCTAssert(connetPacket.passwordFlag, "password flag should be true")
        
        connetPacket.willRetain = true
        XCTAssert(connetPacket.willRetain, "will retain should be true")
        
        connetPacket.willQos = .Qos1
        XCTAssert(connetPacket.willQos == .Qos1, "will qos should be .Qos1")
        
        connetPacket.willFlag = true
        XCTAssert(connetPacket.willFlag, "will flag should be true")
        
        connetPacket.cleanSession = true
        XCTAssert(connetPacket.cleanSession, "clean session should be true")

        
        connetPacket.userNameFlag = false
        XCTAssert(!connetPacket.userNameFlag, "username flag should be false")
        
        connetPacket.passwordFlag = false
        XCTAssert(!connetPacket.passwordFlag, "password flag should be false")
        
        connetPacket.willRetain = false
        XCTAssert(!connetPacket.willRetain, "will retain should be false")
        
        connetPacket.willQos = .Qos0
        XCTAssert(connetPacket.willQos == .Qos0, "will qos should be .Qos0")
        
        connetPacket.willFlag = false
        XCTAssert(!connetPacket.willFlag, "will flag should be false")
        
        connetPacket.cleanSession = false
        XCTAssert(!connetPacket.cleanSession, "clean session should be false")
        
        connetPacket.keepAlive = 70
        XCTAssert(connetPacket.keepAlive == 70, "keep alive should be 70")
    }
}

//extension MqttTests {
//    private func length(v: Array<UInt8>) -> Int {
//        
//    }
//}
