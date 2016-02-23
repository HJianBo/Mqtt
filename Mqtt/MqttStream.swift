//
//  MqttStream.swift
//  Mqtt
//
//  Created by Heee on 16/2/8.
//  Copyright © 2016年 beidouapp. All rights reserved.
//

import Foundation

protocol MqttStreamDelegate {

    func stream(stream: MqttStream, didSendPacket packet: Packet)
    
    func stream(stream: MqttStream, didRecvPacket packet: Packet)
    
    func stream(stream: MqttStream, didConnectHost host:String, port: UInt16)
}

class MqttStream: NSObject {
    
    var host: String
    
    var port: UInt16
    
    var delegate: MqttStreamDelegate?
    
    var inputQueue: dispatch_queue_t?
    private var inputStream: NSInputStream?
    
    var outputQueue: dispatch_queue_t?
    private var outputStream: NSOutputStream?
    
    init(host: String, port: UInt16) {
        self.host = host
        self.port = port
        
        let opQueue = NSOperationQueue()
        opQueue.maxConcurrentOperationCount = 1
        
    }
}


extension MqttStream {

    func connect() {
        // XXX: Host & Port invaild?
        NSStream.getStreamsToHostWithName(host, port: Int(port), inputStream: &inputStream, outputStream: &outputStream)
        
        // XXX: inputStream & outputStream open success ?
        
        inputStream?.delegate = self
        outputStream?.delegate = self
        
        inputStream?.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        outputStream?.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        
        // FIXME: Open err ? time out ??
        inputStream?.open()
        outputStream?.open()
        
    }
    
    func send(data: Packet) -> Int {
        guard let output = outputStream else {
            return -1
        }
        
        guard output.hasSpaceAvailable else {
            NSLog("outputStream not ready")
            return -1
        }
        
        let bytes = data.packToBytes
        let actually = output.write(bytes, maxLength: bytes.count)
        
        return actually
    }
    
    func close() {
        inputStream?.close()
        inputStream?.removeFromRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        
        outputStream?.close()
        outputStream?.removeFromRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
    }
}

extension MqttStream: NSStreamDelegate {
    
    func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent) {

        var streamType = ""
        if aStream is NSInputStream {
            streamType = "Input"
        } else {
            streamType = "Output"
        }
        
        NSLog("\(streamType) | \(aStream.streamStatus) | \(eventCode)")
        
        
        switch eventCode {
        case NSStreamEvent.None:
            break;
        case NSStreamEvent.OpenCompleted:
            delegate?.stream(self, didConnectHost: host, port: port)
            break;
        case NSStreamEvent.HasBytesAvailable:
            // recv
            if aStream == inputStream {
                // 
                receiveDataOnStream(aStream)
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
    
    private func receiveDataOnStream(stream: NSStream) {
        
        var headerByte = [UInt8](count: 1, repeatedValue: 0)
        guard inputStream?.read(&headerByte, maxLength: 1) <= 0 else {
            NSLog("stream: read length 0")
            return
        }
        
        guard let headerType = PacketType(rawValue: headerByte[0]) else {
            NSLog("stream: headerTpype invaild")
            return
        }
        
        let header = PacketFixHeader(type: headerType)
        
        // Reading data (varheader & payload)
        // Max Length is 2^28 = 268,435,455 (256 MB)
        
        var multiplier = 1
        var value = 0
        var encodedByte: UInt8 = 0
        repeat {
            var readByte = [UInt8](count: 1, repeatedValue: 0)
            inputStream?.read(&readByte, maxLength: 1)
            encodedByte = readByte[0]
            value += (Int(encodedByte) & 127) * multiplier
            multiplier *= 128
            if multiplier > 128*128*128 {
                return;
            }
        } while ((Int(encodedByte) & 128) != 0)
        
        let totalLength = value
        //var responseData: NSData = NSData()
        
        var buffer = [UInt8](count: totalLength, repeatedValue: 0)
        if totalLength > 0 {
            
            let readLength = inputStream?.read(&buffer, maxLength: buffer.count)
            //responseData = NSData(bytes: buffer, length: readLength!)
        }
        
        var packet: Packet?
        
        switch headerType {
        case .RESERVED:
            break
        case .CONNECT:
            // FIXME: Client doesn't recv data
            break
        case .CONNACK:
            //
            packet = ConnAckPacket(header: header, bytes: buffer)
            
            break
        case .PUBLISH:
            //
            break
        case .PUBACK:
            //
            break
        case .PUBREC:
            //
            break
        case .PUBREL:
            //
            break
        case .PUBCOMP:
            //
            break
        case .SUBSCRIBE:
            //
            break
        case .SUBACK:
            //
            break
        case .UNSUBSCRIBE:
            //
            break
        case .UNSUBACK:
            //
            break
        case .PINGREQ:
            //
            break
        case .PINGRESP:
            //
            break
        case .DISCONNECT:
            //
            break
        case .RESERVED2:
            //
            break
        }
        
        //self.delegate?.receivedData(self, data: responseData, withMQTTHeader: header)
        //delegate?.stream(self, didRecvPacket: )
        if let p = packet {
            delegate?.stream(self, didRecvPacket: p)
        }
    }
}


