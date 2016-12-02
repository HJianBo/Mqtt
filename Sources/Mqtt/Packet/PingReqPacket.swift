//
//  PingReqPacket.swift
//  Mqtt
//
//  Created by Heee on 16/2/3.
//  Copyright © 2016年 hjianbo.me. All rights reserved.
//

import Foundation
/**
 The PINGREQ Packet is sent from a Client to the Server. It can be used to:
 
  1. Indicate to the Server that the Client is alive in the absence of any other Control Packets 
     being sent from the Client to the Server.
  2. Request that the Server responds to confirm that it is alive.
  3. Exercise the network to indicate that the Network Connection is active.
 
 **Variable Header:**
 The PINGREQ Packet has no variable header.
 
 **Payload:**
 The PINGREQ Packet has no payload.
 */
struct PingReqPacket: Packet {
    
    var fixHeader: PacketFixHeader
    
    var varHeader = [UInt8]()
    
    var payload   = [UInt8]()
    
    init() {
        fixHeader = PacketFixHeader(type: .pingreq)
    }
}
