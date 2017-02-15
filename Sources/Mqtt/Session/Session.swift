//
//  Session.swift
//  Mqtt
//
//  Created by HJianBo on 2017/2/14.
//
//

import Foundation
import SocksCore


protocol SessionDelegate: class {
    
    func session(_ session: Session, didConnect address: String)
    
    func session(_ session: Session, didRecvPublish packet: PublishPacket)
    
    // TODO: didSend 需要定义清楚！！！！ 消息从 socket 发送出去，还是这个消息流程完成
    //func session(_ session: Session, didSend packet: Packet)
    
    // 所有 publish 成功的消息，回调从这里走
    func session(_ session: Session, didPublish: PublishPacket)
    
    // 收到 pong 从这里走
    func session(_ session: Session, didRecvPong: PingRespPacket)
    
    // 订阅成功从这里走
    func session(_ session: Session, didSubscribe topics: [String: SubsAckReturnCode])
    
    // 取消订阅成功从这里走
    func session(_ session: Session, didUnsubscribe topics: [String])
    
    // 断开连接从这里走
    func session(_ session: Session, didDisconnect error: Error?)
}

enum SessionError: Error {
    
    case closeByRemote
    
    case recvInvaildPacket
}

// MQTT Clietn session 
// implment send/recv
final class Session {
    
    private(set) var socket: TCPInternetSocket
    
    private(set) var remoteAddres: InternetAddress

    weak private(set) var delegate: SessionDelegate?
    
    var sendQueue: DispatchQueue
    
    var messageQueue: Array<Packet>
    
    var storedPacket: Dictionary<UInt16, Packet>
    
    init?(host: String, port: UInt16, del: SessionDelegate?) {
        remoteAddres = InternetAddress(hostname: host, port: port)
        do {
            socket = try TCPInternetSocket(address: remoteAddres)
        } catch {
            return nil
        }
        
        delegate = del
        sendQueue = DispatchQueue(label: "com.mqtt.session.send")
        messageQueue = []
        storedPacket = [:]
    }
}


// MARK: - Interface
extension Session {
    
    func connect(packet: ConnectPacket) {
        // connect server
        sendQueue.async { [weak self] in
            guard let weakSelf = self else { return }
            
            do {
                try weakSelf.socket.connect()
            } catch {
                weakSelf.delegate?.session(weakSelf, didDisconnect: error)
            }
            
            // send connect packet
            weakSelf.send(packet: packet)
            
            // active recv task
            weakSelf.startRecevie()
        }
    }
    
    func send(packet: Packet) {
        let sendBlock = { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.messageQueue.append(packet)
            weakSelf.scheduleSendMessage()
        }
        
        sendQueue.async(execute: sendBlock)
    }

    private func scheduleSendMessage() {
        // TODO: exec in send queue
        guard let packet = messageQueue.first else {
            assert(false)
            return
        }
        
        // stored packet when qos > 0
        if packet.qos != .qos0 {
            storedPacket[packet.packetIdIfExisted!] = packet
        }
        
        do {
            try socket.send(data: packet.packToBytes)
            
            // remove
            messageQueue.removeFirst()
            
            // callback
            if packet.qos == .qos0 && packet is PublishPacket {
                delegate?.session(self, didPublish: packet as! PublishPacket)
            }
        } catch {
            DDLogError("send bytes error \(error)")
            DDLogVerbose("close network connection")
            
            self.close(withError: error)
        }
    }
}

// MARK: - Helper
extension Session {
    
    fileprivate func close(withError error: Error? = nil) {
        // 1. close socket
        try? socket.close()
        
        // 2. stop send/recv task
        sendQueue.suspend()
        
        // 3. save message to localstoage
        // TODO:
        
        // 4. callback did disconnect
        delegate?.session(self, didDisconnect: error)
    }
    
}

// MARK: - Recevice
extension Session {
    
    fileprivate func startRecevie() {
        // read cicrle
        DispatchQueue.global().async(execute: backgroundReciveLoop)
    }
    
    private func backgroundReciveLoop() {
        do {
            try tl_read()
        } catch {
            // occur a error, close the network connection
            // XXX: 当出现 read error 时, 是否一定关闭连接？
            DDLogError("revoke recevie loop, read error \(error)")
            delegate?.session(self, didDisconnect: error)
            return
        }
        
        backgroundReciveLoop()
    }
    
    private func didReceviePacket(header: FixedHeader, remainLen: Int, payload: [UInt8]) throws {
        // handle packet, then callback to delegate
        DDLogVerbose("RECV H: \(header), L: \(remainLen), P: \(payload)")
        
        switch header.type {
        case .connack:
            let conack = try ConnAckPacket(header: header, bytes: payload)
            DDLogInfo("RECV \(header.type), return code \(conack.returnCode)")
            
            if conack.returnCode == .accepted {
                delegate?.session(self, didConnect: "\(remoteAddres.hostname):\(remoteAddres.port)")
            } else {
                assert(false)
                self.close()
            }
            
        case .publish:
            let publish = PublishPacket(header: header, bytes: payload)
            DDLogInfo("RECV \(publish.type), topic: \(publish.topicName), payload: \(publish.payload.count) bytes")
            
            delegate?.session(self, didRecvPublish: publish)
            
            // send ack 
            switch publish.qos {
            case .qos0: break
            case .qos1:
                let puback = PubAckPacket(packetId: publish.packetId)
                self.send(packet: puback)
            case .qos2:
                let pubrec = PubRecPacket(packetId: publish.packetId)
                self.send(packet: pubrec)
            }
        case .puback:
            let puback = PubAckPacket(header: header, bytes: payload)
            DDLogInfo("RECV \(puback.type), packet id \(puback.packetId)")
            
            guard let sentPacket = storedPacket[puback.packetId] as? PublishPacket else {
                assert(false)
            }
            
            delegate?.session(self, didPublish: sentPacket)
            
            storedPacket.removeValue(forKey: puback.packetId)
            
        case .pubrec:
            let pubrec = PubRecPacket(header: header, bytes: payload)
            DDLogInfo("RECV \(pubrec.type), pakcet id \(pubrec.packetId)")
            
            guard let sentPacket = storedPacket[pubrec.packetId] as? PublishPacket else {
                DDLogError("no qos2 packet save in memeroy, when recv pubrec")
                return
            }
            
            let pubrel = PubRelPacket(packetId: pubrec.packetId)
            
            self.send(packet: pubrel)
            
            // XXX: 收到 pubrec 则告诉上层 qos2 的 publish 发送成功
            delegate?.session(self, didPublish: sentPacket)
            
            storedPacket.removeValue(forKey: pubrec.packetId)
            
        case .pubcomp:
            let pubcmp = PubCompPacket(header: header, bytes: payload)
            DDLogInfo("RECV \(pubcmp.type), packet id \(pubcmp)")
            
            // 收到 PUBCOMP 时, storedPacket, 里面应该是保存的 PUBREL
            guard let _ = storedPacket[pubcmp.packetId] as? PubRelPacket else {
                assert(false)
            }
            
        case .pubrel:
            let pubrel = try PubRelPacket(header: header, bytes: payload)
            DDLogInfo("RECV \(pubrel.type), packet id \(pubrel.packetId)")
            
            let pubcmp = PubCompPacket(packetId: pubrel.packetId)
            self.send(packet: pubcmp)
            
        case .suback:
            let suback = try SubAckPacket(header: header, bytes: payload)
            DDLogInfo("RECV \(suback.type), return codes \(suback.returnCodes)")
            
            guard let sentPacket = storedPacket[suback.packetId] as? SubscribePacket else {
                assert(false)
            }
            var result = [String: SubsAckReturnCode]()
            for i in 0 ..< sentPacket.topics.count {
                let topic = sentPacket.topics[i].0
                let retCode = suback.returnCodes[i]
                result[topic] = retCode
            }

            delegate?.session(self, didSubscribe: result)
            
            storedPacket.removeValue(forKey: sentPacket.packetId)

        case .unsuback:
            let unsuback = UnsubAckPacket(header: header, bytes: payload)
            DDLogInfo("RECV \(unsuback.type), packet id \(unsuback.packetId)")
            
            guard let sentPacket = storedPacket[unsuback.packetId] as? UnsubscribePacket else {
                assert(false)
            }
            
            delegate?.session(self, didUnsubscribe: sentPacket.topics)
            
            storedPacket.removeValue(forKey: sentPacket.packetId)
            
        case .pingresp:
            let pingresp = PingRespPacket(header: header, bytes: payload)
            DDLogInfo("RECV \(pingresp.type)")
            
        case .reserved, .reserved2:
            // should disconnect
            DDLogWarn("should close the network connect, when recv reserved header type.")
            break
        default:
            assert(false, "recv a packet type \(header.type), should be handle.")
        }
    }
    
    private func tl_read() throws {
        //assert(DispatchQueue.getSpecific(key: OP_QUEUE_SPECIFIC_KEY) == OP_QUEUE_SPECIFIC_VAL,
        //       "this method should only be run at sepcific queue")
        
        let header = try readHeader()
        let remainLength = try readLength()
        var payload: [UInt8] = []
        if remainLength != 0 {
            payload = try readPayload(len: remainLength)
        }
        
        try didReceviePacket(header: header, remainLen: remainLength, payload: payload)
    }
    
    // sync method to read a header
    private func readHeader() throws -> FixedHeader {
        //assert(DispatchQueue.getSpecific(key: OP_QUEUE_SPECIFIC_KEY) == OP_QUEUE_SPECIFIC_VAL,
        //       "this method should only be run at sepcific queue")
        
        let readLength = 1
        
        var buffer = try socket.recv(maxBytes: readLength)
        guard readLength == buffer.count else {
            throw SessionError.closeByRemote
        }
        
        guard let header = FixedHeader(byte: buffer[0]) else {
            throw SessionError.recvInvaildPacket
        }
        DDLogVerbose("did recv header \(header)")
        return header
    }
    
    // sync method to read length
    private func readLength() throws -> Int {
        //assert(DispatchQueue.getSpecific(key: OP_QUEUE_SPECIFIC_KEY) == OP_QUEUE_SPECIFIC_VAL,
        //       "this method should only be run at sepcific queue")
        
        let readLength = 1
        
        var multiply = 1
        var length = 0
        while true {
            let buffer = try socket.recv(maxBytes: readLength)
            guard readLength == buffer.count else {
                throw SessionError.closeByRemote
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
        DDLogVerbose("did recv length \(length)")
        return length
    }
    
    // read variable header and payload
    private func readPayload(len: Int) throws -> [UInt8] {
        //assert(DispatchQueue.getSpecific(key: OP_QUEUE_SPECIFIC_KEY) == OP_QUEUE_SPECIFIC_VAL,
        //       "this method should only be run at sepcific queue")
        
        guard len > 0 else {
            return []
        }
        
        let buffer = try socket.recv(maxBytes: len)
        guard buffer.count == len else {
            throw SessionError.closeByRemote
        }
        
        return buffer
    }
}
