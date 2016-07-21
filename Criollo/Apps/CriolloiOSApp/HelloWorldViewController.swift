//
//  HelloWorldViewController.swift
//  HelloWorld-Swift
//
//  Created by Cătălin Stan on 11/24/15.
//
//

import Criollo

class HelloWorldViewController: CRViewController {

    override func presentViewControllerWithRequest(request: CRRequest, response: CRResponse) -> String {
        self.vars["title"] = String(self.dynamicType);

        var text:String = String();
        let env:NSDictionary! = request.valueForKey("env") as! NSDictionary;
        text += "<h3>Request Environment:</h2><pre>";
        env.enumerateKeysAndObjectsUsingBlock({ (key,  object, stop) -> Void in
            text += "\(key): \(object)\n";
        });
        text += "</pre>";
        self.vars["text"] = text;
        return super.presentViewControllerWithRequest(request, response: response);
    }

}
