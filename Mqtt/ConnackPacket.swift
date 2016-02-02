//
//  MqttConnackPacket.swift
//  Mqtt
//
//  Created by Heee on 16/2/2.
//  Copyright © 2016年 beidouapp. All rights reserved.
//

import Foundation

enum ConnackReturnCode: UInt8 {
    /// Connection accepted
    case Accepted = 0x00
    
    /// The Server does not support the level of the MQTT protocol requested by the Client
    case UnAccepableProtocolVersion  = 0x01
    
    /// The Client identifier is correct UTF-8 but not allowed by the Server
    case IdentifierRejected = 0x02
    
    /// The Network Connection has been made but the MQTT service is unavailable
    case ServerUnavailable = 0x03

    /// The data in the user name or password is malformed
    case BadUsernameOrPassword = 0x04
    
    /// The Client is not authorized to connect
    case NotAuthorized = 0x05
}

struct ConnackPacket: Packet {
    
    var fixHeader: PacketFixHeader

    // MARK: Variable Header
    var connackFlags: UInt8 = 0
    
    var returnCode: ConnackReturnCode = .Accepted
    
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
        fixHeader = PacketFixHeader(type: .CONNACK)
    }
}


