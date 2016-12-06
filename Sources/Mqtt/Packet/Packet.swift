//
//  Packet.swift
//  Mqtt
//
//  Created by Heee on 16/1/18.
//  Copyright © 2016年 jianbo. All rights reserved.
//

import Foundation

// TODO: MUST TO SET 0, ASSERT ????

enum PacketType: UInt8 {
    
    // Forbidden        | Reserved
    case reserved    = 0x00
    
    // Client to Server | Client request to connect to Server
    case connect     = 0x01
    
    // Server to Client | Connect ack
    case connack     = 0x02
    
    // Client -- Server | Publish message
    case publish     = 0x03
    
    // Client -- Server | Publish ack
    case puback      = 0x04
    
    // Client -- Server | Publish received (assured delivery part 1)
    case pubrec      = 0x05
    
    // Client -- Server | Publish release  (assured delivery part 2)
    case pubrel      = 0x06
    
    // Client -- Server | Publish complete (assured delivery part 3)
    case pubcomp     = 0x07
    
    // Client to Server | Client subscribe request
    case subscribe   = 0x08
    
    // Server to Client | Subscribe ack
    case suback      = 0x09
    
    // Client to Server | Unsubcribe request
    case unsubscribe = 0x0A
    
    // Server to Client | Unsubscribe ack
    case unsuback    = 0x0B
    
    // Client to Server | PING Request
    case pingreq     = 0x0C
    
    // Server to Client | PING response
    case pingresp    = 0x0D
    
    // Client to Server | Client is disconnecting
    case disconnect  = 0x0E
    
    // Forbidden        | Reserved
    case reserved2   = 0x0F
}

public enum Qos: UInt8 {
    
    case qos0 = 0
    
    case qos1 = 1
    
    case qos2 = 2
}

extension Qos: Comparable { }

public func < (lhs: Qos, rhs: Qos) -> Bool {
    return lhs.rawValue < rhs.rawValue
}

public func <= (lhs: Qos, rhs: Qos) -> Bool {
    return lhs.rawValue <= rhs.rawValue
}
public func > (lhs: Qos, rhs: Qos) -> Bool {
    return lhs.rawValue > rhs.rawValue
}
public func >= (lhs: Qos, rhs: Qos) -> Bool {
    return lhs.rawValue >= rhs.rawValue
}


/**
 *  Each MQTT Control Packet contains a fixed header
 */
struct FixedHeader {
    
    /**
     *
     *
     */
    
    /// mqtt control packet type
    var type: PacketType = .reserved

    /// flags
    var flag: UInt8 = 0
    
    init(type: PacketType = .reserved) {
        self.type = type
    }
    
    init?(byte: UInt8) {
        guard let t = PacketType(rawValue: byte >> 4) else {
            return nil
        }
        
        type = t
        
        flag = byte & 0x0F
    }
}

/// Fixed Header flag members getter/setter
extension FixedHeader {
    /**
     Duplicate delivery of a PUBLISH Control Packet.
     
     
     The value of flag from an incoming PUBLISH packet is not propagated when the PUBLISH packet is sent to subscribers by the server.
     
     The DUP flag in the outgoing PUBLISH packet is set independently to incoming PUBLISH packet,  its value MUST be determined solely by whether the outgoing PUBLISH packet is a retransmission.
     
     */
    var dup: Bool {
        get { return ((flag & 0x08) >> 3 == 1) ? true : false }
        
        set {
            flag &= ~0x08
            flag |= newValue.rawValue << 3
        }
    }
    
    ///  PUBLISH Quality of Service
    var qos: Qos {
        get {
            guard let q = Qos(rawValue: (flag & 0x06) >> 1) else {
                assert(false, "invaild qos value")
                return .qos0
            }
            return q
        }
        
        set {
            flag &= ~0x06
            flag |= (newValue.rawValue << 1)
            
            // the DUP flag must set to 0 for all qos0 message
            if newValue == .qos0 { dup = false }
        }
    }
    
    /// PUBLISH Retain flag
    var retain: Bool {
        get { return ( flag & 0x01 == 1 ) ? true : false }
        set {
            flag &= ~0x01
            flag |= newValue.rawValue
        }
    }
}

extension FixedHeader {
    
    var packToData: Data {
        return Data(bytes: UnsafePointer<UInt8>(packToBytes), count: packToBytes.count)
    }
    
    var packToBytes: Array<UInt8> {
        // FIXME: tpye != .PUBLISH, flag = 0
        return [(type.rawValue << 4) & 0xF0 | flag & 0x0F]// + remain.bytes
    }
}


protocol Packet {
    
    // 1. Fixed header, require
    var fixedHeader: FixedHeader { get }
    
    // 2. Variable header, optional
    var varHeader: Array<UInt8> { get }
    
    // 3. Payload, optional
    var payload: Array<UInt8> { get }
}


extension Packet {

    var packToData: Data {
        return Data(bytes: UnsafePointer<UInt8>(packToBytes), count: packToBytes.count)
    }
    
    var packToBytes: Array<UInt8> {
        return fixedHeader.packToBytes + remainLength + varHeader + payload
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

///
protocol InitializeWithResponse {
    init(header: FixedHeader, bytes: [UInt8])
}
