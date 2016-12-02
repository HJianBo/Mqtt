//
//  Reader.swift
//  Mqtt
//
//  Created by HJianBo on 2016/11/10.
//
//

import Socks
import Dispatch

private let OP_QUEUE_SPECIFIC_KEY = DispatchSpecificKey<String>()
private let OP_QUEUE_SPECIFIC_VAL = "QUEUEVAL_READER"


protocol MqttReaderDelegate {
    
    func reader(_ reader: MqttReader, didRecvConnectAck connack: ConnAckPacket)
    
}


public class MqttReader {
    
    enum ReaderError: Error {
        case invaildPacket
    }
    
    var socket: TCPClient
    
    //var opQueue: DispatchQueue
    
    var delegate: MqttReaderDelegate?
    
    init(socks: TCPClient, del: MqttReaderDelegate?) {
        socket = socks
        delegate = del
        //opQueue = DispatchQueue(label: "com.mqtt.reader")
        //opQueue.setSpecific(key: OP_QUEUE_SPECIFIC_KEY, value: OP_QUEUE_SPECIFIC_VAL)
    }
}

extension MqttReader {

    func read() throws {
        let header = try readHeader()
        let len = try readLength()
        var payload: [UInt8] = []
        if len != 0 {
            payload = try readPayload(len: len)
        }
        print(header, len, payload)
        
        switch header.type {
        case .connack:
            let conack = ConnAckPacket(header: header, bytes: payload)
            delegate?.reader(self, didRecvConnectAck: conack)
        default:
            assert(false)
        }
    }
}


// Helper
extension MqttReader {
    
    // sync method to read a header
    func readHeader() throws -> PacketFixHeader {
        
        let buffer = try socket.receive(maxBytes: 1)
        
        guard let header = PacketFixHeader(byte: buffer[0]) else {
            throw ReaderError.invaildPacket
        }
        
        return header
    }
    
    // sync method to read length
    func readLength() throws -> Int {
        var multiply = 1
        var length = 0
        
        while true {
            let buffer = try socket.receive(maxBytes: 1)[0]
            length += Int(buffer & 127) * multiply
            // done
            if buffer & 0x80 == 0 {
                break
            } else { // continue read length
                multiply *= 128
            }
        }
        
        // when length equal 0, the payload is empty
        //
        return length
    }
    
    func readPayload(len: Int) throws -> [UInt8] {
        return try socket.receive(maxBytes: len)
    }
}
