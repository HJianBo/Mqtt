//
//  DDLog.swift
//  Mqtt
//
//  Created by HJianBo on 2016/12/2.
//
//

import Foundation

@objc public enum ETLogLevel: UInt8 {
    
    /// 不显示日志
    case off  = 0
    
    /// 显示 错误 日志
    case error
    
    /// 显示 错误|警告 日志
    case warning
    
    /// 显示 错误|警告|调试 日志
    case debug
    
    /// 显示 错误|警告|调试|信息 日志
    case info
    
    /// 显示 错误|警告|调试|信息|冗余 日志
    case verbose
}

var logLevel: ETLogLevel  = .info

func DDLogVerbose(_ format: String) {
    if logLevel >= .verbose {
        NSLog("[Verbs]: \(format)")
    }
}

func DDLogInfo(_ format: String) {
    if logLevel >= .info {
        NSLog("[Info ]: \(format)")
    }
}

func DDLogDebug(_ format: String) {
    if logLevel >= .debug {
        NSLog("[Debug]: \(format)")
    }
}

func DDLogWarn(_ format: String) {
    if logLevel >= .warning {
        NSLog("[Warn ]: \(format)")
    }
}

func DDLogError(_ format: String) {
    if logLevel >= .error {
        NSLog("[Error]: \(format)")
    }
}

//////////// Comparable

extension ETLogLevel: Comparable {
}

extension ETLogLevel: Equatable {
}

public func <(lhs: ETLogLevel, rhs: ETLogLevel) -> Bool {
    return lhs.rawValue < rhs.rawValue
}

public func <=(lhs: ETLogLevel, rhs: ETLogLevel) -> Bool {
    return lhs.rawValue <= rhs.rawValue
}

public func >=(lhs: ETLogLevel, rhs: ETLogLevel) -> Bool {
    return lhs.rawValue >= rhs.rawValue
}

public func >(lhs: ETLogLevel, rhs: ETLogLevel) -> Bool {
    return lhs.rawValue > rhs.rawValue
}
public func ==(lhs: ETLogLevel, rhs: ETLogLevel) -> Bool {
    return lhs.rawValue == rhs.rawValue
}
