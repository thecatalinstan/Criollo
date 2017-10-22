//
//  HelloWorldViewController.swift
//  HelloWorld-Swift
//
//  Created by Cătălin Stan on 11/24/15.
//
//

import Criollo

class HelloWorldViewController: CRViewController {
    
    override func present(with request: CRRequest, response: CRResponse) -> String {
        self.vars["title"] = String(describing: type(of: self))
        
        var text = String()
        
        text += "<h3>Request Query:</h2><pre>"
        for (key, val) in request.query {
            text += "\(key): \(val)\n"
        }
        text += "</pre>"
        
        text += "<h3>Request Environment:</h2><pre>"
        for (key, val) in request.env {
            text += "\(key): \(val)\n"
        }
        text += "</pre>"
        
        self.vars["text"] = text

        return super.present(with: request, response: response)
    }

}
