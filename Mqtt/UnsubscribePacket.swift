//
//  UnsubscribePacket.swift
//  Mqtt
//
//  Created by Heee on 16/2/3.
//  Copyright © 2016年 hjianbo.me. All rights reserved.
//

import Foundation


struct UnsubscribePacket: Packet {
    
    var fixHeader: PacketFixHeader
    
    // MARK: Variable Header
    var packetId: UInt16
    
    var varHeader: Array<UInt8> {
        return packetId.bytes
    }
    
    // MARK: Payload
    var topics = Array<String>()
    
    var payload: Array<UInt8> {
        
        var value = [UInt8]()
        let tmp = topics.map { $0.mq_stringData }
        for d in tmp {
            value.appendContentsOf(d)
        }
        return value
    }
    
    init(packetId: UInt16) {
        fixHeader = PacketFixHeader(type: .UNSUBSCRIBE)
        fixHeader.qos = .Qos1

        self.packetId = packetId
    }
}