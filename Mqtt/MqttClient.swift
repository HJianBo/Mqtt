//
//  MqttClient.swift
//  Mqtt
//
//  Created by Heee on 16/1/18.
//  Copyright © 2016年 jianbo. All rights reserved.
//

import Foundation


open class MqttClient {
    
    var clientId: String
    var cleanSession: Bool
    var keepAlive: UInt16
    
    var username: String?
    var password: String?
    var willMessage: PublishPacket?
    
    fileprivate var stream: Stream

    public init(host: String, port: UInt16, clientId: String, cleanSession: Bool, keepAlive: UInt16 = 60) {
        self.clientId     = clientId
        self.cleanSession = cleanSession
        self.keepAlive    = keepAlive
        
        stream = Stream(host: host, port: port)
        
        stream.delegate = self
    }
}



extension MqttClient {
    
    public func connect() {
        stream.open()
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

extension MqttClient: StreamDelegate {
    
    func stream(_ stream: Stream, didOpenAtHost host: String, port: UInt16) {
        
        
        var packet = ConnectPacket(clientId: clientId)
        
        packet.userName = username
        packet.password = password
        packet.keepAlive = keepAlive
        packet.cleanSession = cleanSession
        
        // TODO: WillMessage
        packet.willTopic = willMessage?.topicName
        
        stream.send(packet.packToData)
        
        // FIXME: read a header
        stream.read(5)
    }
    
    func stream(_ stream: Stream, didRecvData data: Data) {
        NSLog("didRecv: \(data)")
    }
    
    func stream(_ stream: Stream, didSendData data: Data) {
        NSLog("didSend: \(data)")
    }
}
