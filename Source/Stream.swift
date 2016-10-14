//
//  Stream.swift
//  Mqtt
//
//  Created by Heee on 16/2/23.
//  Copyright © 2016年 hjianbo. All rights reserved.
//

import Foundation


protocol StreamDelegate {
    
    func stream(_ stream: Stream, didSendData data: Data, flag: String)
    
    func stream(_ stream: Stream, didRecvData data: Data, flag: String)
    
    func stream(_ stream: Stream, didOpenAtHost host:String, port: UInt16)
}

struct StreamStatus: OptionSet {
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
    
    fileprivate var inputStream: InputStream?
    fileprivate var outputStream: OutputStream?
    
    fileprivate var readQueue: DispatchQueue
    fileprivate var sendQueue: DispatchQueue
    
    
    
    init(host: String, port: UInt16) {
        self.host = host
        self.port = port
        
        readQueue = DispatchQueue(label: "stream_read", attributes: [])
        sendQueue = DispatchQueue(label: "stream_send", attributes: [])
    }
}

extension Stream: Foundation.StreamDelegate {
    
    func stream(_ aStream: Foundation.Stream, handle eventCode: Foundation.Stream.Event) {
        
        var streamType = ""
        if aStream is InputStream {
            streamType = "Input "
        } else {
            streamType = "Output"
        }
        
        NSLog("\(streamType) | \(aStream.streamStatus) | \(eventCode)")
        if let err = aStream.streamError {
            NSLog("err: \(err)")
        }
        
        switch eventCode {
        case Foundation.Stream.Event():
            break;
        case Foundation.Stream.Event.openCompleted:
            if aStream is InputStream {
                status = status.union(.InputReady)
            } else {
                status = status.union(.OutputReady)
            }
            
            if status.isSuperset(of: [.OutputReady, .InputReady]) {
                delegate?.stream(self, didOpenAtHost: host, port: port)
            }
            break;
        case Foundation.Stream.Event.hasBytesAvailable:
            // recv
            if aStream == inputStream {
                //
            }
            break;
        case Foundation.Stream.Event.hasSpaceAvailable:
            break;
        case Foundation.Stream.Event.errorOccurred:
            break;
        case Foundation.Stream.Event.endEncountered:
            break;
        default:
            assert(false, "unknown")
        }
    }
}


extension Stream {
    
    func open() {
        // XXX: Host & Port invaild?
        Foundation.Stream.getStreamsToHost(withName: host, port: Int(port), inputStream: &inputStream, outputStream: &outputStream)
        
        inputStream?.delegate = self
        outputStream?.delegate = self
        
        self.inputStream?.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
        self.outputStream?.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
        
        self.inputStream?.open()
        self.outputStream?.open()
        // TODO: 计时, 连接超时或者失败
        // ...
    }
    
    func send(_ data: Data, flag: String = "") {
        
        guard let output = outputStream else {
            return
        }
        
        sendQueue.async { [unowned self] in
            while !output.hasSpaceAvailable {
                // waiting...
            }
            
            let hasWritedCount = output.write((data as NSData).bytes.bindMemory(to: UInt8.self, capacity: data.count), maxLength: data.count)
            if hasWritedCount == data.count {
                self.delegate?.stream(self, didSendData: data, flag: flag)
            } else {
                NSLog("output stream write error")
            }
        }
    }
    
    func read(_ length: Int, timeOut: TimeInterval = 5, flag: String = "") {
        guard let input = inputStream else {
            return
        }
        
        var buffer = [UInt8](repeating: 0, count: length)
        if length > 0 {
            readQueue.async { [unowned self] in
                let readLen = input.read(&buffer, maxLength: buffer.count)
                if readLen != length {
                    NSLog("----- read length not equal!")
                }
                self.delegate?.stream(self, didRecvData: Data(bytes: buffer), flag: flag)
            }
        }
    }
    
    func close() {
        
        self.inputStream?.close()
        self.inputStream?.remove(from: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
        
        self.outputStream?.close()
        self.outputStream?.remove(from: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
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
