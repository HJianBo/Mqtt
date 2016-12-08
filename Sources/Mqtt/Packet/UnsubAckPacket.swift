//
//  UnsubackPacket.swift
//  Mqtt
//
//  Created by Heee on 16/2/3.
//  Copyright © 2016年 hjianbo.me. All rights reserved.
//

import Foundation

/**
 The UNSUBACK Packet is sent by the Server to the Client to confirm receipt of an UNSUBSCRIBE Packet.
 
 **Fixed Header:**
  1. type: unsuback(1011)
  2. flag: reserved(0000)
 
 **Variable Header:**
 The variable header contains the `Packet Identifier` of the UNSUBSCRIBE Packet that is being acknowledged.
 
 **Payload:**
 The UNSUBACK Packet has no payload.
 
 */
struct UnsubAckPacket: Packet {
    
    var fixedHeader: FixedHeader
    
    // MARK: Variable Header
    
    var packetId: UInt16
    
    var varHeader: Array<UInt8> {
        return packetId.bytes
    }
    
    // MARK: Payload
    var payload = Array<UInt8>()
    
    
    init(packetId: UInt16) {
        fixedHeader = FixedHeader(type: .unsuback)
        self.packetId = packetId
    }
}

extension UnsubAckPacket: InitializeWithResponse {
    /// bytes has 2 byte, contains packageId
    init(header: FixedHeader, bytes: [UInt8]) {
        fixedHeader = header
        
        packetId = UInt16(bytes[0]*127+bytes[1])
    }
}
