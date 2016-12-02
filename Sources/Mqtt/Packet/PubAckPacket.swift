//
//  PubackPacket.swift
//  Mqtt
//
//  Created by Heee on 16/2/2.
//  Copyright © 2016年 hjianbo.me. All rights reserved.
//

import Foundation

struct PubAckPacket: Packet {
    
    var fixHeader: PacketFixHeader
    
    var packetId: UInt16
    
    var varHeader: Array<UInt8> {
        return packetId.bytes
    }
    
    var payload = [UInt8]()
    
    init(packetId: UInt16) {
        fixHeader = PacketFixHeader(type: .puback)
        self.packetId = packetId
    }
    
    init(header: PacketFixHeader, bytes: [UInt8]) {
        fixHeader = header
        
        packetId = UInt16(bytes[0]*127 + bytes[1])
    }
}
