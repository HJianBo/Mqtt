//
//  SubscribePacket.swift
//  Mqtt
//
//  Created by Heee on 16/2/3.
//  Copyright © 2016年 beidouapp. All rights reserved.
//

import Foundation

struct SubscribePacket: Packet {
    
    var fixHeader: PacketFixHeader
    
    // MARK: Varibale Header
    var packetId: UInt16
    
    var varHeader: Array<UInt8> {
        return packetId.bytes
    }
    
    // MARK: Payload
    var topics = Array<(String, Qos)>()
    
    var payload: Array<UInt8> {
        var value = [UInt8]()
        let tmp = topics.map { $0.0.mq_stringData + [$0.1.rawValue] }
        for d in tmp {
            value.appendContentsOf(d)
        }
        return value
    }
    
    
    init(packetId: UInt16) {
        fixHeader     =  PacketFixHeader(type: .SUBSCRIBE)
        fixHeader.qos = .Qos1
        
        self.packetId     = packetId
    }
}