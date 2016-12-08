//
//  UnsubscribePacket.swift
//  Mqtt
//
//  Created by Heee on 16/2/3.
//  Copyright © 2016年 hjianbo.me. All rights reserved.
//

import Foundation

/**
 An UNSUBSCRIBE Packet is sent by the Client to the Server, to unsubscribe from topics.
 
 **Variable Header:** 
 The variable header contains a Packet Identifier.
 
 **Payload:**
 The payload for the UNSUBSCRIBE Packet contains the list of Topic Filters that the Client wishes to
 unsubscribe from.
 
  1. The Topic Filters in an UNSUBSCRIBE packet MUST be UTF-8 encoded strings.
 
  2. The Payload of an UNSUBSCRIBE packet MUST contain at least one Topic Filter. An UNSUBSCRIBE
     packet with no payload
 
 */
public struct UnsubscribePacket: Packet {
    
    var fixedHeader: FixedHeader
    
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
            value.append(contentsOf: d)
        }
        return value
    }
    
    init(packetId: UInt16) {
        fixedHeader = FixedHeader(type: .unsubscribe)
        fixedHeader.qos = .qos1

        self.packetId = packetId
    }
}
