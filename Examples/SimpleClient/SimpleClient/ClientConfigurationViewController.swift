//
//  ClientConfigurationViewController.swift
//  SimpleClient
//
//  Created by HJianBo on 2017/1/8.
//  Copyright © 2017年 beidouapp. All rights reserved.
//

import UIKit

struct Configuration {
    
    var host: String = ""
    
    var clientId = ""
    
    var cleanSession =  false
    
    var keepAlive: UInt16 = 60
    
    var username: String?
    
    var password: String?
    
    init(h: String, cid: String) {
        host = h
        clientId = cid
    }
}

class ClientConfigurationViewController: UIViewController {

    var configuration = Configuration(h: "127.0.0.1", cid: "iosclient")
    
    @IBOutlet weak var txtHost: UITextField!
    @IBOutlet weak var txtClientId: UITextField!
    @IBOutlet weak var txtUsername: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var txtKeepalive: UITextField!
    @IBOutlet weak var switCleansess: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done,
                                                            target: self,
                                                            action: #selector(touchedConfigurationDone(sender:)))
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        txtHost.text = configuration.host
        txtClientId.text = configuration.clientId
        txtKeepalive.text = "\(configuration.keepAlive)"
        
        switCleansess.setOn(configuration.cleanSession, animated: true)
        
        if let username = configuration.username {
            txtUsername.text = username
        }
        if let password = configuration.password {
            txtPassword.text = password
        }
    }
    
    @objc func touchedConfigurationDone(sender: Any) {
        configuration.host = txtHost.text ?? ""
        configuration.clientId = txtClientId.text ?? ""
        configuration.cleanSession = switCleansess.isOn
        
        if let keepAlive = UInt16(txtKeepalive.text ?? "0") {
            configuration.keepAlive = keepAlive
        }
        
        if let username = txtUsername.text {
            configuration.username = username
        }
        
        if let password = txtPassword.text {
            configuration.password = password
        }
        
        navigationController?.popViewController(animated: true)
    }
}
