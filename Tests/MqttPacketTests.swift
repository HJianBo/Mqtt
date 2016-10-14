//
//  MqttTests.swift
//  MqttTests
//
//  Created by Heee on 16/2/2.
//  Copyright © 2016年 jianbo. All rights reserved.
//

import XCTest
@testable import Mqtt

// TODO: Packet data Test??????
// TODO: Packt Property W/R Persmion Test ??

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
        XCTAssert(connetPacket.fixHeader.type == .connect, "packet type is error")
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
        XCTAssert(connetPacket.willQos == .qos0, "will qos should be 0")
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
        XCTAssert(connetPacket.willQos == .qos1, "will qos default should be .qos1")
        XCTAssert(connetPacket.willRetain == false, "will retain default should be false")
        
        connetPacket.willMessage = willMessage
        XCTAssert(connetPacket.willMessage == willMessage, "will message should be \(willMessage)")
        XCTAssert(connetPacket.willFlag, "will flag should be ture")
        XCTAssert(connetPacket.willQos == .qos1, "will qos default should be .qos1")
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
        XCTAssert(connetPacket.willQos == .qos0, "will qos default should be .qos0")
        XCTAssert(connetPacket.willRetain == false, "will retain default should be false")
        
        connetPacket.willMessage = nil
        XCTAssert(connetPacket.willMessage == nil, "will message should be nil")
        XCTAssert(connetPacket.willFlag == false, "will flag should be false")
        XCTAssert(connetPacket.willQos == .qos0, "will qos default should be .qos0")
        XCTAssert(connetPacket.willRetain == false, "will retain default should be false")
        
        connetPacket.userNameFlag = true
        XCTAssert(connetPacket.userNameFlag, "username flag should be true")
        
        connetPacket.passwordFlag = true
        XCTAssert(connetPacket.passwordFlag, "password flag should be true")
        
        connetPacket.willRetain = true
        XCTAssert(connetPacket.willRetain, "will retain should be true")
        
        connetPacket.willQos = .qos1
        XCTAssert(connetPacket.willQos == .qos1, "will qos should be .qos1")
        
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
        
        connetPacket.willQos = .qos0
        XCTAssert(connetPacket.willQos == .qos0, "will qos should be .qos0")
        
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
        
        XCTAssert(connackPacket.fixHeader.type == .connack, "fixheader type should be .connack")
        XCTAssert(connackPacket.connackFlags == 0, "connack flags should be 0")
        XCTAssert(!connackPacket.sessionPresent, "session present should be 0")
        XCTAssert(connackPacket.returnCode == .accepted, "return code default should be .accepted")
    }
    
    func testConnAck_property() {
        var connackPacket = ConnAckPacket()
        
        connackPacket.sessionPresent = true
        XCTAssert(connackPacket.connackFlags == 1, "connack flags should be 1")
        XCTAssert(connackPacket.sessionPresent, "session present should be true")
        
        connackPacket.sessionPresent = false
        XCTAssert(connackPacket.connackFlags == 0, "connack flags should be 0")
        XCTAssert(!connackPacket.sessionPresent, "session present should be false")
        
        connackPacket.returnCode = .badUsernameOrPassword
        XCTAssert(connackPacket.returnCode == .badUsernameOrPassword, "return code should be .badUsernameOrPassword")
        
        connackPacket.returnCode = .unAccepableProtocolVersion
        XCTAssert(connackPacket.returnCode == .unAccepableProtocolVersion, "return code should be .unAccepableProtocolVersion")
        
        connackPacket.returnCode = .notAuthorized
        XCTAssert(connackPacket.returnCode == .notAuthorized, "return code should be .notAuthorized")
        
        connackPacket.returnCode = .accepted
        XCTAssert(connackPacket.returnCode == .accepted, "return code should be .accepted")
    }
}


// MARK: - Publish Packet
extension MqttPacketTests {

    func testPublish_init() {
        let packetId = UInt16(1)
        let topic    = "This is topic"
        let payload: Array<UInt8> = [1, 2, 3, 4]
        
        let publishPacket = PublishPacket(packetId: packetId, topic: topic, payload: payload)
        
        XCTAssert(publishPacket.fixHeader.type == .publish, "packet type should .publish")
        XCTAssert(publishPacket.fixHeader.dup == false, "packet dup should be false")
        XCTAssert(publishPacket.fixHeader.qos == .qos0, "packet Qos should be .qos0")
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
        
        publishPacket.fixHeader.qos = .qos2
        XCTAssert(publishPacket.fixHeader.qos == .qos2, "packet qos should be .qos2")
        XCTAssert(publishPacket.fixHeader.flag == 0x04, "packet falge shpuld be 0x04")
        
        publishPacket.fixHeader.qos = .qos0
        XCTAssert(publishPacket.fixHeader.qos == .qos0, "packet qos should be .qos1")
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
        
        XCTAssert(pubackPacket.fixHeader.type == .puback, "packet type should be .puback")
        XCTAssert(!pubackPacket.fixHeader.dup, "packet dup should be false")
        XCTAssert(!pubackPacket.fixHeader.retain, "packet flag should be false")
        XCTAssert(pubackPacket.fixHeader.qos == .qos0, "packet flag should be .qos0")
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
        
        XCTAssert(pubackPacket.fixHeader.type == .pubrec, "packet type should be .pubrec")
        XCTAssert(!pubackPacket.fixHeader.dup, "packet dup should be false")
        XCTAssert(!pubackPacket.fixHeader.retain, "packet flag should be false")
        XCTAssert(pubackPacket.fixHeader.qos == .qos0, "packet flag should be .qos0")
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
        
        XCTAssert(pubackPacket.fixHeader.type == .pubrel, "packet type should be .pubrel")
        XCTAssert(!pubackPacket.fixHeader.dup, "packet dup should be false")
        XCTAssert(!pubackPacket.fixHeader.retain, "packet flag should be false")
        XCTAssert(pubackPacket.fixHeader.qos == .qos1, "packet flag should be .qos1")
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
        
        XCTAssert(pubackPacket.fixHeader.type == .pubcomp, "packet type should be .pubcomp")
        XCTAssert(!pubackPacket.fixHeader.dup, "packet dup should be false")
        XCTAssert(!pubackPacket.fixHeader.retain, "packet flag should be false")
        XCTAssert(pubackPacket.fixHeader.qos == .qos0, "packet flag should be .qos0")
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
        
        XCTAssert(subscribePacket.fixHeader.type == .subscribe, "packet type should be .subscribe")
        XCTAssert(!subscribePacket.fixHeader.dup, "packet dup should be false")
        XCTAssert(subscribePacket.fixHeader.qos == .qos1, "packet qos should be .qos1")
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
        
        subscribePacket.topics.append(("topic1", .qos0))
        subscribePacket.topics.append(("topic2", .qos1))
        subscribePacket.topics.append(("topic3", .qos2))
        XCTAssert(subscribePacket.topics.count == 3, "packet topics count should be 3")
        XCTAssert(subscribePacket.topics[0].0 == "topic1", "packet topic should be topic1")
        XCTAssert(subscribePacket.topics[1].0 == "topic2", "packet topic should be topic2")
        XCTAssert(subscribePacket.topics[2].0 == "topic3", "packet topic should be topic3")
        XCTAssert(subscribePacket.topics[0].1 == .qos0, "packet topic reqqos should be .qos0")
        XCTAssert(subscribePacket.topics[1].1 == .qos1, "packet topic reqqos should be .qos1")
        XCTAssert(subscribePacket.topics[2].1 == .qos2, "packet topic reqqos should be .qos2")
    }

}

// MARK: - SubAck Packet
extension MqttPacketTests {
    
    func testSubAck_init() {
        let packetId = UInt16(123)
        let subackPacket = SubAckPacket(packetId: packetId)
        
        XCTAssert(subackPacket.fixHeader.type == .suback, "packet type should be .suback")
        XCTAssert(subackPacket.fixHeader.flag == 0x00, "packet falg should be 0x00")
        XCTAssert(!subackPacket.fixHeader.dup, "packet dup should be false")
        XCTAssert(!subackPacket.fixHeader.retain, "packet retain should be false")
        XCTAssert(subackPacket.fixHeader.qos == .qos0, "packet Qos should be .qos0")
        
        XCTAssert(subackPacket.packetId == packetId, "packet id should be \(packetId)")
        
        XCTAssert(subackPacket.returnCodes.count == 0, "packet return code should be 0")
        XCTAssert(subackPacket.payload.count == 0, "packet payload should be 0")
    }
    
    func testSubAck_property() {
        let packetId = UInt16(834)
        
        var subackPacket = SubAckPacket(packetId: 123)
        
        subackPacket.packetId = packetId
        XCTAssert(subackPacket.packetId == packetId, "packet id should be \(packetId)")
        
        subackPacket.returnCodes.append(.maxQos0)
        subackPacket.returnCodes.append(.maxQos1)
        subackPacket.returnCodes.append(.maxQos2)
        subackPacket.returnCodes.append(.failure)
        
        XCTAssert(subackPacket.returnCodes[0] == .maxQos0, "packet return code index 0 should be .maxQos0")
        XCTAssert(subackPacket.returnCodes[1] == .maxQos1, "packet return code index 1 should be .maxQos1")
        XCTAssert(subackPacket.returnCodes[2] == .maxQos2, "packet return code index 2 should be .maxQos2")
        XCTAssert(subackPacket.returnCodes[3] == .failure, "packet return code index 3 should be .failure")

        XCTAssert(subackPacket.payload.count == 4, "packet payload count should be 4")
        XCTAssert(subackPacket.payload[0] == SubsAckReturnCode.maxQos0.rawValue, "packet payload 0 should be 0")
        XCTAssert(subackPacket.payload[1] == SubsAckReturnCode.maxQos1.rawValue, "packet payload 0 should be 1")
        XCTAssert(subackPacket.payload[2] == SubsAckReturnCode.maxQos2.rawValue, "packet payload 0 should be 2")
        XCTAssert(subackPacket.payload[3] == SubsAckReturnCode.failure.rawValue, "packet payload 0 should be 128")
    }
}

// MARK: - UnSubscribe Packet
extension MqttPacketTests {
    
    func testUnsubscribe_init() {
        let packetId = UInt16(893)
        
        let unsubsPacket = UnsubscribePacket(packetId: packetId)
        
        XCTAssert(unsubsPacket.fixHeader.type == .unsubscribe, "packet type should be .unsubscribe")
        XCTAssert(unsubsPacket.fixHeader.flag == 0x02, "packet flag should be 0x02")
        XCTAssert(!unsubsPacket.fixHeader.dup, "packet dup should be false")
        XCTAssert(!unsubsPacket.fixHeader.retain, "packet retain should be false")
        XCTAssert(unsubsPacket.fixHeader.qos == .qos1, "packet Qos should be .qos1")
        
        XCTAssert(unsubsPacket.packetId == packetId, "packet id should be \(packetId)")

        XCTAssert(unsubsPacket.topics.count == 0, "packet topics count should be 0")
        XCTAssert(unsubsPacket.payload.count == 0,"packet payload count should be 0")
    }
    
    func testUnsubscribe_property() {
        let packetId = UInt16(1982)
        let topics   = ["A/AD", "chat/userid", "$sys/settting/close"]
        
        var unsubsPacket = UnsubscribePacket(packetId: 1234)
        
        unsubsPacket.packetId = packetId
        XCTAssert(unsubsPacket.packetId == packetId, "packet id should be \(packetId)")
        
        
        unsubsPacket.topics.append(topics[0])
        unsubsPacket.topics.append(topics[1])
        unsubsPacket.topics.append(topics[2])
        XCTAssert(unsubsPacket.topics[0] == topics[0], "packet topics 0 should be \(topics[0])")
        XCTAssert(unsubsPacket.topics[1] == topics[1], "packet topics 1 should be \(topics[1])")
        XCTAssert(unsubsPacket.topics[2] == topics[2], "packet topics 2 should be \(topics[2])")
        
        // TODO: Test Payload ???
    }
}

// MARK: - UnsubAck Packet
extension MqttPacketTests {
    
    func testUnsubAck_init() {
        let packetId = UInt16(8892)
        
        let unsusackPacket = UnsubAckPacket(packetId: packetId)

        XCTAssert(unsusackPacket.fixHeader.type == .unsuback, "packet type should be .unsuback")
        XCTAssert(unsusackPacket.fixHeader.flag == 0x00, "packet flag should be 0")
        XCTAssert(!unsusackPacket.fixHeader.dup, "packet dup should be 0")
        XCTAssert(unsusackPacket.fixHeader.qos == .qos0, "packet Qos should be .qos0")
        XCTAssert(!unsusackPacket.fixHeader.retain, "packet retain should be false")
        
        XCTAssert(unsusackPacket.packetId == packetId, "packet id should be \(packetId)")
        XCTAssert(unsusackPacket.payload.count == 0, "packet payload count should be 0")
    }
    
    func testUnsubAck_property() {

        let packetId = UInt16(9872)
        
        var unsubsackPacket = UnsubscribePacket(packetId: 978)
        
        unsubsackPacket.packetId = packetId
        XCTAssert(unsubsackPacket.packetId == packetId, "packet id should be \(packetId)")
    }

}

// MARK: - PingReq Packet
extension MqttPacketTests {
    
    func testPingReq_init() {
        
        let pingreqPacket = PingReqPacket()
        
        XCTAssert(pingreqPacket.fixHeader.type == .pingreq, "packet type should be .pingreq")
        XCTAssert(pingreqPacket.fixHeader.flag == 0, "packet flag should be 0")
        XCTAssert(!pingreqPacket.fixHeader.dup, "packet dup should be false")
        XCTAssert(!pingreqPacket.fixHeader.retain, "packet retain should be false")
        XCTAssert(pingreqPacket.fixHeader.qos == .qos0, "packet Qos should be .qos0")
        
        XCTAssert(pingreqPacket.varHeader.count == 0, "packet varheader should be 0")
        XCTAssert(pingreqPacket.payload.count == 0, "packet payload should be 0")
    }
    
    func testPingReq_property() {
        // ...
    }
    
}

// MARK: - PingResp Packet
extension MqttPacketTests {
    
    func testPingResp_init() {
        let pingrespPacket = PingRespPacket()
        
        XCTAssert(pingrespPacket.fixHeader.type == .pingreq, "packet type should be .pingreq")
        XCTAssert(pingrespPacket.fixHeader.flag == 0, "packet flag should be 0")
        XCTAssert(!pingrespPacket.fixHeader.dup, "packet dup should be false")
        XCTAssert(!pingrespPacket.fixHeader.retain, "packet retain should be false")
        XCTAssert(pingrespPacket.fixHeader.qos == .qos0, "packet Qos should be .qos0")
        
        XCTAssert(pingrespPacket.varHeader.count == 0, "packet varheader should be 0")
        XCTAssert(pingrespPacket.payload.count == 0, "packet payload should be 0")
    }
    
    func testPingResp_property() {
        // ...
    }
    
}

// MARK: - Disconnect Packet
extension MqttPacketTests {
    
    func testDisconect_init() {
        let disconnectPacket = DisconnectPacket()
        
        XCTAssert(disconnectPacket.fixHeader.type == .disconnect, "packet type should be .disconnect")
        XCTAssert(disconnectPacket.fixHeader.flag == 0, "packet flag should be 0")
        XCTAssert(!disconnectPacket.fixHeader.dup, "packet dup should be false")
        XCTAssert(!disconnectPacket.fixHeader.retain, "packet retain should be false")
        XCTAssert(disconnectPacket.fixHeader.qos == .qos0, "packet Qos should be .qos0")
        
        XCTAssert(disconnectPacket.varHeader.count == 0, "packet varheader should be 0")
        XCTAssert(disconnectPacket.payload.count == 0, "packet payload should be 0")
    }
    
    func testDisconnect_property () {
        // ...
    }
    
}
