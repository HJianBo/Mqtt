//
//  Extension.swift
//  Mqtt
//
//  Created by Heee on 16/1/29.
//  Copyright © 2016年 jianbo. All rights reserved.
//

import Foundation

extension Bool {
    
    init(intValue: UInt8) {
        self = false
        if intValue > 0 {
            self = true
        }
    }
    
    var rawValue: UInt8 {
        if self {
            return 1
        }
        return 0
    }
}

extension UInt16 {
    
    var lbyte: UInt8 {
        return UInt8(Int(self) & 0x00FF)
    }
    
    var hbyte: UInt8 {
        return UInt8((Int(self) >> 8))
    }
    
    var bytes: Array<UInt8> {
        return [hbyte] + [lbyte]
    }
}


// TODO: Rename?

extension UInt8 {
    
    /// offset: 7~0
    func bitAt(_ offset: UInt8) -> UInt8 {
        return (self >> offset) & 0x01
    }
    
    mutating func setBit(_ value: UInt8, at offset: UInt8) {
        if (value & 0x01) == 1 {
            self |= (1 << offset)
        } else {
            self &= (~(1 << offset))
        }
    }
}


extension String {
    
    var mq_stringData: Array<UInt8> {
        let len = UInt16(lengthOfBytes(using: String.Encoding.utf8))
        return len.bytes + utf8
    }
}

