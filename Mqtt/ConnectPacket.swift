//
//  MqttConnectPacket.swift
//  Mqtt
//
//  Created by Heee on 16/2/1.
//  Copyright © 2016年 jianbo. All rights reserved.
//

import Foundation

let DefaultProtocolName  = "MQTT"
let DefaultProtocolLevel = UInt8(4)
let DefaultKeepAlive     = UInt16(60)


struct ConnectPacket: Packet {
    
    var fixHeader: PacketFixHeader
    
    // MARK: Variable Header Members
    
    var protocolName = DefaultProtocolName
    
    var protocolLevel: UInt8 = DefaultProtocolLevel
    
    var connectFlags: UInt8  = 0
    
    var keepAlive: UInt16    = DefaultKeepAlive
    
    ///
    var varHeader: Array<UInt8> {
        get {
            var value = Array<UInt8>()
            value.appendContentsOf(protocolName.mq_stringData)
            value.append(protocolLevel)
            value.append(connectFlags)
            value.appendContentsOf(keepAlive.bytes)
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
            
            value.appendContentsOf(clientId.mq_stringData)
            
            if (willFlag) {
                if let topic = willTopic {
                    value.appendContentsOf(topic.mq_stringData)
                } else {
                    value.appendContentsOf("".mq_stringData)
                }
                
                if let message = willMessage {
                    value.appendContentsOf(message.mq_stringData)
                } else {
                    value.appendContentsOf("".mq_stringData)
                }
            }
            
            if userNameFlag {
                if let uname = userName {
                    value.appendContentsOf(uname.mq_stringData)
                } else {
                    value.appendContentsOf("".mq_stringData)
                }
            }
            
            if passwordFlag {
                if let pwd = password {
                    value.appendContentsOf(pwd.mq_stringData)
                } else {
                    value.appendContentsOf("".mq_stringData)
                }
            }
            
            return value
        }
    }
    
    init(clientId id: String) {
        clientId = id
        fixHeader = PacketFixHeader(type: .CONNECT)
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
            case .Qos0:
                connectFlags.setBit(0, at: 4)
                connectFlags.setBit(0, at: 3)
                break
            case .Qos1:
                connectFlags.setBit(0, at: 4)
                connectFlags.setBit(1, at: 3)
                break
            case .Qos2:
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
                willQos = .Qos1
            } else {
                // MUST. Set willQos willRetain 0
                willQos = .Qos0
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