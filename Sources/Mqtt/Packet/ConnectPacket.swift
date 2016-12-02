//
//  ConnectPacket.swift
//  Mqtt
//
//  Created by Heee on 16/2/1.
//  Copyright © 2016年 jianbo. All rights reserved.
//

import Foundation

let DefaultProtocolName  = "MQTT"
let DefaultProtocolLevel = UInt8(4)
let DefaultKeepAlive     = UInt16(60)

/**
 After a Network Connection is established by a Client to a Server, *the firse Packet sent from the*
 *Client to the Server MUST be a CONNECT Packet*.

 A Client can only send the CONNECT Packet once over a Network Connection. The Server MUST process
 a sencond CONNECT Packet sent from a Client as a protocol violation and disconnect the Client.

 The payload contains one or more encoded fields. They specify a unique Client identifier for the
 Client, a Will topic, Will Message, User Name and Password. All but the Client identifier are
 optional and their presence is determined based on flags in the variable header.
 
 **Fixed Header:**
  1. *Remaining Length field*: Remaining Length is the length of the variable header (10 bytes) plus
                               the length of the Payload.
 
 **Variable Header:**
 The variable header for the CONNECT Packet consists of four fields in the following order: 
  `Protocol Name`, `Protocol Level`, `Connect Flags`, `Keep Alive`.
 
 **Payload:**
 The payload of the CONNECT Packet contains one or more length-prefixed fields, whose presence is
 determined by the flags in the variable header.
 
 These fields, if present, MUST appear in the order 
 `Client Identifier`, `Will Topic`, `Will Message`, `User Name`, `Passwrod`
 
 */
struct ConnectPacket: Packet {
    
    var fixHeader: PacketFixHeader
    
    // MARK: Variable Header Members
    
    /// The Protocol Name is a UTF-8 encoded string that represents the protocol name "MQTT"
    var protocolName = DefaultProtocolName
    
    /// The value of the Protocol Level field for the version 3.1.1 of the protocol is 4 (0x04).
    var protocolLevel: UInt8 = DefaultProtocolLevel
    
    /**
     The Connect Flags byte contains a number of parameters specifying the behavior
     of the MQTT connection. It also indicates the presence or absence of fields in
     the payload.
     */
    var connectFlags: UInt8  = 0
    
    var keepAlive: UInt16    = DefaultKeepAlive
    
    ///
    var varHeader: Array<UInt8> {
        get {
            var value = Array<UInt8>()
            value.append(contentsOf: protocolName.mq_stringData)
            value.append(protocolLevel)
            value.append(connectFlags)
            value.append(contentsOf: keepAlive.bytes)
            return value
        }
    }
    
    // MARK: Payload
    
    /// Required.
    var clientId: String
    
    var willTopic: String? {
        didSet {
            if willTopic != nil {
                willFlag   = true
            } else {
                willFlag   = false
            }
        }
    }
    
    /// if Will Message is set to 0, Will Flag also auto set to 0
    var willMessage: String? {
        didSet {
            if willMessage != nil {
                willFlag   = true
            } else {
                willFlag   = false
            }
        }
    }
    
    
    var userName: String? {
        didSet {
            userNameFlag = (userName != nil)
        }
    }
    
    var password: String? {
        didSet {
            passwordFlag = password != nil
        }
    }
    
    
    var payload: Array<UInt8> {
        get {
            var value = Array<UInt8>()
            
            value.append(contentsOf: clientId.mq_stringData)
            
            if (willFlag) {
                if let topic = willTopic {
                    value.append(contentsOf: topic.mq_stringData)
                } else {
                    value.append(contentsOf: "".mq_stringData)
                }
                
                if let message = willMessage {
                    value.append(contentsOf: message.mq_stringData)
                } else {
                    value.append(contentsOf: "".mq_stringData)
                }
            }
            
            if userNameFlag {
                if let uname = userName {
                    value.append(contentsOf: uname.mq_stringData)
                } else {
                    value.append(contentsOf: "".mq_stringData)
                }
            }
            
            if passwordFlag {
                if let pwd = password {
                    value.append(contentsOf: pwd.mq_stringData)
                } else {
                    value.append(contentsOf: "".mq_stringData)
                }
            }
            
            return value
        }
    }
    
    init(clientId id: String) {
        clientId = id
        fixHeader = PacketFixHeader(type: .connect)
    }
}


/// Connect Flags
extension ConnectPacket {
    /**
     
     
     +--------------------------------------------------------------------------------------------------+
     |       bit7     |      bit6     |     bit5    | bit4  bit3 |    bit2   |      bit1     |   bit0   |
     | User Name Flag | Password Flag | Will Retain |  Will Qos  | Will Falg | Clean session | Reserved |
     +--------------------------------------------------------------------------------------------------+
     */
    
    var userNameFlag: Bool {
        get {
            return Bool(intValue: connectFlags.bitAt(7))
        }
        
        set {
            connectFlags.setBit(newValue.rawValue, at: 7)
        }
    }
    
    var passwordFlag: Bool {
        get {
            return Bool(intValue: connectFlags.bitAt(6))
        }
        
        set {
            connectFlags.setBit(newValue.rawValue, at: 6)
        }
    }
    
    var willRetain: Bool {
        get {
            return Bool(intValue: connectFlags.bitAt(5))
        }
        set {
            connectFlags.setBit(newValue.rawValue, at: 5)
        }
    }
    
    var willQos: Qos {
        get {
            return Qos(rawValue: connectFlags.bitAt(4)*2 + connectFlags.bitAt(3))!
        }
        
        set {
            switch newValue {
            case .qos0:
                connectFlags.setBit(0, at: 4)
                connectFlags.setBit(0, at: 3)
                break
            case .qos1:
                connectFlags.setBit(0, at: 4)
                connectFlags.setBit(1, at: 3)
                break
            case .qos2:
                connectFlags.setBit(1, at: 4)
                connectFlags.setBit(0, at: 3)
                break
            }
        }
    }
    
    /**
     If the Will Flag is set to 0 
     the Will QoS and Will Retain fields in the Connect Flags MUST be set to zero
     and the Will Topic and Will Message fields MUST NOT be present in the payload
    */
    var willFlag: Bool {
        get {
            return Bool(intValue: connectFlags.bitAt(2))
        }
        
        set {
            connectFlags.setBit(newValue.rawValue, at: 2)
            if newValue {
                // Default. Configuration
                willQos = .qos1
            } else {
                // MUST. Set willQos willRetain 0
                willQos = .qos0
                willRetain = false
            }
        }
    }
    
    var cleanSession: Bool {
        get {
            return Bool(intValue: connectFlags.bitAt(1))
        }
        set {
            connectFlags.setBit(newValue.rawValue, at: 1)
        }
    }
    
    var reserved: Bool {
        get {
            return Bool(intValue: connectFlags.bitAt(0))
        }
    }
}
