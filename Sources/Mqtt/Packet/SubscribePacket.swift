//
//  SubscribePacket.swift
//  Mqtt
//
//  Created by Heee on 16/2/3.
//  Copyright © 2016年 hjianbo.me. All rights reserved.
//

import Foundation

/**
 The SUBSCRIBE Packet is sent from the Client to the Server to create one or more Subscriptions.
 
 The SUBSCRIBE Packet also specifies (for each Subscription) the maximum QoS with which the Server
 can send Application Messages to the Client
 
 **Fixed Header:**
  1. type: subcribe(1000)
  2. flag: reserved(0010)
 Bits 3,2,1 and 0 of the fixed header of the `SUBSCRIBE` Control Packet are **reserved** and MUST be
 set 0,0,1 and 0 respectively. the Server MUST treat any other value as malformed and close the Network
 Connection.
 
 **Variable Header:**
 The variable header contains a `Packet Identifier`.
 
 **Payload:**
 The payload of a SUBCRIBE Packet contains `a list of Topic Filters` indicating the Topics to which the
 Client wants to subscribe.

 */
public struct SubscribePacket: Packet {
    
    var fixedHeader: FixedHeader
    
    // MARK: Varibale Header
    public var packetId: UInt16
    
    var varHeader: Array<UInt8> {
        return packetId.bytes
    }
    
    // MARK: Payload
    public var topics = Array<(String, Qos)>()
    
    var payload: Array<UInt8> {
        var value = [UInt8]()
        let tmp = topics.map { $0.0.mq_stringData + [$0.1.rawValue] }
        for d in tmp {
            value.append(contentsOf: d)
        }
        return value
    }
    
    
    init(packetId: UInt16) {
        fixedHeader     =  FixedHeader(type: .subscribe)
        // flag reserved values (0010)
        fixedHeader.qos = .qos1
        
        self.packetId     = packetId
    }
}
