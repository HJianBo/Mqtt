//
//  Session.swift
//  Mqtt
//
//  Created by HJianBo on 2017/2/14.
//
//

import Foundation
import SocksCore

/// client session state
public enum SessionState: Int {
    
    /// connack not equal .accept
    case denied = -1
    
    /// executed disconnect success, session end
    case disconnected
    
    /// executing connect method, waiting connack packet
    case connecting
    
    /// receive .accept of connack
    case accepted
}

protocol SessionDelegate: class {
    
    func session(_ session: Session, didConnect address: String)
    
    func session(_ session: Session, didRecvPublish packet: PublishPacket)
    
    func session(_ session: Session, didPublish publish: PublishPacket)
    
    func session(_ session: Session, didRecvPong pingresp: PingRespPacket)
    
    func session(_ session: Session, didSubscribe topics: [String: SubsAckReturnCode])
    
    func session(_ session: Session, didUnsubscribe topics: [String])
    
    func session(_ session: Session, didDisconnect error: Error?)
}

enum SessionError: Error {
    
    case socketIsNil
    
    case closeByServer
    
    case invaildPacket

}

// Queue specifi key/value
private struct QueueSpecifi {
    
    static let SendKey = DispatchSpecificKey<String>()
    
    static let SendValue = "SEND_QUEUE_SPECIFI_VALUE"
    
    static let ReadKey = DispatchSpecificKey<String>()
    
    static let ReadValue = "READ_QUEUE_SPECIFI_VALUE"
}

// MQTT Clietn session 
// implment send/recv
final class Session {
    
    fileprivate var socket: TCPInternetSocket?
    
    fileprivate(set) var state: SessionState {
        didSet {
            DDLogInfo("mqtt client session state did change to [\(state)]")
        }
    }
    
    private(set) var remoteAddres: InternetAddress

    weak fileprivate var delegate: SessionDelegate?
    
    var sendQueueGroup: DispatchGroup
    
    // send message & modify variabel property in this queue
    var sendQueue: DispatchQueue
    
    // read cicrle
    var readQueue: DispatchQueue
    
    var messageQueue: Array<Packet>
    
    var storedPacket: Dictionary<UInt16, Packet>
    
    var connectPacket: ConnectPacket?
    
    var heartbeatTimer: Timer?
    
    init(host: String, port: UInt16, del: SessionDelegate?) {
        remoteAddres = InternetAddress(hostname: host, port: port)
        
        delegate = del
        sendQueue = DispatchQueue(label: "com.mqtt.session.send")
        readQueue = DispatchQueue(label: "com.mqtt.session.read")
        sendQueueGroup = DispatchGroup()
        messageQueue = []
        storedPacket = [:]
        
        state = .disconnected
        
        sendQueue.setSpecific(key: QueueSpecifi.SendKey, value: QueueSpecifi.SendValue)
        readQueue.setSpecific(key: QueueSpecifi.ReadKey, value: QueueSpecifi.ReadValue)
    }
    
    deinit {
        DDLogInfo("session deinit")
    }
}


// MARK: - Interface
extension Session {
    
    func connect(packet: ConnectPacket) {
        // connect server & send `ConnectPacket`
        let connectBlock = { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.state = .connecting
            weakSelf.connectPacket = packet
            do {
                weakSelf.socket = try TCPInternetSocket(address: weakSelf.remoteAddres)
                try weakSelf.socket!.connect()
            } catch {
                DDLogError("socket connect error \(error)")
                weakSelf.close(withError: error)
            }
            
            // send connect packet
            weakSelf.messageQueue.append(packet)
            weakSelf.scheduleSendMessage()
            
            // active recv task
            weakSelf.startRecevie()
        }
        
        // exec block in `sendQueue`
        sendQueueGroup.notify(queue: sendQueue, execute: connectBlock)
    }
    
    func send(packet: Packet) {
        
        // append packet to `messageQueue` & schedule send task
        let sendBlock = { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.messageQueue.append(packet)
            weakSelf.scheduleSendMessage()
        }
        
        // exec block in `sendQueue`
        sendQueueGroup.notify(queue: sendQueue, execute: sendBlock)
    }

    private func scheduleSendMessage() {
        assert(DispatchQueue.getSpecific(key: QueueSpecifi.SendKey) == QueueSpecifi.SendValue,
               "this method should only be run at sepcific queue")
        
        guard let packet = messageQueue.first else {
            assert(false)
            return
        }
        
        guard let socket = socket else {
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
            
            // close connection, when sent DisconnectPacket
            if packet is DisconnectPacket {
                self.close(withError: nil)
            }
        } catch {
            DDLogError("send bytes error \(error)")
            DDLogVerbose("close network connection")
            
            self.close(withError: error)
        }
    }
}

extension Session  {
    
    fileprivate func startHeartbeatTimer() {
        guard state == .accepted else { return }
        guard let keepAlive = connectPacket?.keepAlive else { return }
        
        if heartbeatTimer != nil {
            heartbeatTimer?.invalidate()
            heartbeatTimer = nil
        }
        
        heartbeatTimer = Timer(timeInterval: Double(keepAlive),
                               target: self,
                               selector: #selector(_heartbeatTimerArrive),
                               userInfo: nil,
                               repeats: true)
        
        // XXX: 心跳线程是否应放到 sendQueue 当中
        RunLoop.main.add(heartbeatTimer!, forMode: .commonModes)
    }
    
    fileprivate func stopHeartbeatTimer() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }
    
    @objc private func _heartbeatTimerArrive() {
        let ping = PingReqPacket()
        send(packet: ping)
    }
}

// MARK: - Helper
extension Session {
    
    fileprivate func close(withError error: Error? = nil) {
        
        // close socket & stop send/recv task
        let disconnectBlock = { [weak self] in
            guard let weakSelf = self else { return }
        
            guard weakSelf.state != .disconnected else { return }
            
            weakSelf.state = .disconnected
            
            // 1. stop send/recv task
            weakSelf.stopHeartbeatTimer()
            
            // 2. close socket
            try? weakSelf.socket?.close()
            
            // 3. save message to localstoage
            
            // 4. callback did disconnect
            weakSelf.delegate?.session(weakSelf, didDisconnect: error)
        }
        
        // exec disconnect bolck in sendQueue
        sendQueue.async(execute: disconnectBlock)
    }
}

// MARK: - Recevice
extension Session {
    
    fileprivate func startRecevie() {
        // read cicrle
        readQueue.async(execute: backgroundReciveLoop)
    }
    
    private func backgroundReciveLoop() {
        do {
            try tl_read()
            backgroundReciveLoop()
        } catch {
            // occur a error, close the network connection
            DDLogError("revoke recevie loop, read error \(error)")
            self.close(withError: error)
            return
        }
    }
    
    private func handleRecvMessage(header: FixedHeader, remainLen: Int, payload: [UInt8]) throws {
        DDLogVerbose("RECV H: \(header), L: \(remainLen), P: \(payload)")
        
        switch header.type {
        case .connack:
            let conack = try ConnAckPacket(header: header, bytes: payload)
            DDLogInfo("RECV \(header.type), return code \(conack.returnCode)")
            
            if conack.returnCode == .accepted {
                sendQueue.async { [weak self] in
                    self?.state = .accepted
                    self?.startHeartbeatTimer()
                }
                delegate?.session(self, didConnect: "\(remoteAddres.hostname):\(remoteAddres.port)")
            } else {
                sendQueue.async { [weak self] in
                    self?.state = .denied
                }
                // FIXME: need report error
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
                DDLogError("no qos2 packet saved in the cache, when recv pubrec")
                return
            }
            
            let pubrel = PubRelPacket(packetId: pubrec.packetId)
            
            // remove publish packet from cahce.
            storedPacket.removeValue(forKey: pubrec.packetId)
            
            // send & save rel in cahce.
            self.send(packet: pubrel)
            
            // XXX: 收到 pubrec 则告诉上层 qos2 的 publish 发送成功
            delegate?.session(self, didPublish: sentPacket)
            
        case .pubcomp:
            let pubcmp = PubCompPacket(header: header, bytes: payload)
            DDLogInfo("RECV \(pubcmp.type), packet id \(pubcmp)")
            
            // 收到 PUBCOMP 时, storedPacket, 里面应该是保存的 PUBREL
            guard let _ = storedPacket[pubcmp.packetId] as? PubRelPacket else {
                DDLogError("no pubrel saved in the cahce, when recv pubcmp")
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
            
            delegate?.session(self, didRecvPong: pingresp)
        case .reserved, .reserved2:
            // should disconnect
            DDLogError("close the network connect, when recv reserved header type.")
            self.close(withError: SessionError.invaildPacket)
            break
        default:
            assert(false, "recv a packet type \(header.type), should be handle.")
        }
    }
    
    private func tl_read() throws {
        assert(DispatchQueue.getSpecific(key: QueueSpecifi.ReadKey) == QueueSpecifi.ReadValue,
               "this method should only be run at sepcific queue")
        
        let header = try readHeader()
        let remainLength = try readLength()
        var payload: [UInt8] = []
        if remainLength != 0 {
            payload = try readPayload(len: remainLength)
        }
        
        try handleRecvMessage(header: header, remainLen: remainLength, payload: payload)
    }
    
    // sync method to read a header
    private func readHeader() throws -> FixedHeader {
        assert(DispatchQueue.getSpecific(key: QueueSpecifi.ReadKey) == QueueSpecifi.ReadValue,
               "this method should only be run at sepcific queue")
        
        guard let socket = socket else {
            throw SessionError.socketIsNil
        }
        
        let readLength = 1
        
        var buffer = try socket.recv(maxBytes: readLength)
        guard readLength == buffer.count else {
            throw SessionError.closeByServer
        }
        
        guard let header = FixedHeader(byte: buffer[0]) else {
            throw SessionError.invaildPacket
        }
        
        return header
    }
    
    // sync method to read length
    private func readLength() throws -> Int {
        assert(DispatchQueue.getSpecific(key: QueueSpecifi.ReadKey) == QueueSpecifi.ReadValue,
               "this method should only be run at sepcific queue")
        
        guard let socket = socket else {
            throw SessionError.socketIsNil
        }
        
        let readLength = 1
        
        var multiply = 1
        var length = 0
        while true {
            let buffer = try socket.recv(maxBytes: readLength)
            guard readLength == buffer.count else {
                throw SessionError.closeByServer
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
        
        return length
    }
    
    // read variable header and payload
    private func readPayload(len: Int) throws -> [UInt8] {
        assert(DispatchQueue.getSpecific(key: QueueSpecifi.ReadKey) == QueueSpecifi.ReadValue,
               "this method should only be run at sepcific queue")
        
        guard let socket = socket else {
            throw SessionError.socketIsNil
        }
        
        guard len > 0 else {
            return []
        }
        
        let buffer = try socket.recv(maxBytes: len)
        guard buffer.count == len else {
            throw SessionError.closeByServer
        }
        
        return buffer
    }
}