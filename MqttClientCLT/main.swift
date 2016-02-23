//
//  main.swift
//  MqttClientCLT
//
//  Created by Heee on 16/2/16.
//  Copyright © 2016年 beidouapp. All rights reserved.
//

import Foundation
import Mqtt

let sDefaultHost = "115.28.55.154"
let sDefaultPort = UInt16(1883)


let client = MqttClient(host: sDefaultHost, port: sDefaultPort, clientId: "MacbookPro", cleanSession: false)
client.connect()


dispatch_main()

