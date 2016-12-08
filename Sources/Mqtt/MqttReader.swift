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

protocol MqttReaderDelegate: class {
    
    func reader(_ reader: MqttReader, didRecvConnectAck connack: ConnAckPacket)
    
    func reader(_ reader: MqttReader, didRecvPublish publish: PublishPacket)
    
    func reader(_ reader: MqttReader, didRecvPubAck puback: PubAckPacket)
    
    func reader(_ reader: MqttReader, didRecvPubRec pubrec: PubRecPacket) throws
    
    func reader(_ reader: MqttReader, didRecvPubComp pubcomp: PubCompPacket)
    
    func reader(_ reader: MqttReader, didRecvSubAck suback: SubAckPacket)
    
    func reader(_ reader: MqttReader, didRecvUnsuback unsuback: UnsubAckPacket)
    
    func reader(_ reader: MqttReader, didRecvPingresp pingresp: PingRespPacket)
}

// TODO:
// 1. read circle
// 2. 使用 readbuffer 然后通过 buffer 来组包, 组包完成则丢在上层处理
// 3. 可以使用多线程, 和信号量的方式. 控制 每次读满 buffer 就开始等待, buffer 有空就继续读。
// 4. 读数据和组包可以分开在俩个线程进行执行, 但必须都是顺序执行才行

//


class MqttReader {
    
    enum ReaderError: Error {
        case invaildPacket
        case errorLength
    }
    
    var socket: TCPClient
    
    var semaphore: DispatchSemaphore
    
    var readQueue: DispatchQueue
    
    weak var delegate: MqttReaderDelegate?
    
    init(socks: TCPClient, del: MqttReaderDelegate?) {
        socket = socks
        delegate = del
        readQueue = DispatchQueue(label: "com.mqtt.reader", qos: .background)
        readQueue.setSpecific(key: OP_QUEUE_SPECIFIC_KEY, value: OP_QUEUE_SPECIFIC_VAL)
        semaphore = DispatchSemaphore(value: 1)
        
        // read cicrle
        readQueue.async { [unowned self] in
            while true {
                self.semaphore.wait()
                try? self.tl_read()
                self.semaphore.signal()
            }
        }
    }
}


// MARK: Helper
extension MqttReader {

    fileprivate func tl_read() throws {
        assert(DispatchQueue.getSpecific(key: OP_QUEUE_SPECIFIC_KEY) == OP_QUEUE_SPECIFIC_VAL,
               "this method should only be run at sepcific queue")
        
        let header = try readHeader()
        let remainLength = try readLength()
        var payload: [UInt8] = []
        if remainLength != 0 {
            payload = try readPayload(len: remainLength)
        }
        
        switch header.type {
        case .connack:
            let conack = ConnAckPacket(header: header, bytes: payload)
            delegate?.reader(self, didRecvConnectAck: conack)
        case .publish:
            let publish = PublishPacket(header: header, bytes: payload)
            delegate?.reader(self, didRecvPublish: publish)
        case .puback:
            let puback = PubAckPacket(header: header, bytes: payload)
            delegate?.reader(self, didRecvPubAck: puback)
        case .pubrec:
            let pubrec = PubRecPacket(header: header, bytes: payload)
            try delegate?.reader(self, didRecvPubRec: pubrec)
        case .pubcomp:
            let pubcmp = PubCompPacket(header: header, bytes: payload)
            delegate?.reader(self, didRecvPubComp: pubcmp)
        case .suback:
            let suback = SubAckPacket(header: header, bytes: payload)
            delegate?.reader(self, didRecvSubAck: suback)
        case .unsuback:
            let unsuback = UnsubAckPacket(header: header, bytes: payload)
            delegate?.reader(self, didRecvUnsuback: unsuback)
        case .pingresp:
            let pingresp = PingRespPacket(header: header, bytes: payload)
            delegate?.reader(self, didRecvPingresp: pingresp)
        case .reserved, .reserved2:
            // should disconnect 
            DDLogWarn("should close the network connect, when recv reserved header type.")
            break
        default:
            assert(false, "recv a packet type \(header.type), should be handle.")
        }
    }
    
    // sync method to read a header
    private func readHeader() throws -> FixedHeader {
        assert(DispatchQueue.getSpecific(key: OP_QUEUE_SPECIFIC_KEY) == OP_QUEUE_SPECIFIC_VAL,
               "this method should only be run at sepcific queue")
        
        let readLength = 1
        
        var buffer = try socket.receive(maxBytes: readLength)
        guard readLength == buffer.count else {
            throw ReaderError.errorLength
        }
        
        guard let header = FixedHeader(byte: buffer[0]) else {
            throw ReaderError.invaildPacket
        }
        
        return header
    }
    
    // sync method to read length
    private func readLength() throws -> Int {
        assert(DispatchQueue.getSpecific(key: OP_QUEUE_SPECIFIC_KEY) == OP_QUEUE_SPECIFIC_VAL,
               "this method should only be run at sepcific queue")
        
        let readLength = 1
        
        var multiply = 1
        var length = 0
        while true {
            let buffer = try socket.receive(maxBytes: readLength)
            guard readLength == buffer.count else {
                throw ReaderError.errorLength
            }
            let byte = buffer[0]
            length += Int(byte & 127) * multiply
            // done
            if byte & 0x80 == 0 {
                break
            } else { // continue read length
                multiply *= 128
            }
        }
        
        // when length equal 0, the payload is empty
        //
        return length
    }
    
    // read variable header and payload
    private func readPayload(len: Int) throws -> [UInt8] {
        assert(DispatchQueue.getSpecific(key: OP_QUEUE_SPECIFIC_KEY) == OP_QUEUE_SPECIFIC_VAL,
               "this method should only be run at sepcific queue")
        
        guard len > 0 else {
            return []
        }
        
        let buffer = try socket.receive(maxBytes: len)
        guard buffer.count == len else {
            throw ReaderError.errorLength
        }
        
        return buffer
    }
}
