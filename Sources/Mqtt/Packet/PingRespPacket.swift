//
//  PingRespPacket.swift
//  Mqtt
//
//  Created by Heee on 16/2/3.
//  Copyright © 2016年 hjianbo.me. All rights reserved.
//

import Foundation

struct PingRespPacket: Packet {
    
    var fixedHeader: FixedHeader
    
    var varHeader = [UInt8]()
    
    var payload   = [UInt8]()
    
    init() {
        fixedHeader = FixedHeader(type: .pingresp)
    }
}
