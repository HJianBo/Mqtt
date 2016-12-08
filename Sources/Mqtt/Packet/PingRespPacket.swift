//
//  PingRespPacket.swift
//  Mqtt
//
//  Created by Heee on 16/2/3.
//  Copyright © 2016年 hjianbo.me. All rights reserved.
//

import Foundation

/**
 A PINGRESP Packet is sent by the Server to the Client in response to a PINGREQ Packet. It indicates 
 that the Server is alive.
 
 **Fixed Header:**
  1. type: pingresp(1100)
  2. flag: reserved(0000)
 
 **Variable Header:**
 The PINGRESP Packet has no variable header.
 
 **Payload:**
 The PINGRESP Packet has no payload.
 */
public struct PingRespPacket: Packet {
    
    var fixedHeader: FixedHeader
    
    var varHeader = [UInt8]()
    
    var payload   = [UInt8]()
    
    init() {
        fixedHeader = FixedHeader(type: .pingresp)
    }
}

extension PingRespPacket: InitializeWithResponse {
    // bytes should be empty
    init(header: FixedHeader, bytes: [UInt8]) {
        fixedHeader = header
    }
}
