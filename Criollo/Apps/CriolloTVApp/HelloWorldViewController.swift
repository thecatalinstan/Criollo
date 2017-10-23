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

        var text:String = String()
        
        text += "<h3>Request Query:</h2><pre>"
        for (key, object) in request.query {
            text += "\(key): \(object)\n"
        }
        text += "</pre>"
        
        text += "<h3>Request Environment:</h2><pre>"
        for (key, object) in request.env {
            text += "\(key): \(object)\n"
        }
        text += "</pre>"
        
        self.vars["text"] = text
        return super.present(with: request, response: response)
    }

}
