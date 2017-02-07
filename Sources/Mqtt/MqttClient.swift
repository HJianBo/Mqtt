//
//  MqttClient.swift
//  Mqtt
//
//  Created by Heee on 16/1/18.
//  Copyright © 2016年 jianbo. All rights reserved.
//

import Socks
import Foundation

public protocol MqttClientDelegate {
    
    func mqtt(_ mqtt: MqttClient, didRecvConnack packet: ConnAckPacket)
    
    func mqtt(_ mqtt: MqttClient, didPublish packet: PublishPacket)
    
    func mqtt(_ mqtt: MqttClient, didSubscribe packet: SubscribePacket)
    
    func mqtt(_ mqtt: MqttClient, didRecvMessage packet: PublishPacket)
    
    func mqtt(_ mqtt: MqttClient, didUnsubscribe packet: UnsubscribePacket)
    
    func mqtt(_ mqtt: MqttClient, didDisconnect error: Error?)
    
    func mqtt(_ mqtt: MqttClient, didRecvPingresp packet: PingRespPacket)
}

// 扩展协议具有默认实现.
// 当 `协议实现者` 实现该协议后, 实现了该方法. 
// 那么调用者, 调用该方法时是调用的哪个实现？
//extension MqttClientDelegate {
//    public func mqtt(_ mqtt: MqttClient, didRecvPingresp packet: PingRespPacket) {}
//}

/// client session state
public enum SessionState: Int {
    
    /// receive connack is not .accept
    case denied = -1
    
    /// `MqttClient` class has init
    case initialization
    
    /// executing connect method, but not recevie connack packet
    case connecting
    
    /// receive .accept of connack
    case connected
    
    /// executed disconnect success, session end
    case disconnected
}

public enum ClientError: Error {
    
    case aleadryConnected
    
    case aleadryConnecting
    
    case hasDisconnected
    
    case notConnected
    
    case socketIsNil
}

// TODO: 
//  1. 再被远端断开连接后, 需要及时通知程序本身, 及时改变 client 状态, 以及返回码
//  2. 
//
public final class MqttClient {
    
    private var _packetId: UInt16 = 0
    
    public var delegate: MqttClientDelegate?
    
    public fileprivate(set) var sessionState: SessionState = .initialization
    
    public fileprivate(set) var clientId: String
    
    public fileprivate(set) var cleanSession: Bool
    
    public fileprivate(set) var keepAlive: UInt16
    
    public fileprivate(set) var username: String?
    
    public fileprivate(set) var password: String?
    
    var willMessage: PublishPacket?
    
    private var socket: TCPClient?
    
    fileprivate var reader: MqttReader?
    
    fileprivate var sender: MqttSender?

    var mqttQueue: DispatchQueue
    
    var delegateQueue: DispatchQueue
    
    var stateLock: NSLock
    
    var storedPubPacket = [UInt16: PublishPacket]()
    
    var storedSubsPacket = [UInt16: SubscribePacket]()
    
    var storedUnsubsPacket = [UInt16: UnsubscribePacket]()

    public init(clientId: String,
                cleanSession: Bool,
                keepAlive: UInt16,
                username: String?,
                password: String?,
                willMessage: PublishPacket?
        ) {
        self.clientId     = clientId
        self.cleanSession = cleanSession
        self.keepAlive    = keepAlive
        self.username     = username
        self.password     = password
        self.willMessage  = willMessage
        self.stateLock    = NSLock()
        self.mqttQueue    = DispatchQueue(label: "com.mqtt.client")
        self.delegateQueue = DispatchQueue.main
        
    }
    
    fileprivate var nextPacketId: UInt16 {
        if _packetId + 1 >= UInt16.max {
            _packetId = 0
        }
        _packetId += 1
        return _packetId
    }
    
    fileprivate func set(socket: TCPClient) {
        self.socket = socket
        reader = MqttReader(socks: socket, del: self)
        reader?.startRecevie()
        
        sender = MqttSender(sock: socket)
    }
    
    fileprivate func send(packet: Packet) throws {
        guard let sock = socket, !sock.socket.closed, let sender = sender else {
            throw ClientError.notConnected
        }
        sender.send(packet: packet)
    }
    
    
    fileprivate func close() throws {
        
        // TODO: save message queue before close network connection ??
        try socket?.close()
        socket = nil
        reader = nil
    }
}

// MARK: convenience init
extension MqttClient {
    
    public convenience init(clientId: String) {
        self.init(clientId: clientId, cleanSession: false, keepAlive: 60, username: nil, password: nil, willMessage: nil)
    }
    
    public convenience init(clientId: String, cleanSession: Bool) {
        self.init(clientId: clientId, cleanSession: cleanSession, keepAlive: 60, username: nil, password: nil, willMessage: nil)
    }
    
    public convenience init(clientId: String, cleanSession: Bool, keepAlive: UInt16) {
        self.init(clientId: clientId, cleanSession: cleanSession, keepAlive: keepAlive, username: nil, password: nil, willMessage: nil)
    }
    
    
}

// MARK: MQTT method
extension MqttClient {
    
    /**
     
     - parameter port: TCP ports 8883 and 1883 are registered with IANA for MQTT TLS and non TLS communication respectively.
     */
    public func connect(host: String, port: UInt16 = 1883) throws {
        stateLock.lock()
        
        guard sessionState != .connected else {
            stateLock.unlock()
            throw ClientError.aleadryConnected
        }
        
        guard sessionState != .connecting else {
            stateLock.unlock()
            throw ClientError.aleadryConnecting
        }
        
        defer {
            sessionState = .connecting
            stateLock.unlock()
        }
        let addr = InternetAddress(hostname: host, port: port)
        
        // create socket and connect to address
        
        let socket = try TCPClient(address: addr)
        
        // set socket instance to client
        set(socket: socket)
        
        // send connect packet
        var packet = ConnectPacket(clientId: clientId)
        
        packet.username = username
        packet.password = password
        packet.cleanSession = cleanSession
        packet.keepAlive = keepAlive
        
        try send(packet: packet)
    }
    
    public func publish(topic: String, payload: [UInt8], qos: Qos = .qos1) throws {
        let packet = PublishPacket(packetId: nextPacketId, topic: topic, payload: payload, qos: qos)
        
        if qos == .qos0 {
            try send(packet: packet)
            delegateQueue.async { [weak self] in
                guard let weakSelf = self else { return }
                weakSelf.delegate?.mqtt(weakSelf, didPublish: packet)
            }
        } else {
            // store message
            // XXX: 当固定时间没有收到回复时, 应该重发该消息
            storedPubPacket[packet.packetId] = packet
            // send PUBLISH Qos1/2 DUP0
            try send(packet: packet)
        }
    }
    
    public func subscribe(topic: String, qos: Qos = .qos1) throws {
        var packet = SubscribePacket(packetId: nextPacketId)
        
        packet.topics.append((topic, qos))
        
        // stored subscribe packet
        storedSubsPacket[packet.packetId] = packet
        
        try send(packet: packet)
    }
    
    public func unsubscribe(topics: [String]) throws {
        var packet = UnsubscribePacket(packetId: nextPacketId)
        packet.topics = topics
        
        // stored packet
        storedUnsubsPacket[packet.packetId] = packet
        
        // send
        try send(packet: packet)
    }
    
    public func ping() throws {
        let packet = PingReqPacket()
        
        try send(packet: packet)
    }
    
    public func disconnect() throws {
        guard sessionState == .connected else {
            return
        }
        stateLock.lock()
        defer {
            sessionState = .disconnected
            stateLock.unlock()
        }
        let packet = DisconnectPacket()
        
        try send(packet: packet)
        
        // must close the network connect 
        // must not send any more control packets on that network connection
        try close()

        // 改为从reader的socket读取到的状态进行判断
        //delegateQueue.async { [weak self] in
        //    guard let weakSelf = self else { return }
        //    weakSelf.delegate?.mqtt(weakSelf, didDisconnect: nil)
        //}
    }
}

// MARK: Public Helper Method
extension MqttClient {
    
    public func publish(topic: String, payload: String, qos: Qos = .qos1) throws {
        try publish(topic: topic, payload: payload.toBytes(), qos: qos)
    }
}

extension MqttClient: MqttReaderDelegate {
    
    // when recv connect ack
    func reader(_ reader: MqttReader, didRecvConnectAck connack: ConnAckPacket) {
        DDLogInfo("reader recv connect ack \(connack)")
        
        stateLock.lock()
        if connack.returnCode == .accepted {
            sessionState = .connected
        } else {
            sessionState = .denied
        }
        stateLock.unlock()
        delegateQueue.async { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.delegate?.mqtt(weakSelf, didRecvConnack: connack)
        }
    }
    
    func reader(_ reader: MqttReader, didRecvPublish publish: PublishPacket) {
        DDLogInfo("reader recv publish \(publish)")
        
        delegateQueue.async { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.delegate?.mqtt(weakSelf, didRecvMessage: publish)
        }
        
        // feedback ack
        switch publish.fixedHeader.qos {
        case .qos0:
            break
        case .qos1:
            let packet = PubAckPacket(packetId: publish.packetId)
            try? send(packet: packet)
        case .qos2:
            
            // TODO: should stored the packet id, when qos is equal 2
            // XXXX: 如果在某个时间段未收到 pubrec 的返回, 那么应该使用这个 id 再次发送 pubrel
            let packet = PubRecPacket(packetId: publish.packetId)
            try? send(packet: packet)
        }
    }
    
    func reader(_ reader: MqttReader, didRecvPubAck puback: PubAckPacket) {
        DDLogInfo("reader recv publish ack \(puback)")
        
        guard let publish = storedPubPacket[puback.packetId] else {
            DDLogWarn("recv publish ack, but not stored in cache")
            return
        }
        
        // publish is compelate, when qos equal 1
        delegateQueue.async { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.delegate?.mqtt(weakSelf, didPublish: publish)
        }
        
        sender?.someMessageMaybeCompelate(by: puback)
        
        storedPubPacket.removeValue(forKey: puback.packetId)
    }
    
    func reader(_ reader: MqttReader, didRecvPubRec pubrec: PubRecPacket) throws {
        DDLogInfo("reader recv publish rec \(pubrec)")
        
        guard let _ = storedPubPacket[pubrec.packetId] else {
            DDLogWarn("recv public recv, but not stored in cache")
            return
        }
        
        // response PUBREL packet to server
        let pubrel = PubRelPacket(packetId: pubrec.packetId)
        try send(packet: pubrel)
    }
    
    func reader(_ reader: MqttReader, didRecvPubComp pubcomp: PubCompPacket) {
        DDLogInfo("reader recv publish comp \(pubcomp)")
        guard let publish = storedPubPacket[pubcomp.packetId] else {
            DDLogWarn("recv publish comp, but not stored in cache")
            return
        }
        
        // publish is compelate, when qos equal 2
        delegateQueue.async { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.delegate?.mqtt(weakSelf, didPublish: publish)
        }
        storedPubPacket.removeValue(forKey: pubcomp.packetId)
    }
    
    func reader(_ reader: MqttReader, didRecvPubRel pubrel: PubRelPacket) {
        DDLogInfo("reader recv publish rel \(pubrel)")
        
        // TODO: when recv pubrel should discard stored packet id
    }
    
    func reader(_ reader: MqttReader, didRecvSubAck suback: SubAckPacket) {
        DDLogInfo("reader recv subscribe ack \(suback)")
        guard let packet = storedSubsPacket[suback.packetId] else {
            DDLogWarn("recv a suback, but not stored in cache")
            return
        }
        storedSubsPacket.removeValue(forKey: suback.packetId)
        delegateQueue.async { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.delegate?.mqtt(weakSelf, didSubscribe: packet)
        }
    }
    
    func reader(_ reader: MqttReader, didRecvUnsuback unsuback: UnsubAckPacket) {
        DDLogInfo("reader recv unsubscribe ack \(unsuback)")
        
        guard let packet = storedUnsubsPacket[unsuback.packetId] else {
            DDLogWarn("recv a unsubscribe ack, but not stored in cache")
            return
        }
        
        storedUnsubsPacket.removeValue(forKey: unsuback.packetId)
        delegateQueue.async { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.delegate?.mqtt(weakSelf, didUnsubscribe: packet)
        }
    }
    
    func reader(_ reader: MqttReader, didRecvPingresp pingresp: PingRespPacket) {
        DDLogInfo("reader recv ping response \(pingresp)")
        
        delegateQueue.async { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.delegate?.mqtt(weakSelf, didRecvPingresp: pingresp)
        }
    }
    
    func reader(_ reader: MqttReader, didDisconnect error: Error) {
        DDLogInfo("reader disconect event error: \(error)")
        stateLock.lock()
        defer {
            sessionState = .disconnected
            stateLock.unlock()
        }
        
        let diserror: Error? = sessionState == .disconnected ? nil : error
        delegateQueue.async { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.delegate?.mqtt(weakSelf, didDisconnect: diserror)
        }
    }
}
