//
//  PubrecPacket.swift
//  Mqtt
//
//  Created by Heee on 16/2/2.
//  Copyright © 2016年 hjianbo.me. All rights reserved.
//

import Foundation

/**
 PUBREC Packet is the response to a PUBLISH Packet with QoS 2. It is the second packet of the QoS
 2 protocol exchange.
 
 **Fixed Header:**
  1. *Remaining Length field:* This is the length of the variable header.
                               For the PUBREC Packet this has the value 2.
 
 **Variable Header:**
 The variable header contains the Packet Identifier from the PUBLISH Packet that is being acknowledged.
 
 **Payload:**
 The PUBREC Packet has no payload.

 */
struct PubRecPacket: Packet {
    
    var fixedHeader: FixedHeader
    
    var packetId: UInt16
    
    var varHeader: Array<UInt8> {
        return packetId.bytes
    }
    
    var payload = [UInt8]()
    
    init(packetId: UInt16) {
        fixedHeader = FixedHeader(type: .pubrec)
        self.packetId = packetId
    }
}

extension PubRecPacket: InitializeWithResponse {
    
    init(header: FixedHeader, bytes: [UInt8]) {
        self.fixedHeader = header
        
        packetId = UInt16(bytes[0])*256+UInt16(bytes[1])
    }
}

extension PubRecPacket {
    public var description: String {
        return "PubRec(packetId: \(packetId))"
    }
}
