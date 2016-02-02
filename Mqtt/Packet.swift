//
//  Packet.swift
//  Mqtt
//
//  Created by Heee on 16/1/18.
//  Copyright © 2016年 jianbo. All rights reserved.
//

import Foundation


enum PacketType: UInt8 {
    
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

enum Qos: UInt8 {
    
    case Qos0 = 0
    
    case Qos1 = 1
    
    case Qos2 = 2
}

extension Qos: Comparable { }

func < (lhs: Qos, rhs: Qos) -> Bool {
    return lhs.rawValue < rhs.rawValue
}

func <= (lhs: Qos, rhs: Qos) -> Bool {
    return lhs.rawValue <= rhs.rawValue
}
func > (lhs: Qos, rhs: Qos) -> Bool {
    return lhs.rawValue > rhs.rawValue
}
func >= (lhs: Qos, rhs: Qos) -> Bool {
    return lhs.rawValue >= rhs.rawValue
}


/**
 *  Each MQTT Control Packet contains a fixed header
 */
struct PacketFixHeader {
    
    /// mqtt control packet type
    var type: PacketType = .RESERVED
    
    /// flags
    var flag: UInt8 = 0x00
    
    init(type: PacketType = .RESERVED) {
        self.type = type
    }
    
    
    /// Duplicate delivery of a PUBLISH Control Packet
    var dup: Bool {
        get {
            return Bool(intValue: flag & UInt8(0x08))
        }
        
        set {
            flag = flag | (newValue.rawValue << 3)
        }
    }
    
    ///  PUBLISH Quality of Service
    var qos: Qos {
        
        get {
            return Qos(rawValue: flag & UInt8(0x03))!
        }
        
        set {
            flag = flag | (newValue.rawValue << 1)
        }
    }
    
    /// PUBLISH Retain flag
    var retain: Bool {
        get {
            return Bool(intValue: flag & UInt8(0x01))
        }
        
        set {
            flag = flag | newValue.rawValue
        }
    }
}

extension PacketFixHeader {
    
    var packToData: NSData {
        return NSData(bytes: packToBytes, length: packToBytes.count)
    }
    
    var packToBytes: Array<UInt8> {
        // FIXME: tpye != .PUBLISH, flag = 0
        return [type.rawValue & 0xF0 | flag & 0x0F]// + remain.bytes
    }
}


protocol Packet {
    
    // 1. Fixed header, require
    var fixHeader: PacketFixHeader { get }
    
    // 2. Variable header, optional
    var varHeader: Array<UInt8> { get }
    
    // 3. Payload, optional
    var payload: Array<UInt8> { get }
}


extension Packet {

    var packToData: NSData {
        return NSData(bytes: packToBytes, length: packToBytes.count)
    }
    
    var packToBytes: Array<UInt8> {
        return fixHeader.packToBytes + remainLength + varHeader + payload
    }
    
    var remainLength: Array<UInt8> {
        var bytes: [UInt8] = []
        var digit: UInt8 = 0
        var len: UInt32 = UInt32(varHeader.count+payload.count)
        repeat {
            digit = UInt8(len % 128)
            len = len / 128
            // if there are more digits to encode, set the top bit of this digit
            if len > 0 { digit = digit | 0x80 }
            bytes.append(digit)
        } while len > 0
        
        return bytes
    }
}

extension Packet {
    var description: String {
        return "\n fixheader: \(fixHeader).\n remainlen: \(remainLength).\n varheader: \(varHeader).\n payload: \(payload).\n"
    }
}