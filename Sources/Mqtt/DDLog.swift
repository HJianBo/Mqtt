//
//  DDLog.swift
//  Mqtt
//
//  Created by HJianBo on 2016/12/2.
//
//

import Foundation

public enum ETLogLevel: UInt8 {
    
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

var logLevel: ETLogLevel  = .verbose

func DDLogVerbose(_ format: CustomStringConvertible) {
    if logLevel >= .verbose {
        print("[Verbs]: \(format)")
    }
}

func DDLogInfo(_ format: CustomStringConvertible) {
    if logLevel >= .info {
        print("[Info ]: \(format)")
    }
}

func DDLogDebug(_ format: CustomStringConvertible) {
    if logLevel >= .debug {
        print("[Debug]: \(format)")
    }
}

func DDLogWarn(_ format: CustomStringConvertible) {
    if logLevel >= .warning {
        print("[Warn ]: \(format)")
    }
}

func DDLogError(_ format: CustomStringConvertible) {
    if logLevel >= .error {
        print("[Error]: \(format)")
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
