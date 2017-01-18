//
//  ConnAckPacket.swift
//  Mqtt
//
//  Created by Heee on 16/2/2.
//  Copyright © 2016年 hjianbo.me. All rights reserved.
//

import Foundation

public enum ConnAckReturnCode: UInt8 {
    /// Connection accepted
    case accepted = 0x00
    
    /// The Server does not support the level of the MQTT protocol requested by the Client
    case unAccepableProtocolVersion  = 0x01
    
    /// The Client identifier is correct UTF-8 but not allowed by the Server
    case identifierRejected = 0x02
    
    /// The Network Connection has been made but the MQTT service is unavailable
    case serverUnavailable = 0x03

    /// The data in the user name or password is malformed
    case badUsernameOrPassword = 0x04
    
    /// The Client is not authorized to connect
    case notAuthorized = 0x05
}

/**
 The CONNACK Packet is the packet sent by the Server in response to a CONNECT Packet received from a Client
 
 */
public struct ConnAckPacket: Packet {
    
    var fixedHeader: FixedHeader

    // MARK: Variable Header
    
    var connackFlags: UInt8 = 0
    
    public var returnCode: ConnAckReturnCode = .accepted
    
    /**
     The variable header for the CONNACK Packet consists of twi fields in the following order:
     `Connect Acknowledge Flags`, `Connect Return Code`.
     
     */
    var varHeader: Array<UInt8> {
        return [connackFlags, returnCode.rawValue]
    }

    var payload = Array<UInt8>()
    
    public init() {
        fixedHeader = FixedHeader(type: .connack)
    }
}

// MARK: Variable Header Helper
extension ConnAckPacket {
    
    /**
     If the Server accepts a connnection with CleanSession set to 1, the Server MUST set `Sessiont Present`
     to 0 in the CONNACK packet in addition to setting a zero return code in the CONNACK packet.
     
     If the Server accepts a connection whih CleanSession set to 0, the value set in Session Persent 
     depends on whether the Server already has stored Session state for the supplied client ID. 
      1. If the Server has stored Session state. it MUST set Session Present to 1 in the CONNACK packet. 
      2. If the Server does not have stored Session state, it MUST set Session Present to 0 in the CONNACK packet.
     This is in addition to setting a zero return code in the CONNACK packet.
     */
    public var sessionPresent: Bool {
        get {
            return Bool(intValue: connackFlags.bitAt(0))
        }
        set {
            connackFlags.setBit(newValue.rawValue, at: 0)
        }
    }
}



extension ConnAckPacket: InitializeWithResponse {
    
    /**
     bytes count is 2 bytes
     byte1: return code
     byte2: connack flags
     */
    init(header: FixedHeader, bytes: [UInt8]) throws {
        guard bytes.count == 2 else {
            throw PacketError.byteCountIllegal
        }
        
        guard let code = ConnAckReturnCode(rawValue: bytes[1]) else {
            throw PacketError.byteContentIllegal
        }
        
        guard header.type == .connack else {
            throw PacketError.typeIllegal
        }
        
        fixedHeader = header
        connackFlags = bytes[0]
        returnCode = code
    }
}

extension ConnAckPacket {
    public var description: String {
        return "ConnAck(returnCode: \(returnCode), sessionPresent: \(sessionPresent))"
    }
}
