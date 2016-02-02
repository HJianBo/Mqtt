//
//  MqttTests.swift
//  MqttTests
//
//  Created by Heee on 16/2/2.
//  Copyright © 2016年 jianbo. All rights reserved.
//

import XCTest
@testable import Mqtt


class MqttPacketTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
}


// MARK: - Connect Packet

extension MqttPacketTests {
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



// MARK: - Connack Packet
extension MqttPacketTests {
    
    func testConnack_Init() {
        let connackPacket = ConnackPacket()
        
        XCTAssert(connackPacket.fixHeader.type == .CONNACK, "fixheader type should be .CONNACK")
        XCTAssert(connackPacket.connackFlags == 0, "connack flags should be 0")
        XCTAssert(!connackPacket.sessionPresent, "session present should be 0")
        XCTAssert(connackPacket.returnCode == .Accepted, "return code default should be .Accepted")
    }
    
    func testConnack_property() {
        var connackPacket = ConnackPacket()
        
        connackPacket.sessionPresent = true
        XCTAssert(connackPacket.connackFlags == 1, "connack flags should be 1")
        XCTAssert(connackPacket.sessionPresent, "session present should be true")
        
        connackPacket.sessionPresent = false
        XCTAssert(connackPacket.connackFlags == 0, "connack flags should be 0")
        XCTAssert(!connackPacket.sessionPresent, "session present should be false")
        
        connackPacket.returnCode = .BadUsernameOrPassword
        XCTAssert(connackPacket.returnCode == .BadUsernameOrPassword, "return code should be .BadUsernameOrPassword")
        
        connackPacket.returnCode = .UnAccepableProtocolVersion
        XCTAssert(connackPacket.returnCode == .UnAccepableProtocolVersion, "return code should be .UnAccepableProtocolVersion")
        
        connackPacket.returnCode = .NotAuthorized
        XCTAssert(connackPacket.returnCode == .NotAuthorized, "return code should be .NotAuthorized")
        
        connackPacket.returnCode = .Accepted
        XCTAssert(connackPacket.returnCode == .Accepted, "return code should be .Accepted")
    }
}

//extension MqttTests {
//    private func length(v: Array<UInt8>) -> Int {
//        
//
//}
