//
//  UnsubackPacket.swift
//  Mqtt
//
//  Created by Heee on 16/2/3.
//  Copyright © 2016年 hjianbo.me. All rights reserved.
//

import Foundation

struct UnsubAckPacket: Packet {
    
    var fixHeader: PacketFixHeader
    
    // MARK: Variable Header
    
    var packetId: UInt16
    
    var varHeader: Array<UInt8> {
        return packetId.bytes
    }
    
    // MARK: Payload
    var payload = Array<UInt8>()
    
    
    init(packetId: UInt16) {
        fixHeader = PacketFixHeader(type: .UNSUBACK)
        self.packetId = packetId
    }
}