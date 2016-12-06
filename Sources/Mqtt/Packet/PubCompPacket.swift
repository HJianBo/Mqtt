//
//  PubcompPacket.swift
//  Mqtt
//
//  Created by Heee on 16/2/2.
//  Copyright © 2016年 hjianbo.me. All rights reserved.
//

import Foundation

/**
 The PUBCOMP Packet is the response to a PUBREL Packet. It is the fourth and final packet of the QoS
 2 protocol exchange.
 
 **Fixed Header:**
  1. *Remaining Length field:* This is the length of the variable header. 
                               For the PUBCOMP Packet this has the value 2.
 
 **Variable Header:**
 The variable header contains the same Packet Identifier as the PUBREL Packet that is being
 acknowledged.
 
 **Payload:**
 The PUBCOMP Packet has no payload.
 
 */
struct PubCompPacket: Packet {
    
    var fixedHeader: FixedHeader
    
    var packetId: UInt16
    
    var varHeader: Array<UInt8> {
        return packetId.bytes
    }
    
    var payload = [UInt8]()
    
    init(packetId: UInt16) {
        fixedHeader = FixedHeader(type: .pubcomp)
        self.packetId = packetId
    }
}

extension PubCompPacket: InitializeWithResponse {
    
    init(header: FixedHeader, bytes: [UInt8]) {
        fixedHeader = header
        
        packetId = UInt16(bytes[0]*127 + bytes[1])
    }
}
