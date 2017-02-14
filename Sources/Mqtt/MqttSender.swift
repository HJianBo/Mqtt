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

/**
 负责 MQTT 所有的消息发送. 消息分成俩种处理方式
  1. Publish/Subscribe/Unsubscribe: 进入消息队列排队进行发送
  2. 其他类型: 使用优先队列, 优先进行发送
 对于前者, 需要等待其 ACK 回复, 若等待超时则重发该消息
 对于后者, 直接发送
 */
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
    
    var needStopSendTask = false
    
    weak var delegate: MqttSenderDelegate?
    
    required init(sock: TCPClient, del: MqttSenderDelegate? = nil) {
        socket = sock
        delegate = del
        
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
    
    func endTaskNow() {
        needStopSendTask = true
        sendCondition.signal()
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
        
        // 读取当前所需变量的状态
        var _pFligtWindow: Int = 0                          // 窗口指针
        var _flightWindow: Int = 0                          // 窗口大小
        var _messageQueueCount: Int = 0                     // 当前消息队列大小
        var _currentNeedSendPacket: PublishPacket? = nil    // 当前消息
        
        // XXX: 学艺不精的作法
        //      此处避免多线程操作变量, 所以先在 opQueue 里从获取到相关值
        opQueue.sync {
            _pFligtWindow = pFligtWindow
            _flightWindow = flightWindow
            _messageQueueCount = messageQueue.count
            if pFligtWindow < messageQueue.count {
                _currentNeedSendPacket = messageQueue[pFligtWindow]
            }
        }
        
        guard needStopSendTask == false else {
            DDLogInfo("send messages task will stop")
            DDLogVerbose("remain messages number \(_messageQueueCount)")
            // TODO: 保存未发送的数据
            // ...
            return
        }
        
        guard _pFligtWindow < _flightWindow, let indxPacket = _currentNeedSendPacket else {
            // 如果条件任然不满足, 则继续
            sendMessageTask()
            return
        }
        
        // 2. send
        try? socket.send(bytes: indxPacket.packToBytes)
        
        // 3. 发送成功后, 如果消息的Qos等级为:
        //     - Qos0 则当前元素出队列, 并提示发送成功
        //     - Qos1/2 则当前窗口指针+1
        DDLogVerbose("sender did send \(indxPacket)")
        
        if indxPacket.fixedHeader.qos == .qos0 {
            sendSuccessHandler(packet: indxPacket, at: _pFligtWindow)
        }
        
        pFligtWindow += 1
        
        // 4. 循环继续
        sendMessageTask()
    }
    
    // 成功发送
    fileprivate func sendSuccessHandler(packet: PublishPacket, at index: Int) {
        // 从设计来说, 如果要保证 MessageOrder 的话 index 必定为0
        // 否则则不能认为发送成功, 还需要重新发送
        // 
        
        guard index == 0 else {
            DDLogError("call succesSend method in index = \(index)")
            return
        }
        
        // 出队列
        opQueue.sync {
            guard let first = messageQueue.first else {
                assert(false, "message frist is empty")
                return
            }
            
            guard first.packetId == packet.packetId else {
                assert(false, "packet id not equal, maybe exist bug")
                return
            }
            
            messageQueue.removeFirst()
            
            pFligtWindow -= 1
            
            DDLogInfo("packet id[\(first.packetId)][\(first.fixedHeader.qos)] has complated")
            
            // send success callback
            cbQueue.async { [weak self] in
                guard let weakSelf = self else { return }
                weakSelf.delegate?.sender(weakSelf, didSendPacket: packet)
            }
        }
    }
    
    // save unsend message to local stoage
    
    
    //
}

extension MqttSender {
    
    func someMessageMaybeCompelate(by response: Packet) {
        guard let responseId = response.packetIdIfExisted else {
            assert(false, "packet id is nil")
            return
        }
        // 先取到对应的 Packet
        var tmpPacket: PublishPacket? = nil
        var index: Int = -1
        opQueue.sync {
            
            for i in 0 ..< messageQueue.count {
                let p = messageQueue[i]
                guard p.packetId == responseId else {
                    continue
                }
                tmpPacket = p
                index = i
                break
            }
        }
        
        guard let packet = tmpPacket else {
            assert(false, "packet is nil")
            return
        }
        
        
        if response is PubAckPacket {
            let _ = response as! PubAckPacket
            guard packet.fixedHeader.qos == .qos1 else {
                assert(false, "\(packet.fixedHeader.qos) packet recv a `PubAckPacket` response")
                return
            }
            // qos1 has complated
            sendSuccessHandler(packet: packet, at: index)
        } else if response is PubRecPacket {
            let _ = response as! PubRecPacket
            
        } else if response is PubRelPacket {
            let _ = response as! PubRelPacket
        
        } else if response is PubCompPacket {
            let _ = response as! PubCompPacket
            guard packet.fixedHeader.qos == .qos2 else {
                assert(false, "\(packet.fixedHeader.qos) packet recv a `PubCompPacket` response")
                return
            }
            
            // qos2 has complated
            sendSuccessHandler(packet: packet, at: index)
            
        } else if response is SubAckPacket {
            let _ = response as! SubAckPacket
        
        } else if response is UnsubAckPacket {
            let _ = response as! UnsubAckPacket
            
        }
    }
}
