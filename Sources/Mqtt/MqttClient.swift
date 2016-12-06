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
    
    func mqtt(_ mqtt: MqttClient, didSubcribe packet: SubscribePacket)
    
    func mqtt(_ mqtt: MqttClient, didRecvMessage packet: PublishPacket)
}

public final class MqttClient {
    
    private var _packetId: UInt16 = 0
    
    public var delegate: MqttClientDelegate?
    
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
    
    // sync method
    fileprivate func send(packet: Packet, recv: Bool = true) throws {
        
        // TODO: when socket is nil, throw a error
        try socket?.send(bytes: packet.packToBytes)
        
        // TODO: when reader is nil, throw a error
        if recv {
            try reader?.read()
        }
    }
    
    fileprivate func readPacket() throws {
        try reader?.read()
    }
}

// MARK: MQTT method
extension MqttClient {
    
    public func connect(host: String, port: UInt16) throws {
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
        
        try send(packet: packet, recv: false)
        
        if qos == .qos0 {
            delegate?.mqtt(self, didPublish: packet)
        } else {
            storedPubPacket[packet.packetId] = packet
        }
        
        try readPacket()
    }
    
    public func subscribe(topic: String, qos: Qos = .qos1) throws {
        var packet = SubscribePacket(packetId: nextPacketId)
        
        packet.topics.append((topic, qos))
        
        try send(packet: packet, recv: false)
        
        storedSubsPacket[packet.packetId] = packet
        
        try readPacket()
    }
    
    public func unsubscribe(topics: [String]) throws {
        var packet = UnsubscribePacket(packetId: nextPacketId)
        packet.topics = topics
        
        try send(packet: packet)
    }
    
    public func ping() throws {
        let packet = PingReqPacket()
        
        try send(packet: packet)
    }
    
    public func disconnect() throws {
        let packet = DisconnectPacket()
        
        try send(packet: packet)
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
            assert(false)
            return
        }
        
        // publish is compelate, when qos equal 1
        delegate?.mqtt(self, didPublish: publish)
        storedPubPacket.removeValue(forKey: puback.packetId)
    }
    
    func reader(_ reader: MqttReader, didRecvPubRec pubrec: PubRecPacket) throws {
        DDLogDebug("recv publish rec \(pubrec)")
        
        guard let _ = storedPubPacket[pubrec.packetId] else {
            assert(false)
            return
        }
        
        // response PUBREL packet to server
        let pubrel = PubRelPacket(packetId: pubrec.packetId)
        try send(packet: pubrel)
    }
    
    func reader(_ reader: MqttReader, didRecvPubComp pubcomp: PubCompPacket) {
        DDLogDebug("recv publish comp \(pubcomp)")
        guard let publish = storedPubPacket[pubcomp.packetId] else {
            assert(false)
            return
        }
        
        // publish is compelate, when qos equal 2
        delegate?.mqtt(self, didPublish: publish)
        storedPubPacket.removeValue(forKey: pubcomp.packetId)
    }
    
    func reader(_ reader: MqttReader, didRecvSubAck suback: SubAckPacket) {
        DDLogDebug("recv subscribe ack \(suback)")
        guard let packet = storedSubsPacket[suback.packetId] else {
            DDLogWarn("recv a suback, but not in stored subscribe packet")
            return
        }
        storedSubsPacket.removeValue(forKey: suback.packetId)
        delegate?.mqtt(self, didSubcribe: packet)
    }
}
