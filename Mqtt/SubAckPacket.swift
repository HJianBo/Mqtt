//
//  SubackPacket.swift
//  Mqtt
//
//  Created by Heee on 16/2/3.
//  Copyright © 2016年 beidouapp. All rights reserved.
//

import Foundation

enum SubsAckReturnCode: UInt8 {
    
    case MaxQos0 = 0x00
    
    case MaxQos1 = 0x01
    
    case MaxQos2 = 0x02
    
    case Failure = 0x80
}


struct SubAckPacket: Packet {
    
    var fixHeader: PacketFixHeader
    
    // MARK: Varibale Header
    var packetId: UInt16

    var varHeader: Array<UInt8> {
        return packetId.bytes
    }
    
    // MARK: Payload
    
    var returnCodes = Array<SubsAckReturnCode>()
    
    var payload: Array<UInt8> {
        return returnCodes.map { $0.rawValue }
    }
    
    init(packetId: UInt16) {
        fixHeader = PacketFixHeader(type: .SUBACK)
        
        self.packetId = packetId
    }
}