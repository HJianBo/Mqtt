//
//  LocalStorage.swift
//  Mqtt
//
//  Created by HJianBo on 2017/2/16.
//
//

import Foundation

private let defaultKeyPrefix = "goodboy"

// TODO: LocalStorage should support linux

// 以 packetId 为 Key 持久化 `publish` `pubrel` 包
// 协议规定只需要重发这俩个包, 所以暂不考虑持久化其他类型的包
final class LocalStorage {
    var userDefault: UserDefaults
    
    init?(name: String) {
        guard let ud = UserDefaults(suiteName: name) else {
            return nil
        }
        
        userDefault = ud
    }
}

extension LocalStorage {
    
    func save(packet: Packet) {
        guard let packetId = packet.packetIdIfExisted else {
            assert(false)
        }
        userDefault.set(packet.packToData, forKey: "\(defaultKeyPrefix)-\(packetId)")
        userDefault.synchronize()
    }
}

extension LocalStorage {
    func remove(packet: Packet) {
        guard let packetId = packet.packetIdIfExisted else {
            assert(false)
        }
        userDefault.removeObject(forKey: "\(defaultKeyPrefix)-\(packetId)")
        userDefault.synchronize()
    }
}

extension LocalStorage {
    
    func allPacket() -> [Packet] {
        // XXX: the data maybe very big??
        let alldic = userDefault.dictionaryRepresentation()
        var packets = [Packet]()
        for (k, v) in alldic {
            // vaildate the key is correct
            guard k.mq_isVaildationKey else { continue }
            
            // convert to Data type
            guard let dataValue = v as? Data else { continue }
            
            // parse to packet
            guard let packet = parse(data: dataValue) else { continue }
            
            packets.append(packet)
        }
        
        return packets
    }
}

extension LocalStorage {
    
    // parse packet from all packet Data (fixedheader, remained len, variable header, payload)
    // current support only `publish` `pubrel` type
    func parse(data: Data) -> Packet? {
        var remainedData = data
        
        let header = remainedData.removeFirst()
        guard let fixedHeader = FixedHeader(byte: header) else {
            return nil
        }
        
        var multiply = 1
        var length = 0
        while true {
            let byte = remainedData.removeFirst()
            length += Int(byte & 127) * multiply
            // done
            if byte & 0x80 == 0 {
                break
            } else { // continue read length
                multiply *= 128
            }
        }
        
        switch fixedHeader.type {
        case .publish:
            return PublishPacket(header: fixedHeader, bytes: remainedData.bytes)
        case .pubrel:
            return try? PubRelPacket(header: fixedHeader, bytes: remainedData.bytes)
        default:
            assert(false)
        }
        
        return nil
    }
}

extension String {
    
    fileprivate var mq_isVaildationKey: Bool {
        let regxPattern = "\(defaultKeyPrefix)-[\\d]+$"
        do {
            let reg = try NSRegularExpression(pattern: regxPattern,
                                              options: .caseInsensitive)
            
            let range = NSMakeRange(0, characters.count)
            
            let result = reg.matches(in: self, options: .anchored, range: range)
            
            return result.count == 0 ? false : true
        } catch {
            return false
        }
    }
}
