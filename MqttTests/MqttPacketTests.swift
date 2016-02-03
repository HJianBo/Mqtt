//
//  MqttTests.swift
//  MqttTests
//
//  Created by Heee on 16/2/2.
//  Copyright © 2016年 jianbo. All rights reserved.
//

import XCTest
@testable import Mqtt

// TODO: Packet data Tets??????

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
    
    func testConnAck_Init() {
        let connackPacket = ConnAckPacket()
        
        XCTAssert(connackPacket.fixHeader.type == .CONNACK, "fixheader type should be .CONNACK")
        XCTAssert(connackPacket.connackFlags == 0, "connack flags should be 0")
        XCTAssert(!connackPacket.sessionPresent, "session present should be 0")
        XCTAssert(connackPacket.returnCode == .Accepted, "return code default should be .Accepted")
    }
    
    func testConnAck_property() {
        var connackPacket = ConnAckPacket()
        
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


// MARK: - Publish Packet
extension MqttPacketTests {

    func testPublish_init() {
        let packetId = UInt16(1)
        let topic    = "This is topic"
        let payload: Array<UInt8> = [1, 2, 3, 4]
        
        let publishPacket = PublishPacket(packetId: packetId, topic: topic, payload: payload)
        
        XCTAssert(publishPacket.fixHeader.type == .PUBLISH, "packet type should .PUBLISH")
        XCTAssert(publishPacket.fixHeader.dup == false, "packet dup should be false")
        XCTAssert(publishPacket.fixHeader.qos == .Qos0, "packet Qos should be .Qos0")
        XCTAssert(publishPacket.fixHeader.retain == false, "packet retain should be false")

        XCTAssert(publishPacket.topicName == topic, "packet topic name should be \(topic)")
        XCTAssert(publishPacket.packetId == packetId, "packet id should be \(packetId)")
        XCTAssert(publishPacket.payload == payload, "packet payload should be \(payload)")
    }
    
    func testPublish_property() {
        let packetId = UInt16(1)
        let topic    = "This is topic"
        let payload: Array<UInt8> = [1, 2, 3, 4]
        
        
        var publishPacket = PublishPacket(packetId: 111, topic: "topic", payload: [1, 2])
        
        publishPacket.packetId = packetId
        XCTAssert(publishPacket.packetId == packetId, "packet id should be \(packetId)")
        XCTAssert(publishPacket.fixHeader.flag == 0x00, "packet falge shpuld be 0x00")
        
        publishPacket.fixHeader.dup = true
        XCTAssert(publishPacket.fixHeader.dup, "packet dup should be true")
        XCTAssert(publishPacket.fixHeader.flag == 0x08, "packet falge shpuld be 0x08")
        
        publishPacket.fixHeader.dup = false
        XCTAssert(!publishPacket.fixHeader.dup, "packet dup should be false")
        XCTAssert(publishPacket.fixHeader.flag == 0x00, "packet falge shpuld be 0x00")
        
        publishPacket.fixHeader.qos = .Qos2
        XCTAssert(publishPacket.fixHeader.qos == .Qos2, "packet qos should be .Qos2")
        XCTAssert(publishPacket.fixHeader.flag == 0x04, "packet falge shpuld be 0x04")
        
        publishPacket.fixHeader.qos = .Qos0
        XCTAssert(publishPacket.fixHeader.qos == .Qos0, "packet qos should be .Qos1")
        XCTAssert(publishPacket.fixHeader.flag == 0x00, "packet falge shpuld be 0x00")
        
        publishPacket.fixHeader.retain = true
        XCTAssert(publishPacket.fixHeader.retain, "packet retain should be true")
        XCTAssert(publishPacket.fixHeader.flag == 0x01, "packet falge shpuld be 0x01")
        
        publishPacket.fixHeader.retain = false
        XCTAssert(!publishPacket.fixHeader.retain, "packet retain should be false")
        XCTAssert(publishPacket.fixHeader.flag == 0x00, "packet falge shpuld be 0x00")
        
        publishPacket.topicName = topic
        XCTAssert(publishPacket.topicName == topic, "packet topic should be \(topic)")
        
        publishPacket.topicName = ""
        XCTAssert(publishPacket.topicName == "", "packet topic should be empty")
        
        publishPacket.payload = payload
        XCTAssert(publishPacket.payload == payload, "packet payload should be \(payload)")
        
        publishPacket.payload = []
        XCTAssert(publishPacket.payload == [], "packet payload should be empty")
    }
}

// MARK: - PublishAck Packet
extension MqttPacketTests {

    func testPubAck_init () {
        let packetId = UInt16(10)
        
        let pubackPacket = PubAckPacket(packetId: packetId)
        
        XCTAssert(pubackPacket.fixHeader.type == .PUBACK, "packet type should be .PUBACK")
        XCTAssert(!pubackPacket.fixHeader.dup, "packet dup should be false")
        XCTAssert(!pubackPacket.fixHeader.retain, "packet flag should be false")
        XCTAssert(pubackPacket.fixHeader.qos == .Qos0, "packet flag should be .Qos0")
        XCTAssert(pubackPacket.fixHeader.flag == 0x00, "packet flag should be 0")
        XCTAssert(pubackPacket.packetId == packetId, "packet id should be \(packetId)")
        XCTAssert(pubackPacket.payload.count == 0, "packet payload should be empty")
    }
    
    func testPubAck_propterty() {
        let packetId = UInt16(10)
        
        var pubackPacket = PubAckPacket(packetId: 1231)
        
        pubackPacket.packetId = packetId
        XCTAssert(pubackPacket.packetId == packetId, "packet id should be \(packetId)")
    }
}


// MARK: - PubRec Packet
extension MqttPacketTests {

    func testPubRec_init() {
        let packetId = UInt16(10)
        
        let pubackPacket = PubRecPacket(packetId: packetId)
        
        XCTAssert(pubackPacket.fixHeader.type == .PUBREC, "packet type should be .PUBREC")
        XCTAssert(!pubackPacket.fixHeader.dup, "packet dup should be false")
        XCTAssert(!pubackPacket.fixHeader.retain, "packet flag should be false")
        XCTAssert(pubackPacket.fixHeader.qos == .Qos0, "packet flag should be .Qos0")
        XCTAssert(pubackPacket.fixHeader.flag == 0x00, "packet flag should be 0")
        XCTAssert(pubackPacket.packetId == packetId, "packet id should be \(packetId)")
        XCTAssert(pubackPacket.payload.count == 0, "packet payload should be empty")
    }

    func testPubRec_property() {
        let packetId = UInt16(10)
        
        var pubackPacket = PubRecPacket(packetId: 1231)
        
        pubackPacket.packetId = packetId
        XCTAssert(pubackPacket.packetId == packetId, "packet id should be \(packetId)")
    }
}

// MARK: - PubRel Packet
extension MqttPacketTests {
    
    func testPubRel_init() {
        let packetId = UInt16(10)
        
        let pubackPacket = PubRelPacket(packetId: packetId)
        
        XCTAssert(pubackPacket.fixHeader.type == .PUBREL, "packet type should be .PUBREL")
        XCTAssert(!pubackPacket.fixHeader.dup, "packet dup should be false")
        XCTAssert(!pubackPacket.fixHeader.retain, "packet flag should be false")
        XCTAssert(pubackPacket.fixHeader.qos == .Qos1, "packet flag should be .Qos1")
        XCTAssert(pubackPacket.fixHeader.flag == 0x02, "packet flag should be 0x02")
        XCTAssert(pubackPacket.packetId == packetId, "packet id should be \(packetId)")
        XCTAssert(pubackPacket.payload.count == 0, "packet payload should be empty")
    }
    
    func testPubRel_property() {
        let packetId = UInt16(10)
        
        var pubackPacket = PubRelPacket(packetId: 1231)
        
        pubackPacket.packetId = packetId
        XCTAssert(pubackPacket.packetId == packetId, "packet id should be \(packetId)")
    }

}

// MARK: - PubComp Packet
extension MqttPacketTests {
    
    func testPubComp_init() {
        let packetId = UInt16(10)
        
        let pubackPacket = PubCompPacket(packetId: packetId)
        
        XCTAssert(pubackPacket.fixHeader.type == .PUBCOMP, "packet type should be .PUBCOMP")
        XCTAssert(!pubackPacket.fixHeader.dup, "packet dup should be false")
        XCTAssert(!pubackPacket.fixHeader.retain, "packet flag should be false")
        XCTAssert(pubackPacket.fixHeader.qos == .Qos0, "packet flag should be .Qos0")
        XCTAssert(pubackPacket.fixHeader.flag == 0x00, "packet flag should be 0")
        XCTAssert(pubackPacket.packetId == packetId, "packet id should be \(packetId)")
        XCTAssert(pubackPacket.payload.count == 0, "packet payload should be empty")
    }
    
    func testPubComp_property() {
        let packetId = UInt16(10)
        
        var pubackPacket = PubCompPacket(packetId: 1231)
        
        pubackPacket.packetId = packetId
        XCTAssert(pubackPacket.packetId == packetId, "packet id should be \(packetId)")
    }

}

// MARK: - Subscribe Packet
extension MqttPacketTests {
    
    func testSubscribe_init() {
        let packetId = UInt16(123)
        let subscribePacket = SubscribePacket(packetId: packetId)
        
        XCTAssert(subscribePacket.fixHeader.type == .SUBSCRIBE, "packet type should be .SUBSCRIBE")
        XCTAssert(!subscribePacket.fixHeader.dup, "packet dup should be false")
        XCTAssert(subscribePacket.fixHeader.qos == .Qos1, "packet qos should be .Qos1")
        XCTAssert(!subscribePacket.fixHeader.retain, "packet retain should be false")
        XCTAssert(subscribePacket.fixHeader.flag == 0x02, "packet flag should be 0x02")
        
        XCTAssert(subscribePacket.packetId == packetId, "packet id should be \(packetId)")
        XCTAssert(subscribePacket.topics.count == 0, "packet topics count should be 0")
    }
    
    
    func testSubscribe_propterty() {
        let packetId = UInt16(123)
        var subscribePacket = SubscribePacket(packetId: 1234)
        
        subscribePacket.packetId = packetId
        XCTAssert(subscribePacket.packetId == packetId, "packet id should be \(packetId)")
        
        subscribePacket.topics.append(("topic1", .Qos0))
        subscribePacket.topics.append(("topic2", .Qos1))
        subscribePacket.topics.append(("topic3", .Qos2))
        XCTAssert(subscribePacket.topics.count == 3, "packet topics count should be 3")
        XCTAssert(subscribePacket.topics[0].0 == "topic1", "packet topic should be topic1")
        XCTAssert(subscribePacket.topics[1].0 == "topic2", "packet topic should be topic2")
        XCTAssert(subscribePacket.topics[2].0 == "topic3", "packet topic should be topic3")
        XCTAssert(subscribePacket.topics[0].1 == .Qos0, "packet topic reqqos should be .Qos0")
        XCTAssert(subscribePacket.topics[1].1 == .Qos1, "packet topic reqqos should be .Qos1")
        XCTAssert(subscribePacket.topics[2].1 == .Qos2, "packet topic reqqos should be .Qos2")
    }

}

// MARK: - SubAck Packet
extension MqttPacketTests {
    
    func testSubAck_init() {
        
    }
    
    func testSubAck_property() {
    
    }

}

// MARK: - UnSubscribe Packet
extension MqttPacketTests {
    
    func testUnsubscribe_init() {
    
    }
    
    func testUnsubscribe_property() {
    
    }
    
}

// MARK: - UnsubAck Packet
extension MqttPacketTests {
    
    func testUnsubAck_init() {
    
    }
    
    func testUnsubAck_property() {
    
    }

}

// MARK: - PingReq Packet
extension MqttPacketTests {
    
    func testPingReq_init() {
    
    }
    
    func testPingReq_property() {
    
    }
    
}

// MARK: - PingResp Packet
extension MqttPacketTests {
    
    func testPingResp_init() {
    
    }
    
    func testPingResp_property() {
    
    }
    
}

// MARK: - Disconnect Packet
extension MqttPacketTests {
    
    func testDisconect_init() {
    
    }
    
    func testDisconnect_property () {
    
    }
    
}