//
//  MqttClient.swift
//  Mqtt
//
//  Created by Heee on 16/1/18.
//  Copyright © 2016年 jianbo. All rights reserved.
//

import Socks

public class MqttClient {
    
    private var _packetId: UInt16 = 0
    
    var clientId: String
    
    var cleanSession: Bool
    
    var keepAlive: UInt16
    
    var username: String?
    
    var password: String?
    
    var willMessage: PublishPacket?
    
    private var socket: TCPClient?
    
    private var reader: MqttReader?

    public init(clientId: String,
                cleanSession: Bool = false,
                keepAlive: UInt16 = 60
        ) {
        self.clientId     = clientId
        self.cleanSession = cleanSession
        self.keepAlive    = keepAlive
    }
    
    fileprivate var packetId: UInt16 {
        return _packetId
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
    
    fileprivate func send(packet: Packet, recv: Bool = true) throws {
        
        // TODO: when socket is nil, throw a error
        try socket?.send(bytes: packet.packToBytes)
        
        // TODO: when reader is nil, throw a error
        if recv {
            try reader?.read()
        }
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
        let packet = PublishPacket(packetId: nextPacketId, topic: topic, payload: payload)
        
        try send(packet: packet)
    }
    
    public func subscribe(topic: String, qos: Qos = .qos1) throws {
        let packet = SubscribePacket(packetId: nextPacketId, qos: qos)
        
        try send(packet: packet)
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

extension MqttClient {

}

extension MqttClient: MqttReaderDelegate {
    
    // when recv connect ack
    func reader(_ reader: MqttReader, didRecvConnectAck connack: ConnAckPacket) {
        DDLogDebug("recv connectack \(connack)")
    }
}
