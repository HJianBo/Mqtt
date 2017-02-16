//
//  PubackPacket.swift
//  Mqtt
//
//  Created by Heee on 16/2/2.
//  Copyright © 2016年 hjianbo.me. All rights reserved.
//

import Foundation

struct PubAckPacket: Packet {
    
    var fixedHeader: FixedHeader
    
    var packetId: UInt16
    
    var varHeader: Array<UInt8> {
        return packetId.bytes
    }
    
    var payload = [UInt8]()
    
    init(packetId: UInt16) {
        fixedHeader = FixedHeader(type: .puback)
        self.packetId = packetId
    }
}

extension PubAckPacket: InitializeWithResponse {
    init(header: FixedHeader, bytes: [UInt8]) {
        fixedHeader = header
        
        packetId = UInt16(bytes[0])*256+UInt16(bytes[1])
    }
}

extension PubAckPacket {
    public var description: String {
        return "PubAck(packetId: \(packetId))"
    }
}
