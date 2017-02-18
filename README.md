Swift mqtt client for ios or osx 
# Feature
- [x] Base `Connection` `Subscribe` `Publish` `Unsubscribe` `Ping` `Disconnect` method.
- [x] Keep alive
- [x] Clean/Recover session state, when connected server
- [x] Clourse-style、asynchronous interface

# Requirements
- iOS 8.0+ | macOS 10.10+ | tvOS 9.0+ | watchOS 2.0+
- Xcode 8
- Swift 3.0

# Integration
##### Swift Packet Manager
Mqtt Framework can imported by ***Swift Package Manager***, enter the following code in `Package.swift`
```swift
.Package(url: "https://github.com/HJianBo/Mqtt", majorVersion: 0, minor: 1)
```

# Usage
```swift
```


# TODO
- [ ] In-flight Send Window, Message Ordering.
- [ ] Support iOS background model
- [ ] Support Linux

# Dependencies
- [Vapor/Socks](https://github.com/vapor/socks)

