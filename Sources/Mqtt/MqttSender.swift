//
//  MqttSender.swift
//  Mqtt
//
//  Created by HJianBo on 2016/12/8.
//
//

import Socks
import Dispatch
import Foundation

// 在发送消息时
// 1. 是否需要收到返回
// 2. in-flight window 的重发机制是否可以考虑使用 信号量+生产者消费者模式 来实现
// 3. 心跳超时机制 (考虑什么时候发送心跳、什么时候计算为超时)
// 4. packetId 是否应用一个机制，来保障不重复
//protocol Sender {
//    
//    var socket: TCPClient { get }
//    
//    /// serial queue
//    var opQueue: DispatchQueue { get set }
//    
//    /// serial queue
//    var cbQueue: DispatchQueue { get set }
//    
//    var messageQueue: Array<Packet> {get}
//    
//    init(sock: TCPClient)
//    
//    func send(packet: Packet) throws
//}

protocol MqttSenderDelegate: class {
    
    func sender(_ sender: MqttSender, didSendPacket packet: Packet)
}

final class MqttSender {
    
    var socket: TCPClient
    
    var opQueue: DispatchQueue
    
    var cbQueue: DispatchQueue
    
    var messageQueue: Array<PublishPacket>
    
    // flight window 当前索引指针
    var pFligtWindow: Int = 0
    
    // flight window size
    var flightWindow: Int = 5
    
    // 
    var sendCondition: NSCondition
    
    weak var delegate: MqttSenderDelegate?
    
    required init(sock: TCPClient) {
        socket = sock
        
        opQueue = DispatchQueue(label: "com.mqtt.sender.op")
        cbQueue = DispatchQueue(label: "com.mqtt.sender.cb")
        messageQueue = []
        sendCondition = NSCondition()
        
        DispatchQueue.global().async(execute: sendMessageTask)
    }
    
    func send(packet: Packet) {
        // 发送消息分成俩种
        //  1. Ping, Connect 之类的作为优先发送
        //  2. Publish 消息作为放入消息队列，低优先级排队发送
        
        // TODO: 需要把 Subscribe / Unsubscribe 放到消息队列中
        if packet is PublishPacket {
            opQueue.sync {
                messageQueue.append(packet as! PublishPacket)
            }
            sendCondition.signal()
        } else {
            do {
                try socket.send(bytes: packet.packToBytes)
            } catch {
                DDLogError("\(#function): \(error)")
            }
        }
    }
    
    deinit {
        // XXX: Sender 被释放后， Task 需要终止！
        
        // XXX: pFilghtWindow 需要线程安全
    }
}

extension MqttSender {
    
    fileprivate func sendMessageTask() {
        // 1. 等待发送消息的信号
        sendCondition.lock()
        sendCondition.wait()
        sendCondition.unlock()
        guard pFligtWindow < flightWindow && pFligtWindow < messageQueue.count else {
            // 如果条件任然不满足, 则继续
            sendMessageTask()
            return
        }
        
        // 2. send
        let packet = messageQueue[pFligtWindow]
        try? socket.send(bytes: packet.packToBytes)
        
        // 3. 发送成功后, 如果消息的Qos等级为:
        //     - Qos0 则当前元素出队列, 并提示发送成功
        //     - Qos1/2 则当前窗口指针+1
        DDLogVerbose("sender did send \(packet)")
        if packet.fixedHeader.qos == .qos0 {
            opQueue.sync {
                let _ = messageQueue.remove(at: pFligtWindow)
            }
            
            // 提示发送成功
            cbQueue.async { [weak self] in
                guard let weakSelf = self else { return }
                weakSelf.delegate?.sender(weakSelf, didSendPacket: packet)
            }
        } else {
            pFligtWindow += 1
        }
        
        // 4. 循环继续
        sendMessageTask()
    }
}

extension MqttSender {
    
    func someMessageMaybeCompelate(by packet: Packet) {

        if packet is PubAckPacket {
            // Qos1 的包收到了 ACK, 则
            
            let packet = packet as! PubAckPacket
            
            opQueue.sync {
                guard let first = messageQueue.first else {
                    return
                }
                
                guard first.packetId == packet.packetId else {
                    DDLogWarn("recv publish ack is not message queue head response")
                    return
                }
                
                guard first.fixedHeader.qos == .qos1 else {
                    return
                }
                
                // qos1 has complated
                DDLogInfo("packet id[\(first.packetId)][\(first.fixedHeader.qos)] has complated")
                
                let _ = messageQueue.removeFirst()
                pFligtWindow -= 1
                
                cbQueue.async { [weak self] in
                    guard let weakSelf = self else { return }
                    weakSelf.delegate?.sender(weakSelf, didSendPacket: first)
                }
            }
        } else if packet is PubRecPacket {
            let _ = packet as! PubRecPacket
            
        } else if packet is PubRelPacket {
            let _ = packet as! PubRelPacket
        
        } else if packet is PubCompPacket {
            let _ = packet as! PubCompPacket
            
        } else if packet is SubAckPacket {
            let _ = packet as! SubAckPacket
        
        } else if packet is UnsubAckPacket {
            let _ = packet as! UnsubAckPacket
            
        }
    }
}
