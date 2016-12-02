//
//  PublishPacket.swift
//  Mqtt
//
//  Created by Heee on 16/2/2.
//  Copyright © 2016年 hjianbo.me. All rights reserved.
//

import Foundation

public struct PublishPacket: Packet {
    
    var fixHeader: PacketFixHeader
    
    // MARK: Variable Header
    public var topicName: String
    
    var packetId: UInt16
    
    var varHeader: Array<UInt8> {
        var value = topicName.mq_stringData
        
        if fixHeader.qos > .qos0 {
            value.append(contentsOf: packetId.bytes)
        }
        return value
    }
    
    public var payload: Array<UInt8>
    
    init(packetId: UInt16, topic: String, payload: Array<UInt8>, dup: Bool = false, qos: Qos = .qos0, retain: Bool = false) {
        fixHeader = PacketFixHeader(type: .publish)
        
        self.topicName = topic
        self.packetId  = packetId
        
        self.fixHeader.dup = dup
        self.fixHeader.qos = qos
        self.fixHeader.retain = retain
        self.payload = payload
    }
}
