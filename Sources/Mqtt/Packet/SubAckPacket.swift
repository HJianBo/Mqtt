//
//  SubackPacket.swift
//  Mqtt
//
//  Created by Heee on 16/2/3.
//  Copyright © 2016年 hjianbo.me. All rights reserved.
//

import Foundation

public enum SubsAckReturnCode: UInt8 {
    
    case maxQos0 = 0x00
    
    case maxQos1 = 0x01
    
    case maxQos2 = 0x02
    
    case failure = 0x80
}

/**
 A SUBACK Packet is sent by the Server to the Client to confirm receipt and processing of a SUBSCRIBE
 Packet.
 
 A SUBACK Packet contains a list of return codes, that specify the maximum QoS level that was granted
 in each Subscription that was requested by the SUBSCRIBE.
 
 **Fixed Header:**
  1. type: subsack(1001)
  2. flag: reserved(0000)
 
 **Variable Header:**
 The variable header contains the Packet Identifier from the SUBSCRIBE Packet that is being acknowledged
 
 **Payload:**
 The payload contains a list of return codes. Each return code corresponds to a Topic Filter in the
 SUBSCRIBE Packet being acknowledged.
 
 The order of return codes in the SUBACK Packet MUST match the order of Topic Filters in the SUBSCRIBE
 Packet
 
 */
struct SubAckPacket: Packet {
    
    var fixedHeader: FixedHeader
    
    // MARK: Varibale Header
    var packetId: UInt16

    var varHeader: Array<UInt8> {
        return packetId.bytes
    }
    
    // MARK: Payload
    
    var returnCodes: Array<SubsAckReturnCode>
    
    var payload: Array<UInt8> {
        return returnCodes.map { $0.rawValue }
    }
    
    init(packetId: UInt16) {
        fixedHeader = FixedHeader(type: .suback)
        self.packetId = packetId
        
        returnCodes = []
    }
}

extension SubAckPacket: InitializeWithResponse {
    
    init(header: FixedHeader, bytes: [UInt8]) throws {
        guard header.type == .suback else {
            throw PacketError.typeIllegal
        }
        
        guard bytes.count >= 2 else {
            throw PacketError.byteContentIllegal
        }
        
        fixedHeader = header
        packetId = UInt16(bytes[0])*256+UInt16(bytes[1])
        
        // XXX: endindex????
        returnCodes = bytes[2..<bytes.endIndex].map {
            guard let returnCode = SubsAckReturnCode(rawValue: $0) else {
                return .failure
            }
            return returnCode
        }
    }
}

extension SubAckPacket {
    public var description: String {
        return "SubAck(packetId: \(packetId))"
    }
}
