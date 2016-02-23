//
//  MqttClient.swift
//  Mqtt
//
//  Created by Heee on 16/1/18.
//  Copyright © 2016年 jianbo. All rights reserved.
//

import Foundation


public class MqttClient {
    
    var clientId: String
    var cleanSession: Bool
    var keepAlive: UInt16
    
    var username: String?
    var password: String?
    var willMessage: PublishPacket?
    
    private var stream: MqttStream

    public init(host: String, port: UInt16, clientId: String, cleanSession: Bool, keepAlive: UInt16 = 60) {
        self.clientId     = clientId
        self.cleanSession = cleanSession
        self.keepAlive    = keepAlive
        
        stream = MqttStream(host: host, port: port)
        
        stream.delegate = self
    }
}



extension MqttClient {
    
    public func connect() {
        stream.connect()
    }
    
    public func publish() {
        
    }
    
    public func subscribe() {
    
    }
    
    public func unsubscribe() {
        
    }
    
    public func ping() {
        
    }
    
    public func disconnect() {
    
    }
}

extension MqttClient: MqttStreamDelegate {
    
    func stream(stream: MqttStream, didConnectHost host: String, port: UInt16) {
        var packet = ConnectPacket(clientId: clientId)
        
        packet.userName = username
        packet.password = password
        packet.keepAlive = keepAlive
        packet.cleanSession = cleanSession
        
        // TODO: WillMessage
        packet.willTopic = willMessage?.topicName
        stream.send(packet)
    }
    
    func stream(stream: MqttStream, didSendPacket packet: Packet) {
        
    }
    
    func stream(stream: MqttStream, didRecvPacket packet: Packet) {
        
    }
}