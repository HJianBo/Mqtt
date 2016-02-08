//
//  MqttStream.swift
//  Mqtt
//
//  Created by Heee on 16/2/8.
//  Copyright © 2016年 beidouapp. All rights reserved.
//

import Foundation

class MqttStream: NSObject {
    
    var host: String
    
    var port: UInt16
    
    private var inputStream: NSInputStream?
    
    private var outputStream: NSOutputStream?
    
    init(host: String, port: UInt16) {
        self.host = host
        self.port = port
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
        
        inputStream?.open()
        outputStream?.open()
    }
    
    func send(data: Packet) -> Int {
        let bytes = data.packToBytes
        if let actually = outputStream?.write(bytes, maxLength: bytes.count) {
            return actually
        }
        
        return -1
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
        NSLog("\(__FUNCTION__): \(aStream), \(eventCode)")
    
        switch eventCode {
        case NSStreamEvent.None:
            break;
        case NSStreamEvent.OpenCompleted:
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
        let len = inputStream?.read(&headerByte, maxLength: 1)
        if !(len > 0) { return; }
        let header = PacketFixHeader(type: PacketType(rawValue: headerByte[0])!) //MQTTPacketFixedHeader(networkByte: headerByte[0])
        
        ///Max Length is 2^28 = 268,435,455 (256 MB)
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
        
        var responseData: NSData = NSData()
        if totalLength > 0 {
            var buffer = [UInt8](count: totalLength, repeatedValue: 0)
            let readLength = inputStream?.read(&buffer, maxLength: buffer.count)
            responseData = NSData(bytes: buffer, length: readLength!)
        }
        //self.delegate?.receivedData(self, data: responseData, withMQTTHeader: header)
    }
}


