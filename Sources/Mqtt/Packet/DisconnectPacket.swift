//
//  DisconnectPacket.swift
//  Mqtt
//
//  Created by Heee on 16/2/3.
//  Copyright © 2016年 hjianbo.me. All rights reserved.
//

import Foundation

/**
 The DISCONNECT Packet is the final Control Packet sent from the Client to the Server. It indicates 
 that the Client is disconnecting cleanly.
 
 **Fixed Header:**
  1. type: disconnect(1110)
  2. flag: reserved(0000)
 
 **Variable Header:**
 The DISCONNECT Packet has no variable header.
 
 
 **Payload:**
 The DISCONNECT Packet has no payload.
 
 - note:
 
 After sending a DISCONNECTT Packet the Client:
  - MUST close the network Connection
  - MUST NOT send any more Control Packets on that Network Connection
 
 */
struct DisconnectPacket: Packet {
    
    var fixedHeader: FixedHeader
    
    var varHeader = [UInt8]()
    
    var payload   = [UInt8]()
    
    init() {
        fixedHeader = FixedHeader(type: .disconnect)
    }
}
