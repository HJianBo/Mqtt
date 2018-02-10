//
//  MqttClient.swift
//  Mqtt
//
//  Created by Heee on 16/1/18.
//  Copyright © 2016年 jianbo. All rights reserved.
//

import Foundation
import Dispatch

public protocol MqttClientDelegate {
    
    func mqtt(_ mqtt: MqttClient, didRecvMessage packet: PublishPacket)
    
    func mqtt(_ mqtt: MqttClient, didPublish publish: PublishPacket)
    
    func mqtt(_ mqtt: MqttClient, didDisconnect error: Error?)
    
    func mqtt(_ mqtt: MqttClient, didRecvPong packet: PingRespPacket)
}

public enum ClientError: Error {
    
    case aleadryConnected
    
    case aleadryConnecting
    
    case notConnected
    
    case paramIllegal
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
    
    public var serverAddress: String {
        return session?.serverAddress ?? ""
    }
    
    // will message set
    public var willTopic: String?
    public var willMessage: String?
    public var willQos: Qos = .qos0
    public var willRetain = false
    
    fileprivate var session: Session?

    var delegateQueue: DispatchQueue
    
    public typealias ConnectHandler = (String, Error?) -> Void
    public typealias MessageHandler = (Error?) -> Void
    public typealias SubscribeHandler = (Dictionary<String, SubsAckReturnCode>, Error?) -> Void
    
    var connectCompelationHandler: ConnectHandler?
    
    var messageCallbacks: Dictionary<UInt16, MessageHandler>
    
    var subscriCallbacks: Dictionary<UInt16, SubscribeHandler>

    public init(clientId: String,
                cleanSession: Bool,
                keepAlive: UInt16,
                username: String?,
                password: String?
        ) {
        self.clientId     = clientId
        self.cleanSession = cleanSession
        self.keepAlive    = keepAlive
        self.username     = username
        self.password     = password
        self.delegateQueue = DispatchQueue.main
        
        messageCallbacks = [:]
        subscriCallbacks = [:]
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
        self.init(clientId: clientId, cleanSession: false, keepAlive: 60, username: nil, password: nil)
    }
    
    public convenience init(clientId: String, cleanSession: Bool) {
        self.init(clientId: clientId, cleanSession: cleanSession, keepAlive: 60, username: nil, password: nil)
    }
    
    public convenience init(clientId: String, cleanSession: Bool, keepAlive: UInt16) {
        self.init(clientId: clientId, cleanSession: cleanSession, keepAlive: keepAlive, username: nil, password: nil)
    }
}

// MARK: MQTT method
extension MqttClient {
    
    /**
     Connect mqtt server
     
     - parameter port: TCP ports 8883 and 1883 are registered with IANA for MQTT TLS and non TLS communication respectively.
     */
    public func connect(host: String, port: UInt16 = 1883, handler: ((String, Error?) -> Void)? = nil) {
        do {
            guard sessionState != .accepted else {
                throw ClientError.aleadryConnected
            }
            
            guard sessionState != .connecting else {
                throw ClientError.aleadryConnecting
            }
            
            session = Session(host: host, port: port, del: self)
            connectCompelationHandler = handler
            
            // send connect packet
            var packet = ConnectPacket(clientId: clientId)
            
            packet.username = username
            packet.password = password
            packet.cleanSession = cleanSession
            packet.keepAlive = keepAlive
            
            // set will message
            if let willTopic = self.willTopic, let willMessage = self.willMessage {
                packet.willTopic   = willTopic
                packet.willMessage = willMessage
                packet.willQos     = willQos
                packet.willRetain  = willRetain
                packet.willFlag    = true
            }
            
            session?.connect(packet: packet)
        } catch {
            delegateQueue.async {
                handler?("\(host):\(port)", error)
            }
            
            connectCompelationHandler = nil
        }
    }
    
    
    /**
     
    */
    public func publish(topic: String, payload: [UInt8], qos: Qos = .qos1, retain: Bool = false, handler: ((Error?) -> Void)? = nil) {
        do {
            guard topic.mq_isVaildateTopic else {
                throw ClientError.paramIllegal
            }
            
            let packetId = nextPacketId
            
            messageCallbacks[packetId] = handler
            var packet = PublishPacket(packetId: packetId, topic: topic, payload: payload, qos: qos)
            
            packet.fixedHeader.retain = retain
            
            // send packet
            try sessionSend(packet: packet)
        } catch {
            delegateQueue.async {
                handler?(error)
            }
            
            // XXX: should rm handler cache, while a error throwed from `sessionSend`,
        }
    }
    
    /**
     
     */
    public func subscribe(topicFilters: Dictionary<String, Qos>, handler: SubscribeHandler? = nil) {
        do {
            var convertedFilters = [(String, Qos)]()
            for (k, v) in topicFilters {
                guard k.mq_isVaildateTopicFilter else {
                    throw ClientError.paramIllegal
                }
                convertedFilters.append((k, v))
            }
            let packetId = nextPacketId
            var packet = SubscribePacket(packetId: packetId)
            packet.topicFilters = convertedFilters
            // cahce handler
            subscriCallbacks[packetId] = handler
            // send packet
            try sessionSend(packet: packet)
        } catch {
            delegateQueue.async {
                var subres = Dictionary<String, SubsAckReturnCode>()
                for (k, _) in topicFilters {
                    subres[k] = .failure
                }
                
                handler?(subres, error)
            }
            // XXX: should rm hander from cache
        }
    }
    
    /**
     
     */
    public func unsubscribe(topicFilters: [String], handler: ((Error?) -> Void)? = nil) {
        do {
            for t in topicFilters {
                guard t.mq_isVaildateTopicFilter else {
                    throw ClientError.paramIllegal
                }
            }
            let packetId = nextPacketId
            var packet = UnsubscribePacket(packetId: packetId)
            packet.topics = topicFilters
            
            // cache handler
            messageCallbacks[packetId] = handler
            
            // send packet
            try sessionSend(packet: packet)
        } catch {
            delegateQueue.async {
                handler?(error)
            }
            // XXX: should rm handler from cahce, when a error throwed from seesionSend
        }
    }
    
    
    /// ping
    public func ping() throws {
        let packet = PingReqPacket()
        try sessionSend(packet: packet)
    }
    
    /// disconnect
    public func disconnect() throws {
        let packet = DisconnectPacket()
        try sessionSend(packet: packet)
    }
}

// MARK: Public Helper Method
extension MqttClient {
    
    public func publish(topic: String, payload: String, qos: Qos = .qos1, retain: Bool = false, handler: MessageHandler? = nil) {
        publish(topic: topic, payload: payload.bytes, qos: qos, retain: retain, handler: handler)
    }
}

// MARK: - SessionDelegate
extension MqttClient: SessionDelegate {
    
    func session(_ session: Session, didConnect address: String) {
        DDLogInfo("session did connect \(address)")
        
        delegateQueue.async { [weak self] in
            guard let weakSelf = self else { return }
            // exec handler
            weakSelf.connectCompelationHandler?(address, nil)
            weakSelf.connectCompelationHandler = nil
        }
    }
    
    func session(_ session: Session, didDisconnect error: Error?) {
        DDLogInfo("session did disconnect error: \(String(describing: error))")
        
        self.session = nil
        delegateQueue.async { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.delegate?.mqtt(weakSelf, didDisconnect: error)
            // exec handler
            weakSelf.connectCompelationHandler?(session.serverAddress, error)
            weakSelf.connectCompelationHandler = nil
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
            
            // exec handler
            guard let msgHandler = weakSelf.messageCallbacks[publish.packetId] else {
                return
            }
            msgHandler(nil)
            weakSelf.messageCallbacks[publish.packetId] = nil
        }
    }
    
    func session(_ session: Session, didSubscribe subscribe: SubscribePacket, withAck suback: SubAckPacket) {
        var subres = [String: SubsAckReturnCode]()
        
        for i in 0 ..< subscribe.topicFilters.count {
            let topic = subscribe.topicFilters[i].0
            let retCode = suback.returnCodes[i]
            subres[topic] = retCode
        }
        
        DDLogInfo("session did subscribe topics \(subres)")
        
        delegateQueue.async { [weak self] in
            guard let weakSelf = self else { return }
            
            // exec message handler
            guard let subsHandler = weakSelf.subscriCallbacks[subscribe.packetId] else {
                assert(false)
                return
            }
            subsHandler(subres, nil)
            weakSelf.subscriCallbacks[subscribe.packetId] = nil
        }
    }

    func session(_ session: Session, didUnsubscribe unsubs: UnsubscribePacket) {
        DDLogInfo("session did unsubscirbe topics \(unsubs.topics)")
        
        delegateQueue.async { [weak self] in
            guard let weakSelf = self else { return }
            // exec message handler
            guard let msgHandler = weakSelf.messageCallbacks[unsubs.packetId] else {
                assert(false)
                return
            }
            msgHandler(nil)
            weakSelf.messageCallbacks[unsubs.packetId] = nil
        }
    }
    
    func session(_ session: Session, didRecvPong pingresp: PingRespPacket) {
        DDLogInfo("session did recv pong")
        
        delegateQueue.async { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.delegate?.mqtt(weakSelf, didRecvPong: pingresp)
        }
    }
}
