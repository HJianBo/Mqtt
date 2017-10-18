extension MqttClientTests {
    static var allTests : [(String, (MqttClientTests) -> () throws -> Void)] {
        return [
            ("test001_Publish", test001_Publish),
            ("test002_Subscribe",test002_Subscribe),
            ("test003_Unsubscribe", test003_Unsubscribe),
            ("test004_Ping", test004_Ping)
        ]
    }
}

extension MqttPacketTests {
    static var allTests : [(String, (MqttPacketTests) -> () throws -> Void)] {
        return [
            ("testConnectPacket_Init", testConnectPacket_Init),
            ("testConnectPacket_property", testConnectPacket_property),
            ("testConnAck_Init", testConnAck_Init),
            ("testConnAck_property", testConnAck_property),
            ("testPublish_init", testPublish_init),
            ("testPublish_property", testPublish_property),
            ("testPubAck_init", testPubAck_init),
            ("testPubAck_propterty", testPubAck_propterty),
            ("testPubRec_init", testPubRec_init),
            ("testPubRec_property", testPubRec_property),
            ("testPubRel_init", testPubRel_init),
            ("testPubRel_property", testPubRel_property),
            ("testPubComp_init", testPubComp_init),
            ("testPubComp_property", testPubComp_property),
            ("testSubscribe_init", testSubscribe_init),
            ("testSubscribe_propterty", testSubscribe_propterty),
            ("testSubAck_init", testSubAck_init),
            ("testSubAck_property", testSubAck_property),
            ("testUnsubscribe_init", testUnsubscribe_init),
            ("testUnsubscribe_property", testUnsubscribe_property),
            ("testUnsubAck_init", testUnsubAck_init),
            ("testUnsubAck_property", testUnsubAck_property),
            ("testPingReq_init", testPingReq_init),
            ("testPingReq_property", testPingReq_property),
            ("testPingResp_init", testPingResp_init),
            ("testPingResp_property", testPingResp_property),
            ("testDisconect_init", testDisconect_init),
            ("testDisconnect_property", testDisconnect_property)
        ]
    }
}
