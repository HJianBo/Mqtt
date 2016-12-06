//
//  PublishPacket.swift
//  Mqtt
//
//  Created by Heee on 16/2/2.
//  Copyright © 2016年 hjianbo.me. All rights reserved.
//

import Foundation

/**
 A PUBLISH Control Packet is sent from a Client to a Server or from Server to a Client to transport an
 Application Message.
 
 **Fixed Header:**
  1. type: publish(0011)
  2. flag: dup,qos,retain
 
 **Variable Header:**
 The variable header contains the following fields in the order: `Topic Name`, `Packet Identifier`.
  1. Topic Name: The Topic Name identifies the information channel to which payload data is published.
                 The Topic Name in the PUBLISH Packet MUST NOT contain wildcard characters
 
  2. Packet Identifier: The Packet Identifier field is only present in PUBLISH Packets where the 
                        QoS level is 1 or 2
 
 **Payload:**
 The Payload contains the Application Message that is being published. The content and format of the
 data is application specific. The length of the payload can be calculated by subtracting the length 
 of the variable header from the Remaining Length field that is in the Fixed Header. *It is valid for
 a PUBLISH Packet to contain a zero length payload*.
 */
public struct PublishPacket: Packet {
    
    var fixedHeader: FixedHeader
    
    // MARK: Variable Header
    public var topicName: String
    
    public var packetId: UInt16
    
    var varHeader: Array<UInt8> {
        var value = topicName.mq_stringData
        
        if fixedHeader.qos > .qos0 {
            value.append(contentsOf: packetId.bytes)
        }
        return value
    }
    
    public var payload: Array<UInt8>
    
    init(packetId: UInt16, topic: String, payload: Array<UInt8>, dup: Bool = false, qos: Qos = .qos0, retain: Bool = false) {
        fixedHeader = FixedHeader(type: .publish)
        
        self.topicName = topic
        self.packetId  = packetId
        
        self.fixedHeader.dup = dup
        self.fixedHeader.qos = qos
        self.fixedHeader.retain = retain
        self.payload = payload
    }
}

extension PublishPacket: InitializeWithResponse {
    init(header: FixedHeader, bytes: [UInt8]) {
        fixedHeader = header
        
        // parse topic
        let topicLen = Int(bytes[0]*127 + bytes[1])
        topicName = String(bytes: bytes[2..<topicLen+2], encoding: .utf8)!
        
        // parse qos and payload
        if fixedHeader.qos > .qos0 {
            packetId = UInt16(bytes[topicLen+2]*127 + bytes[topicLen+3])
            payload = Array<UInt8>(bytes.suffix(from: topicLen+4))
        } else {
            packetId = 0
            payload = Array<UInt8>(bytes.suffix(from: topicLen+2))
        }
    }
}


