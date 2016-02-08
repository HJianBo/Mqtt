//
//  MqttClient.swift
//  Mqtt
//
//  Created by Heee on 16/1/18.
//  Copyright © 2016年 jianbo. All rights reserved.
//

import Foundation



class MqttClient {
    
    var clientId: String
    var cleanSession: Bool
    var keepAlive: UInt16
    
    var username: String?
    var password: String?
    var willMessage: PublishPacket?
    
    private var stream: MqttStream

    init(host: String, port: UInt16, clientId: String, cleanSession: Bool, keepAlive: UInt16 = 60) {
        self.clientId     = clientId
        self.cleanSession = cleanSession
        self.keepAlive    = keepAlive
        
        stream = MqttStream(host: host, port: port)
    }
}



extension MqttClient {
    
    func connect() {
        var packet = ConnectPacket(clientId: clientId)
        
        packet.userName = username
        packet.password = password
        packet.keepAlive = keepAlive
        packet.cleanSession = cleanSession
        
        // TODO: WillMessage
        packet.willTopic = willMessage?.topicName
        stream.connect()
    }
    
    func publish() {
    
    }
    
    func subscribe() {
    
    }
    
    func unsubscribe() {
        
    }
    
    func ping() {
        
    }
    
    func disconnect() {
    
    }
}

