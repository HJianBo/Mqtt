# Mqtt
Swift mqtt client for ios or osx 

# Feature
- [x] Base `Connection` `Subscribe` `Publish` `Unsubscribe` `Ping` `Disconnect` method.

# TODO
- [ ] Sender&Reader proxy class
- [ ] Session state
- [ ] Keep alive
- [ ] In-flight Send Window, Message Ordering and save unsend messaage when close connection.
- [ ] Read Queue
- [ ] Qos1, Qos2 Re-Delivered
- [ ] Clean Session
- [ ] Clouser Interface
- [ ] Support iOS background model
- [ ] Support macOS iOS tvOS watchOS Linux

# Usage
Mqtt Framework can imported by ***Swift Package Manager***, enter the following code in `Package.swift`

**!Warning** don't have release package now!
```swift
.Package(url: "https://github.com/HJianBo/Mqtt", majorVersion: 0, minor: 0)
```

# Dependencies
- [Vapor/Socks](https://github.com/vapor/socks)


