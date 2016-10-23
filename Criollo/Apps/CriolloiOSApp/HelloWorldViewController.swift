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
        let query:NSDictionary! = request.value(forKey: "query") as! NSDictionary
        text += "<h3>Request Query:</h2><pre>"
        query.enumerateKeysAndObjects({ (key,  object, stop) -> Void in
            text += "\(key): \(object)\n"
        })
        text += "</pre>"
        let env:NSDictionary! = request.value(forKey: "env") as! NSDictionary
        text += "<h3>Request Environment:</h2><pre>"
        env.enumerateKeysAndObjects({ (key,  object, stop) -> Void in
            text += "\(key): \(object)\n"
        })
        text += "</pre>"
        self.vars["text"] = text
        return super.present(with: request, response: response)
    }

}
