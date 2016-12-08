//
//  MqttClient.swift
//  Mqtt
//
//  Created by Heee on 16/1/18.
//  Copyright © 2016年 jianbo. All rights reserved.
//

import Socks

public protocol MqttClientDelegate {
    
    func mqtt(_ mqtt: MqttClient, didRecvConnack packet: ConnAckPacket)
    
    func mqtt(_ mqtt: MqttClient, didPublish packet: PublishPacket)
    
    func mqtt(_ mqtt: MqttClient, didSubscribe packet: SubscribePacket)
    
    func mqtt(_ mqtt: MqttClient, didRecvMessage packet: PublishPacket)
    
    func mqtt(_ mqtt: MqttClient, didUnsubscribe packet: UnsubscribePacket)
    
    func mqtt(_ mqtt: MqttClient, didDisconnect error: Error?)
}

extension MqttClientDelegate {
    public func mqtt(_ mqtt: MqttClient, didRecvPingresp packet: PingRespPacket) {}
}

public final class MqttClient {
    
    private var _packetId: UInt16 = 0
    
    public var delegate: MqttClientDelegate?
    
    // TODO:
    public var sessionState: Int = 0
    
    var clientId: String
    
    var cleanSession: Bool
    
    var keepAlive: UInt16
    
    var username: String?
    
    var password: String?
    
    var willMessage: PublishPacket?
    
    private var socket: TCPClient?
    
    private var reader: MqttReader?
    
    var storedPubPacket = [UInt16: PublishPacket]()
    
    var storedSubsPacket = [UInt16: SubscribePacket]()
    
    var storedUnsubsPacket = [UInt16: UnsubscribePacket]()

    public init(clientId: String,
                cleanSession: Bool = false,
                keepAlive: UInt16 = 60
        ) {
        self.clientId     = clientId
        self.cleanSession = cleanSession
        self.keepAlive    = keepAlive
    }
    
    fileprivate var nextPacketId: UInt16 {
        // FIXME: over flow?
        _packetId += 1
        return _packetId
    }
    
    fileprivate func set(socket: TCPClient) {
        self.socket = socket
        reader = MqttReader(socks: socket, del: self)
    }
    
    // TODO: 需改为 sender 进行代理消息的发送
    // sync method
    fileprivate func send(packet: Packet, recv: Bool = true) throws {
        
        // TODO: when socket is nil, throw a error
        try socket?.send(bytes: packet.packToBytes)
    }
    
    fileprivate func close() throws {
        
        // TODO: save message queue before close network connection ??
        try socket?.close()
    }
}

// MARK: MQTT method
extension MqttClient {
    
    /**
     
     - parameter port: TCP ports 8883 and 1883 are registered with IANA for MQTT TLS and non TLS communication respectively.
     */
    public func connect(host: String, port: UInt16 = 1883) throws {
        let addr = InternetAddress(hostname: host, port: port)
        
        // create socket and connect to address
        let socket = try TCPClient(address: addr)
        
        // set socket instance to client
        set(socket: socket)
        
        // send connect packet
        var packet = ConnectPacket(clientId: clientId)
        
        packet.userName = username
        packet.password = password
        packet.cleanSession = cleanSession
        packet.keepAlive = keepAlive
        
        try send(packet: packet)
    }
    
    public func publish(topic: String, payload: [UInt8], qos: Qos = .qos1) throws {
        let packet = PublishPacket(packetId: nextPacketId, topic: topic, payload: payload, qos: qos)
        
        if qos == .qos0 {
            try send(packet: packet, recv: false)
            delegate?.mqtt(self, didPublish: packet)
        } else {
            // store message
            storedPubPacket[packet.packetId] = packet
            // send PUBLISH Qos1/2 DUP0
            try send(packet: packet, recv: false)
        }
    }
    
    public func subscribe(topic: String, qos: Qos = .qos1) throws {
        var packet = SubscribePacket(packetId: nextPacketId)
        
        packet.topics.append((topic, qos))
        
        // stored subscribe packet
        storedSubsPacket[packet.packetId] = packet
        
        try send(packet: packet, recv: false)
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
        let packet = DisconnectPacket()
        
        try send(packet: packet)
        
        // must close the network connect 
        // must not send any more control packets on that network connection
        try close()
        delegate?.mqtt(self, didDisconnect: nil)
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
        DDLogDebug("recv connect ack \(connack)")
        
        delegate?.mqtt(self, didRecvConnack: connack)
    }
    
    func reader(_ reader: MqttReader, didRecvPublish publish: PublishPacket) {
        DDLogDebug("recv publish \(publish)")
        
        delegate?.mqtt(self, didRecvMessage: publish)
        
        // feedback ack
        switch publish.fixedHeader.qos {
        case .qos0:
            break
        case .qos1:
            let packet = PubAckPacket(packetId: publish.packetId)
            try? send(packet: packet)
        case .qos2:
            let packet = PubRecPacket(packetId: publish.packetId)
            try? send(packet: packet)
        }
    }
    
    func reader(_ reader: MqttReader, didRecvPubAck puback: PubAckPacket) {
        DDLogDebug("recv publish ack \(puback)")
        
        guard let publish = storedPubPacket[puback.packetId] else {
            DDLogWarn("recv publish ack, but not stored in cache")
            return
        }
        
        // publish is compelate, when qos equal 1
        delegate?.mqtt(self, didPublish: publish)
        storedPubPacket.removeValue(forKey: puback.packetId)
    }
    
    func reader(_ reader: MqttReader, didRecvPubRec pubrec: PubRecPacket) throws {
        DDLogDebug("recv publish rec \(pubrec)")
        
        guard let _ = storedPubPacket[pubrec.packetId] else {
            DDLogWarn("recv public recv, but not stored in cache")
            return
        }
        
        // response PUBREL packet to server
        let pubrel = PubRelPacket(packetId: pubrec.packetId)
        try send(packet: pubrel)
    }
    
    func reader(_ reader: MqttReader, didRecvPubComp pubcomp: PubCompPacket) {
        DDLogDebug("recv publish comp \(pubcomp)")
        guard let publish = storedPubPacket[pubcomp.packetId] else {
            DDLogWarn("recv publish comp, but not stored in cache")
            return
        }
        
        // publish is compelate, when qos equal 2
        delegate?.mqtt(self, didPublish: publish)
        storedPubPacket.removeValue(forKey: pubcomp.packetId)
    }
    
    func reader(_ reader: MqttReader, didRecvSubAck suback: SubAckPacket) {
        DDLogDebug("recv subscribe ack \(suback)")
        guard let packet = storedSubsPacket[suback.packetId] else {
            DDLogWarn("recv a suback, but not stored in cache")
            return
        }
        storedSubsPacket.removeValue(forKey: suback.packetId)
        delegate?.mqtt(self, didSubscribe: packet)
    }
    
    func reader(_ reader: MqttReader, didRecvUnsuback unsuback: UnsubAckPacket) {
        DDLogDebug("recv unsubscribe ack \(unsuback)")
        
        guard let packet = storedUnsubsPacket[unsuback.packetId] else {
            DDLogWarn("recv a unsubscribe ack, but not stored in cache")
            return
        }
        
        storedUnsubsPacket.removeValue(forKey: unsuback.packetId)
        delegate?.mqtt(self, didUnsubscribe: packet)
    }
    
    func reader(_ reader: MqttReader, didRecvPingresp pingresp: PingRespPacket) {
        DDLogDebug("recv ping response \(pingresp)")
        
        delegate?.mqtt(self, didRecvPingresp: pingresp)
    }
}
