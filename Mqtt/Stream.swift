//
//  Stream.swift
//  Mqtt
//
//  Created by Heee on 16/2/23.
//  Copyright © 2016年 hjianbo. All rights reserved.
//

import Foundation


protocol StreamDelegate {
    
    func stream(stream: Stream, didSendData data: NSData)
    
    func stream(stream: Stream, didRecvData data: NSData)
    
    func stream(stream: Stream, didOpenAtHost host:String, port: UInt16)
}

struct StreamStatus: OptionSetType {
    let rawValue: UInt
    
    static let None = StreamStatus(rawValue: 0x00)
    static let InputReady = StreamStatus(rawValue: 0x01)
    static let OutputReady = StreamStatus(rawValue: 0x01 << 1)
}


class Stream: NSObject {
    
    var host: String
    
    var port: UInt16
    
    var delegate: StreamDelegate?
    
    var status: StreamStatus = .None
    
    private var inputStream: NSInputStream?
    private var outputStream: NSOutputStream?
    
    private var readQueue: dispatch_queue_t
    private var sendQueue: dispatch_queue_t
    
    
    
    init(host: String, port: UInt16) {
        self.host = host
        self.port = port
        
        readQueue = dispatch_queue_create("stream_read", DISPATCH_QUEUE_SERIAL)
        sendQueue = dispatch_queue_create("stream_send", DISPATCH_QUEUE_SERIAL)
    }
}

extension Stream: NSStreamDelegate {
    
    func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent) {
        
        var streamType = ""
        if aStream is NSInputStream {
            streamType = "Input "
        } else {
            streamType = "Output"
        }
        
        NSLog("\(streamType) | \(aStream.streamStatus) | \(eventCode)")
        if let err = aStream.streamError {
            NSLog("err: \(err)")
        }
        
        switch eventCode {
        case NSStreamEvent.None:
            break;
        case NSStreamEvent.OpenCompleted:
            if aStream is NSInputStream {
                status = status.union(.InputReady)
            } else {
                status = status.union(.OutputReady)
            }
            
            if status.isSupersetOf([.OutputReady, .InputReady]) {
                delegate?.stream(self, didOpenAtHost: host, port: port)
            }
            break;
        case NSStreamEvent.HasBytesAvailable:
            // recv
            if aStream == inputStream {
                //
            }
            break;
        case NSStreamEvent.HasSpaceAvailable:
            break;
        case NSStreamEvent.ErrorOccurred:
            break;
        case NSStreamEvent.EndEncountered:
            break;
        default:
            assert(false, "unknown")
        }
    }
}


extension Stream {
    
    func open() {
        // XXX: Host & Port invaild?
        NSStream.getStreamsToHostWithName(host, port: Int(port), inputStream: &inputStream, outputStream: &outputStream)
        
        inputStream?.delegate = self
        outputStream?.delegate = self
        
        self.inputStream?.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        self.outputStream?.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        
        self.inputStream?.open()
        self.outputStream?.open()
        // TODO: 计时, 连接超时或者失败
        // ...
    }
    
    func send(data: NSData) {
        
        guard let output = outputStream else {
            return
        }
        
        dispatch_async(sendQueue) { [unowned self] in
            while !output.hasSpaceAvailable {
                // waiting...
            }
            
            let hasWritedCount = output.write(UnsafePointer<UInt8>(data.bytes), maxLength: data.length)
            if hasWritedCount == data.length {
                self.delegate?.stream(self, didSendData: data)
            } else {
                NSLog("output stream write error")
            }
        }
    }
    
    func read(length: Int, timeOut: NSTimeInterval = 5) {
        guard let input = inputStream else {
            return
        }
        
        
//        var buffer = [UInt8](count: length, repeatedValue: 0)
//        if length > 0 {
//            let readLength = input.read(&buffer, maxLength: buffer.count)
//        }
    }
    
    func close() {
        
        self.inputStream?.close()
        self.inputStream?.removeFromRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        
        self.outputStream?.close()
        self.outputStream?.removeFromRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
    }
}

//extension Stream {
//    private func receiveDataOnStream(stream: NSStream) {
//        
//        var headerByte = [UInt8](count: 1, repeatedValue: 0)
//        guard inputStream?.read(&headerByte, maxLength: 1) > 0 else {
//            NSLog("stream: read length 0")
//            return
//        }
//        
//        guard let headerType = PacketType(rawValue: headerByte[0]) else {
//            NSLog("stream: headerTpype invaild")
//            return
//        }
//        
//        let header = PacketFixHeader(type: headerType)
//        
//        // Reading data (varheader & payload)
//        // Max Length is 2^28 = 268,435,455 (256 MB)
//        
//        var multiplier = 1
//        var value = 0
//        var encodedByte: UInt8 = 0
//        repeat {
//            var readByte = [UInt8](count: 1, repeatedValue: 0)
//            inputStream?.read(&readByte, maxLength: 1)
//            encodedByte = readByte[0]
//            value += (Int(encodedByte) & 127) * multiplier
//            multiplier *= 128
//            if multiplier > 128*128*128 {
//                return;
//            }
//        } while ((Int(encodedByte) & 128) != 0)
//        
//        let totalLength = value
//        //var responseData: NSData = NSData()
//        
//        var buffer = [UInt8](count: totalLength, repeatedValue: 0)
//        if totalLength > 0 {
//            
//            let readLength = inputStream?.read(&buffer, maxLength: buffer.count)
//            //responseData = NSData(bytes: buffer, length: readLength!)
//        }
//        
//        var packet: Packet?
//        
//        switch headerType {
//        case .RESERVED:
//            break
//        case .CONNECT:
//            // FIXME: Client doesn't recv data
//            break
//        case .CONNACK:
//            //
//            packet = ConnAckPacket(header: header, bytes: buffer)
//            
//            break
//        case .PUBLISH:
//            //
//            break
//        case .PUBACK:
//            //
//            break
//        case .PUBREC:
//            //
//            break
//        case .PUBREL:
//            //
//            break
//        case .PUBCOMP:
//            //
//            break
//        case .SUBSCRIBE:
//            //
//            break
//        case .SUBACK:
//            //
//            break
//        case .UNSUBSCRIBE:
//            //
//            break
//        case .UNSUBACK:
//            //
//            break
//        case .PINGREQ:
//            //
//            break
//        case .PINGRESP:
//            //
//            break
//        case .DISCONNECT:
//            //
//            break
//        case .RESERVED2:
//            //
//            break
//        }
//        
//        //self.delegate?.receivedData(self, data: responseData, withMQTTHeader: header)
//        //delegate?.stream(self, didRecvPacket: )
////        if let p = packet {
////            delegate?.stream(self, didRecvPacket: p)
////        }
//    }
//}