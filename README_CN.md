Mqtt 是完全使用 Swift 开发的轻量级 Mqtt 客户端框架

# 特性
- 实现了 Mqtt 协议中最基础的几个方法 `Connect` `Subscribe` `Publish` `Unsubscribe` `Ping` `Disconnect`
- 使用 GCD 、全异步、闭包风格的接口
- 简单的心跳保活机制
- Clean Session 和 Publish、Pubrel 包的重发 
- 支持 Linux (Ubuntu)

# 要求
- iOS 8.0+ | macOS 10.10+ | tvOS 9.0+ | watchOS 2.0+
- Xcode 9.x
- Swift 4

# 集成
### Swift Packet Manager
在 `Package.swift`中添加 Mqtt 依赖
```swift
// swift-tools-version:4.0
import PackageDescription

let package = Package(
    // ...
    dependencies: [
        .package(url: "https://github.com/HJianBo/Mqtt", from: "0.2.0"),
    ],
    // ...
)
```

### Carthage
将以下内容加入到 `Cartflie`
```
github "HJianBo/Mqtt"
```

然后，签出该依赖
```
carthage build
```

但此时，**Carthage** 一定会编译失败，因为该库还使用 **Swift Package Manager** 依赖了其他的仓库

这里有一个变通方法是:
```
# Manually checkout SwiftPM dependencies
cd Carthage/Checkouts/Mqtt/ && swift build && cd ../../..

# execute carthage build again
carthage build
```

### CocoaPods
...

# 使用

首先需要在 `.swift` 文件的开头导入本框架
```swift
import Mqtt
```

创建一个客户端
```swift
let client = MqttClient(clientId: "mqtt-client-t")
```

连接
```swift
client.connect(host: "q.emqtt.com") { address, error in
    guard error == nil else {
        print("connect failed, error: \(error)")
        return
    }
    print("connect successful! address: \(address)")
}
```

订阅主题
```swift
client.subscribe(topicFilters: ["topic": .qos1]) { (res, error) in 
    guard error == nil else {
        print("subscribe topic error: \(error)")
        return
    }
    print("subscribe successful! topic authorized result: \(res)")
}
```

发布消息
```swift
client.publish(topic: "topic", payload: "hi~🙄", qos: .qos2) { error in
    guard error == nil else {
        print("publish message error: \(error)")
        return
    }
    print("publish message successful!")
}
```

详情的使用方式可以参考自带的 Demo 程序： Examples/SimpleClient

# TODO
- [ ] 消息窗口、和消息排序
- [ ] 支持 iOS 端，进入的后台、切换导致重连等逻辑

# 依赖
- [Vapor/Socks](https://github.com/vapor/socks)


