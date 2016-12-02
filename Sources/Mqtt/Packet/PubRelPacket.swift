//
//  PubrelPacket.swift
//  Mqtt
//
//  Created by Heee on 16/2/2.
//  Copyright © 2016年 hjianbo.me. All rights reserved.
//

import Foundation

/**
 A PUBREL Packet is the response to a PUBREC Packet. It is the third packet of the QoS 2 protocol exchange
 
 **Fixed Header:**
  1. Bits 3,2,1,and 0 of the fixed header in the PUBREL Control Packet are reserved and MUST be set 
     to 0,0,1,and 0 respectovely. The Server MUST treat any other value as malformed and close the 
     Network Connection.
  2. *Remaining Length field:* This is the length of the variable header. For the PUBREL Packet
                               this has the value 2.

 
 **Variable Header:**
 The variable header contains the same Packet Identifier as the PUBREC Packet that is being
 acknowledged.
 
 **Payload:**
 The PUBREL Packet has no payload.
 
 */
struct PubRelPacket: Packet {
    
    /// flag is reserved, the value is 0010
    var fixHeader: PacketFixHeader
    
    var packetId: UInt16
    
    var varHeader: Array<UInt8> {
        return packetId.bytes
    }
    
    var payload = [UInt8]()
    
    init(packetId: UInt16) {
        fixHeader = PacketFixHeader(type: .pubrel)
        
        // set flag to 0010
        fixHeader.qos = .qos1
        self.packetId = packetId
    }
}
