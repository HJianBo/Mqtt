//
//  DisconnectPacket.swift
//  Mqtt
//
//  Created by Heee on 16/2/3.
//  Copyright © 2016年 hjianbo.me. All rights reserved.
//

import Foundation

struct DisconnectPacket: Packet {
    
    var fixHeader: PacketFixHeader
    
    var varHeader = [UInt8]()
    
    var payload   = [UInt8]()
    
    init() {
        fixHeader = PacketFixHeader(type: .disconnect)
    }
}
