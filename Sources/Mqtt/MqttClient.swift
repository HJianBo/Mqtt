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
    
    func mqtt(_ mqtt: MqttClient, didConnect address: String)
    
    func mqtt(_ mqtt: MqttClient, didPublish packet: PublishPacket)
    
    func mqtt(_ mqtt: MqttClient, didRecvMessage packet: PublishPacket)
    
    func mqtt(_ mqtt: MqttClient, didSubscribe result: [String: SubsAckReturnCode])
    
    func mqtt(_ mqtt: MqttClient, didUnsubscribe topics: [String])
    
    func mqtt(_ mqtt: MqttClient, didDisconnect error: Error?)
    
    func mqtt(_ mqtt: MqttClient, didRecvPong packet: PingRespPacket)
}

public enum ClientError: Error {
    
    case aleadryConnected
    
    case aleadryConnecting
    
    case notConnected
}


public final class MqttClient {
    
    private var _packetId: UInt16 = 0
    
    public var delegate: MqttClientDelegate?
    
    public var sessionState: SessionState {
        get {
            guard let s = session?.state else { return .disconnected }
            return s
        }
    }
    
    public fileprivate(set) var clientId: String
    /**
     When a Client reconnects with CleanSession set to 0, both the Client and Server MUST re-send any
     unacknowledged PUBLISH Packets (where QoS > 0) and PUBREL Packets using their original Packet
     Idenitifiers
     */
    public fileprivate(set) var cleanSession: Bool
    
    public fileprivate(set) var keepAlive: UInt16
    
    public fileprivate(set) var username: String?
    
    public fileprivate(set) var password: String?
    
    var willMessage: PublishPacket?
    
    fileprivate var session: Session?

    var delegateQueue: DispatchQueue

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
        self.delegateQueue = DispatchQueue.main
    }
    
    deinit {
        DDLogVerbose("mqttclient deinit")
    }
    
    fileprivate var nextPacketId: UInt16 {
        if _packetId + 1 >= UInt16.max {
            _packetId = 0
        }
        _packetId += 1
        return _packetId
    }
    
    // `connect` `send` 等操作, 应该进行排队处理
    // 比如立刻的调用 `connect` `send` 应该有正确的返回
    fileprivate func sessionSend(packet: Packet) throws {
        
        guard let session = session else {
            throw ClientError.notConnected
        }
        
        guard sessionState != .disconnected, sessionState != .denied else {
            throw ClientError.notConnected
        }
        
        session.send(packet: packet)
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
        guard sessionState != .accepted else {
            throw ClientError.aleadryConnected
        }
        
        guard sessionState != .connecting else {
            throw ClientError.aleadryConnecting
        }
        
        
        session = Session(host: host, port: port, del: self)
        
        // send connect packet
        var packet = ConnectPacket(clientId: clientId)
        
        packet.username = username
        packet.password = password
        packet.cleanSession = cleanSession
        packet.keepAlive = keepAlive
        session?.connect(packet: packet)
    }
    
    public func publish(topic: String, payload: [UInt8], qos: Qos = .qos1) throws {
        guard topic.mq_isVaildateTopic else {
            return
        }
        
        let packet = PublishPacket(packetId: nextPacketId, topic: topic, payload: payload, qos: qos)
        
        try sessionSend(packet: packet)
    }
    
    public func subscribe(topics: Dictionary<String, Qos>) throws {
        var packet = SubscribePacket(packetId: nextPacketId)
        
        for (k, v) in topics {
            guard k.mq_isVaildateTopic else { continue }
            packet.topics.append((k, v))
        }
        
        try sessionSend(packet: packet)
    }
    
    public func unsubscribe(topics: [String]) throws {
        for t in topics {
            guard t.mq_isVaildateTopic else {
                return
            }
        }
        
        var packet = UnsubscribePacket(packetId: nextPacketId)
        packet.topics = topics
        
        try sessionSend(packet: packet)
    }
    
    public func ping() throws {
        let packet = PingReqPacket()
        
        try sessionSend(packet: packet)
    }
    
    public func disconnect() throws {
        guard sessionState == .accepted else {
            return
        }
        
        let packet = DisconnectPacket()
        try sessionSend(packet: packet)
    }
}

// MARK: Public Helper Method
extension MqttClient {
    
    public func publish(topic: String, payload: String, qos: Qos = .qos1) throws {
        try publish(topic: topic, payload: payload.toBytes(), qos: qos)
    }
    
    public func subscribe(topic: String, qos: Qos) throws {
        try subscribe(topics: [topic: qos])
    }
    
    public func unsubscribe(topic: String) throws {
        try unsubscribe(topics: [topic])
    }
}

// MARK: - SessionDelegate
extension MqttClient: SessionDelegate {
    
    func session(_ session: Session, didRecvPong pingresp: PingRespPacket) {
        DDLogInfo("session did recv pong")
        
        delegateQueue.async { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.delegate?.mqtt(weakSelf, didRecvPong: pingresp)
        }
    }
    
    func session(_ session: Session, didConnect address: String) {
        DDLogInfo("session did connect \(address)")
        
        delegateQueue.async { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.delegate?.mqtt(weakSelf, didConnect: address)
        }
    }

    func session(_ session: Session, didRecvPublish packet: PublishPacket) {
        DDLogInfo("session did recv publish \(packet)")
        
        delegateQueue.async { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.delegate?.mqtt(weakSelf, didRecvMessage: packet)
        }
    }
    
    func session(_ session: Session, didPublish publish: PublishPacket) {
        DDLogInfo("session did send publish \(publish)")
        
        delegateQueue.async { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.delegate?.mqtt(weakSelf, didPublish: publish)
        }
    }
    
    func session(_ session: Session, didSubscribe topics: [String : SubsAckReturnCode]) {
        DDLogInfo("session did subscribe topics \(topics)")
        
        delegateQueue.async { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.delegate?.mqtt(weakSelf, didSubscribe: topics)
        }
    }
    
    func session(_ session: Session, didUnsubscribe topics: [String]) {
        DDLogInfo("session did unsubscirbe topics \(topics)")
        
        delegateQueue.async { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.delegate?.mqtt(weakSelf, didUnsubscribe: topics)
        }
    }
    
    func session(_ session: Session, didDisconnect error: Error?) {
        DDLogInfo("session did disconnect error: \(error)")
        
        self.session = nil
        delegateQueue.async { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.delegate?.mqtt(weakSelf, didDisconnect: error)
        }
    }
}
