import XCTest
@testable import MqttTests

XCTMain([
    testCase(MqttClientTests.allTests),
    testCase(MqttPacketTests.allTests),
])
