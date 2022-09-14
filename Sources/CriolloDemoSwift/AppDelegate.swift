//
//  AppDelegate.swift
//  
//
//  Created by Cătălin Stan on 15/09/2022.
//

import CriolloSwift

@main
class AppDelegate: ApplicationDelegate {

    private lazy var server = CRHTTPServer()
    
    public static func main() throws {
        try Criollo.applicationMain(AppDelegate())
    }
        
    // MARK: - ApplicationDelegate
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        server.add { _, res, _ in
            res.send("Hello world!")
        }
        server.startListening()
    }
    
}
