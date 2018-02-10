Swift mqtt client for ios or osx 【[中文介绍](https://github.com/HJianBo/Mqtt/blob/master/README_CN.md)】
# Feature
- [x] Base `Connect` `Subscribe` `Publish` `Unsubscribe` `Ping` `Disconnect` method.
- [x] Clourse-style、asynchronous interface
- [x] Keep alive
- [x] Clean/Recover session state, when connected server
- [x] Support Linux (Ubuntu)

# Requirements
- iOS 8.0+ | macOS 10.10+ | tvOS 9.0+ | watchOS 2.0+
- Xcode 9.x
- Swift 4

# Integration
### Swift Packet Manager
Add this dependencies in the `Package.swift`
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
Put the following line to your `Cartfile`
```
github "HJianBo/Mqtt"
```

Then checkout this repos
```
carthage build
```

But it will occur compile error because the Mqtt has some others dependencies with **Swift Package Manager**

There is a workaround as the following:
```bash
# Manually checkout SwiftPM dependencies
cd Carthage/Checkouts/Mqtt/ && swift build && cd ../../..

# execute carthage build again
carthage build
```

### CocoaPods

come soon..

# Usage
first, you should import the framework in `.swift` file header
```swift
import Mqtt
```

Create a client
```swift
let client = MqttClient(clientId: "mqtt-client-t")
```

Connect to server
```swift
client.connect(host: "q.emqtt.com") { address, error in
    guard error == nil else {
        print("connect failed, error: \(error)")
        return
    }
    print("connect successful! address: \(address)")
}
```

Subscribe topic with topic filters
```swift
client.subscribe(topicFilters: ["topic": .qos1]) { (res, error) in 
    guard error == nil else {
        print("subscribe topic error: \(error)")
        return
    }
    print("subscribe successful! topic authorized result: \(res)")
}
```

Publish message to some topic
```swift
client.publish(topic: "topic", payload: "hi~🙄", qos: .qos2) { error in
    guard error == nil else {
        print("publish message error: \(error)")
        return
    }
    print("publish message successful!")
}
```

The more details of the use can refer to the Demo program: Examples/SimpleClient

# TODO
- [ ] In-flight Send Window, Message Ordering.
- [ ] Support iOS background model (will disconnect, when lock screen)
- [ ] SSL/TLS

# Dependencies
- [Vapor/Socks](https://github.com/vapor/socks)

