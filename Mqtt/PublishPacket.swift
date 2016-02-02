//
//  PublishPacket.swift
//  Mqtt
//
//  Created by Heee on 16/2/2.
//  Copyright © 2016年 beidouapp. All rights reserved.
//

import Foundation

struct PublishPacket: Packet {
    
    var fixHeader: PacketFixHeader
    
    // MARK: Variable Header
    var topicName: String
    
    var packetId: UInt16
    
    var varHeader: Array<UInt8> {
        var value = topicName.mq_stringData
        
        if fixHeader.qos > .Qos0 {
            value.appendContentsOf(packetId.bytes)
        }
        return value
    }
    
    var payload: Array<UInt8>
    
    init(packetId: UInt16, topic: String, payload: Array<UInt8>, dup: Bool = false, qos: Qos = .Qos1, retain: Bool = true) {
        fixHeader = PacketFixHeader(type: .PUBLISH)
        
        self.topicName = topic
        self.packetId  = packetId
        
        self.fixHeader.dup = dup
        self.fixHeader.qos = qos
        self.fixHeader.retain = retain
        self.payload = payload
    }
}
