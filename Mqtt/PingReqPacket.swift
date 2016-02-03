//
//  PingReqPacket.swift
//  Mqtt
//
//  Created by Heee on 16/2/3.
//  Copyright © 2016年 beidouapp. All rights reserved.
//

import Foundation

struct PingReqPacket: Packet {
    
    var fixHeader: PacketFixHeader
    
    var varHeader = [UInt8]()
    
    var payload   = [UInt8]()
    
    init() {
        fixHeader = PacketFixHeader(type: .PINGREQ)
    }
}