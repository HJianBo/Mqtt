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
    
    //func session(_ session: Session, didSubscribe topics: [String: SubsAckReturnCode])
    
    func session(_ session: Session, didSubscribe subscribe: SubscribePacket, withAck suback: SubAckPacket)
    
    func session(_ session: Session, didUnsubscribe unsubs: UnsubscribePacket)
    
    func session(_ session: Session, didDisconnect error: Error?)
}

enum SessionError: Error {
    
    case socketIsNil
    
    case closeByServer
    
    case invaildPacket
    
    case authenticateFailed(reason: String)
    
    static func authenticateError(by returnCode: ConnAckReturnCode) -> SessionError {
        switch returnCode {
        case .badUsernameOrPassword:
            return .authenticateFailed(reason: "the data in the user name or password is malformed")
            
        case .identifierRejected:
            return .authenticateFailed(reason: "the client identifier is correct utf-8 but not allowed by the server")
            
        case .notAuthorized:
            return .authenticateFailed(reason: "the client is not authorized to connect")
            
        case .serverUnavailable:
            return .authenticateFailed(reason: "the network connection has been made but the mqtt service is unavailable")
            
        case.unAccepableProtocolVersion:
            return .authenticateFailed(reason: "the server does not support the level of the mqtt protocol requested by the client")
        case .accepted:
            assert(false)
            return .authenticateFailed(reason: "accepted")
        }
    }
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
            DDLogDebug("mqtt client session state did change to [\(state)]")
        }
    }
    
    weak fileprivate var delegate: SessionDelegate?
    
    fileprivate var remoteAddres: InternetAddress
    
    var serverAddress: String {
        return "\(remoteAddres.hostname):\(remoteAddres.port)"
    }
    
    fileprivate var sendQueueGroup: DispatchGroup
    
    // send message & modify variabel property in this queue
    fileprivate var sendQueue: DispatchQueue
    
    // read cicrle
    fileprivate var readQueue: DispatchQueue
    
    fileprivate var messageQueue: Array<Packet>
    
    fileprivate var storedPacket: Dictionary<UInt16, Packet>
    
    fileprivate var localStorage: LocalStorage?
    
    fileprivate var heartbeatTimer: Timer?
    
    fileprivate(set) var connectPacket: ConnectPacket?
    
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
            weakSelf.localStorage = LocalStorage(name: packet.clientId)
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
            
            // 协议规定只是 `publish` `pubrel` 需要持久化重发
            if packet is PublishPacket || packet is PubRelPacket {
                localStorage?.save(packet: packet)
            }
        }
        
        do {
            try socket.send(data: packet.packToBytes)
            
            // remove
            messageQueue.removeFirst()
            
            // callback
            if packet.qos == .qos0 && packet is PublishPacket {
                delegate?.session(self, didPublish: packet as! PublishPacket)
            }
            
            DDLogVerbose("SEND \(packet)")
            
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
        switch header.type {
        case .connack:
            let conack = try ConnAckPacket(header: header, bytes: payload)
            DDLogInfo("RECV \(conack)")
            
            if conack.returnCode == .accepted {
                sendQueue.async { [weak self] in
                    self?.state = .accepted
                    self?.startHeartbeatTimer()
                }
                
                DDLogInfo("clean sesion is \(String(describing: connectPacket?.cleanSession))")
                
                // recover session if need
                if connectPacket?.cleanSession == false {
                    if let allStoredPacket = localStorage?.allPacket() {
                        DDLogDebug("recover session, resend \(allStoredPacket.count) message")
                        
                        // XXX: packet id 作为排序依据是不正确的.
                        let sortedPacket = allStoredPacket.sorted { p1, p2 in
                            if let pid1 = p1.packetIdIfExisted, let pid2 = p2.packetIdIfExisted {
                                return pid1 < pid2
                            }
                            return true
                        }
                        
                        // push packet to message queue & send it
                        for p in sortedPacket {
                            var p2 = p
                            if p2.qos != .qos0 {
                                p2.fixedHeader.dup = true
                            }
                            send(packet: p2)
                        }
                    }
                } else {
                    let count = localStorage?.removeAll()
                    DDLogDebug("clean session, remove \(String(describing: count)) packet from localstorage")
                }
                
                delegate?.session(self, didConnect: "\(remoteAddres.hostname):\(remoteAddres.port)")
            } else {
                sendQueue.async { [weak self] in
                    self?.state = .denied
                }
                
                let error = SessionError.authenticateError(by: conack.returnCode)
                self.close(withError: error)
            }
            
        case .publish:
            let publish = PublishPacket(header: header, bytes: payload)
            DDLogInfo("RECV \(publish)")
            
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
            DDLogInfo("RECV \(puback)")
            
            guard let sentPacket = storedPacket[puback.packetId] as? PublishPacket else {
                assert(false)
                return
            }
            
            delegate?.session(self, didPublish: sentPacket)
            
            // discard from cahce & localstorage
            storedPacket.removeValue(forKey: puback.packetId)
            localStorage?.remove(packet: sentPacket)
            
        case .pubrec:
            let pubrec = PubRecPacket(header: header, bytes: payload)
            DDLogInfo("RECV \(pubrec)")
            
            guard let sentPacket = storedPacket[pubrec.packetId] as? PublishPacket else {
                DDLogError("should a qos2 publich packet saved in the cache, when recv pubrec. but is \(String(describing: storedPacket[pubrec.packetId]))")
                return
            }
            
            let pubrel = PubRelPacket(packetId: pubrec.packetId)
            
            // XXX: 收到 pubrec 则告诉上层 qos2 的 publish 发送成功
            delegate?.session(self, didPublish: sentPacket)
            
            // discard from cahce & localstorage
            storedPacket.removeValue(forKey: pubrec.packetId)
            localStorage?.remove(packet: sentPacket)
            
            // response pubrel (will save pubrel into localstorage in send method)
            self.send(packet: pubrel)
            
        case .pubcomp:
            let pubcmp = PubCompPacket(header: header, bytes: payload)
            DDLogInfo("RECV \(pubcmp)")
            
            guard let sentMessage = storedPacket[pubcmp.packetId] as? PubRelPacket else {
                DDLogError("should a pubrel packet saved in the cache, when recv pubcmp. but is \(String(describing: storedPacket[pubcmp.packetId]))")
                return
            }
            
            // discard from cahce & localstorage
            storedPacket.removeValue(forKey: sentMessage.packetId)
            localStorage?.remove(packet: sentMessage)
            
        case .pubrel:
            let pubrel = try PubRelPacket(header: header, bytes: payload)
            DDLogInfo("RECV \(pubrel)")
            
            let pubcmp = PubCompPacket(packetId: pubrel.packetId)
            self.send(packet: pubcmp)
            
        case .suback:
            let suback = try SubAckPacket(header: header, bytes: payload)
            DDLogInfo("RECV \(suback)")
            
            guard let sentPacket = storedPacket[suback.packetId] as? SubscribePacket else {
                assert(false)
                return
            }
            
            delegate?.session(self, didSubscribe: sentPacket, withAck: suback)
                
            storedPacket.removeValue(forKey: sentPacket.packetId)

        case .unsuback:
            let unsuback = UnsubAckPacket(header: header, bytes: payload)
            DDLogInfo("RECV \(unsuback)")
            
            guard let sentPacket = storedPacket[unsuback.packetId] as? UnsubscribePacket else {
                assert(false)
                return
            }
            
            delegate?.session(self, didUnsubscribe: sentPacket)
            
            storedPacket.removeValue(forKey: sentPacket.packetId)
            
        case .pingresp:
            let pingresp = PingRespPacket(header: header, bytes: payload)
            DDLogInfo("RECV pong")
            
            delegate?.session(self, didRecvPong: pingresp)
        case .reserved, .reserved2:
            DDLogError("close the network connect, when recv reserved header type")
            self.close(withError: SessionError.invaildPacket)
            break
        default:
            assert(false, "recv a packet type \(header.type), should be handle")
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
