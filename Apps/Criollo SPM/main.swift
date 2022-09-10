//
//  main.swift
//  Criollo SPM
//
//  Created by Cătălin Stan on 10/09/2022.
//

import Foundation
import Criollo

let server = CRHTTPServer()
server.get("/") { _, res, done in
    res.send("Hello world!")
    done()
}

server.startListening()

Dispatch.dispatchMain()
