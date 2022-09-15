//
//  AppDelegate.swift
//  
//
//  Created by Cătălin Stan on 15/09/2022.
//

import Criollo

class AppDelegate: CRApplicationDelegate {
    
    private lazy var server = CRHTTPServer()
    
    // MARK: - CRApplicationDelegate
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        server.add { _, res, _ in
            res.send("Hello world!")
        }
        server.startListening()
    }
}
