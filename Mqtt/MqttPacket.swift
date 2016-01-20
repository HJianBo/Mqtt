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
    case RESERVED    = 0x00
    
    // Client to Server | Client request to connect to Server
    case CONNECT     = 0x10
    
    // Server to Client | Connect ack
    case CONNACK     = 0x20
    
    // Client -- Server | Publish message
    case PUBLISH     = 0x30
    
    // Client -- Server | Publish ack
    case PUBACK      = 0x40
    
    // Client -- Server | Publish received (assured delivery part 1)
    case PUBREC      = 0x50
    
    // Client -- Server | Publish release  (assured delivery part 2)
    case PUBREL      = 0x60
    
    // Client -- Server | Publish complete (assured delivery part 3)
    case PUBCOMP     = 0x70
    
    // Client to Server | Client subscribe request
    case SUBSCRIBE   = 0x80
    
    // Server to Client | Subscribe ack
    case SUBACK      = 0x90
    
    // Client to Server | Unsubcribe request
    case UNSUBSCRIBE = 0xA0
    
    // Server to Client | Unsubscribe ack
    case UNSUBACK    = 0xB0
    
    // Client to Server | PING Request
    case PINGREQ     = 0xC0
    
    // Server to Client | PING response
    case PINGRESP    = 0xD0
    
    // Client to Server | Client is disconnecting
    case DISCONNECT  = 0xE0
    
    // Forbidden        | Reserved
    case RESERVED2   = 0xF0
}




protocol PacketFixHeader {
    // mqtt control packet type
    var type: MqttPacketType { get }
    
    // flags
    var flag: UInt8 { get }
    
    // remaining length
    var remain: UInt8 { get }
}


protocol MqttPacket {
    
    // 1. Fixed header, require
    var fixHeader: PacketFixHeader { get }
    
    // 2. Variable header, optional
    var varHeader: Array<UInt8>? { get }
    
    // 3. Payload, optional
    var payload: Array<UInt8>? { get }
}






