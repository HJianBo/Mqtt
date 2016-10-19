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
    
    fileprivate var stream: Stream

    public init(host: String, port: UInt16, clientId: String, cleanSession: Bool = false, keepAlive: UInt16 = 60) {
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
    
    enum ReaderAction: Int {
        case header = 0
        case length
        case payload
    }
    
    func readHeader() {
        stream.read(1, flag: ReaderAction.header.rawValue)
    }
    
    func readLength() {
        stream.read(1, flag: ReaderAction.length.rawValue)
    }
    
    func readPaylod(len: Int) {
        
    }
    
    
    func stream(_ stream: Stream, didOpenAtHost host: String, port: UInt16) {
        
        var packet = ConnectPacket(clientId: clientId)
        
        packet.userName = username
        packet.password = password
        packet.keepAlive = keepAlive
        packet.cleanSession = cleanSession
        
        // TODO: WillMessage
        packet.willTopic = willMessage?.topicName
        
        stream.send(packet.packToData)
        
        // recv response
        readHeader()
    }
    
    func stream(_ stream: Stream, didRecvData data: Data, flag: Int) {
        NSLog("didRecv: \(data), flag: \(flag)")
        if flag == ReaderAction.header.rawValue {
            let header = PacketFixHeader(byte: data[0])
            print(header)
        }
        
        switch ReaderAction(rawValue: flag)! {
        case .header:
            readLength()
        case .length:
            // ...
            
            
            
            readPaylod(len: 10)
        case .payload:
            // ...
            readHeader()
        }
    }
    
    func stream(_ stream: Stream, didSendData data: Data, flag: Int) {
        NSLog("didSend: \(data), flag: \(flag)")
    }
}
