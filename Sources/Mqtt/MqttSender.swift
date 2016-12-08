//
//  MqttSender.swift
//  Mqtt
//
//  Created by HJianBo on 2016/12/8.
//
//

import Socks

// 在发送消息时
// 1. 是否需要收到返回
// 2. in-flight window 的重发机制是否可以考虑使用 信号量+生产者消费者模式 来实现
// 3. 心跳超时机制 (考虑什么时候发送心跳、什么时候计算为超时)
// 4. packetId 是否应用一个机制，来保障不重复
protocol Sender {
    
    init(sock: TCPClient)
    
    func send(packet: Packet) throws
}
