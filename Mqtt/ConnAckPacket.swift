//
//  ConnAckPacket.swift
//  Mqtt
//
//  Created by Heee on 16/2/2.
//  Copyright © 2016年 hjianbo.me. All rights reserved.
//

import Foundation

enum ConnAckReturnCode: UInt8 {
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

struct ConnAckPacket: Packet {
    
    var fixHeader: PacketFixHeader

    // MARK: Variable Header
    
    var connackFlags: UInt8 = 0
    
    var returnCode: ConnAckReturnCode = .accepted
    
    var sessionPresent: Bool {
        get {
            return Bool(intValue: connackFlags.bitAt(0))
        }
        set {
            connackFlags.setBit(newValue.rawValue, at: 0)
        }
    }
    
    var varHeader: Array<UInt8> {
        return [connackFlags, returnCode.rawValue]
    }

    var payload = Array<UInt8>()
    
    init() {
        fixHeader = PacketFixHeader(type: .connack)
    }
    
    
    init(header: PacketFixHeader, bytes: [UInt8]) {
        fixHeader = header
        
        connackFlags = bytes[0]
        returnCode = ConnAckReturnCode(rawValue: bytes[1])!
    }
}


