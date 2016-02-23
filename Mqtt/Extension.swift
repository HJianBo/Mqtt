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
    func bitAt(offset: UInt8) -> UInt8 {
        return (self >> offset) & 0x01
    }
    
    mutating func setBit(value: UInt8, at offset: UInt8) {
        if (value & 0x01) == 1 {
            self |= (1 << offset)
        } else {
            self &= (~(1 << offset))
        }
    }
}


extension String {
    
    var mq_stringData: Array<UInt8> {
        let len = UInt16(lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        return len.bytes + utf8
    }
}


extension NSStreamStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        case .NotOpen:  return "NotOpen"
        case .Opening:  return "Opening"
        case .Open:     return "Open"
        case .Reading:  return "Reading"
        case .Writing:  return "Writing"
        case .AtEnd:    return "AtEnd"
        case .Closed:   return "Closed"
        case .Error:    return "Error"
        }
    }
}

extension NSStreamEvent: CustomStringConvertible {
    public var description: String {
        switch self {
        case NSStreamEvent.None:                return "None"
        case NSStreamEvent.OpenCompleted:       return "OpenComleted"
        case NSStreamEvent.HasBytesAvailable:   return "HasBytesAvailable"
        case NSStreamEvent.HasSpaceAvailable:   return "HasSpaceAvailable"
        case NSStreamEvent.ErrorOccurred:       return "ErrorOccurred"
        case NSStreamEvent.EndEncountered:      return "EndEncountered"
        default:
            assert(false, "unknown")
        }
    }
}