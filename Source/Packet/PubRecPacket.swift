//
//  PubrecPacket.swift
//  Mqtt
//
//  Created by Heee on 16/2/2.
//  Copyright © 2016年 hjianbo.me. All rights reserved.
//

import Foundation

struct PubRecPacket: Packet {
    
    var fixHeader: PacketFixHeader
    
    var packetId: UInt16
    
    var varHeader: Array<UInt8> {
        return packetId.bytes
    }
    
    var payload = [UInt8]()
    
    init(packetId: UInt16) {
        fixHeader = PacketFixHeader(type: .pubrec)
        self.packetId = packetId
    }
}
