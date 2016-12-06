//
//  DisconnectPacket.swift
//  Mqtt
//
//  Created by Heee on 16/2/3.
//  Copyright © 2016年 hjianbo.me. All rights reserved.
//

import Foundation

/**
 The DISCONNECT Packet is the final Control Packet sent from the Client to the Server. It indicates that
 1140 the Client is disconnecting cleanly.
 
 */
struct DisconnectPacket: Packet {
    
    var fixedHeader: FixedHeader
    
    var varHeader = [UInt8]()
    
    var payload   = [UInt8]()
    
    init() {
        fixedHeader = FixedHeader(type: .disconnect)
    }
}
