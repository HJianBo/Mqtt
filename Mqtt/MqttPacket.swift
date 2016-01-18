//
//  Packet.swift
//  Mqtt
//
//  Created by Heee on 16/1/18.
//  Copyright © 2016年 beidouapp. All rights reserved.
//

import Foundation


typealias Byte = UInt8

enum MqttPacketType: UInt8 {
    
    // Forbidden        | Reserved
    case RESERVED    = 0
    
    // Client to Server | Client request to connect to Server
    case CONNECT     = 1
    
    // Server to Client | Connect ack
    case CONNACK     = 2
    
    // Client -- Server | Publish message
    case PUBLISH     = 3
    
    // Client -- Server | Publish ack
    case PUBACK      = 4
    
    // Client -- Server | Publish received (assured delivery part 1)
    case PUBREC      = 5
    
    // Client -- Server | Publish release  (assured delivery part 2)
    case PUBREL      = 6
    
    // Client -- Server | Publish complete (assured delivery part 3)
    case PUBCOMP     = 7
    
    // Client to Server | Client subscribe request
    case SUBSCRIBE   = 8
    
    // Server to Client | Subscribe ack
    case SUBACK      = 9
    
    // Client to Server | Unsubcribe request
    case UNSUBSCRIBE = 10
    
    // Server to Client | Unsubscribe ack
    case UNSUBACK    = 11
    
    // Client to Server | PING Request
    case PINGREQ     = 12
    
    // Server to Client | PING response
    case PINGRESP    = 13
    
    // Client to Server | Client is disconnecting
    case DISCONNECT  = 14
    
    // Forbidden        | Reserved
    case RESERVED2   = 15
}


protocol MqttPacket {
    
    // 1. Fixed header, require

    // mqtt control packet type
    var type: MqttPacketType { get }
    
    // flags
    var flag: UInt8 { get }
    
    // remaining length
    var remain: UInt8 { get }
    
    // 2. Variable header, optional
    
    // 3. Payload, optional
}