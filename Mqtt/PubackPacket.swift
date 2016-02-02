//
//  PubackPacket.swift
//  Mqtt
//
//  Created by Heee on 16/2/2.
//  Copyright © 2016年 beidouapp. All rights reserved.
//

import Foundation


struct PubackPacket: Packet {
    
    var fixHeader: PacketFixHeader
    
    var packetId: UInt16
    
    var varHeader: Array<UInt8> {
        return packetId.bytes
    }
    
    var payload = Array<UInt8>()
    
    init(packetId: UInt16) {
        fixHeader = PacketFixHeader(type: .PUBACK)
        self.packetId = packetId
    }
}