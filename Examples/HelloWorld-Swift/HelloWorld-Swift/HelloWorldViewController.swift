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
        self.templateVariables["title"] = self.className;

        var text:String = String();
        // Request Enviroment
        let env:NSDictionary! = request.valueForKey("env") as! NSDictionary;
        text += "<h3>Request Environment:</h2><pre>";
        env.enumerateKeysAndObjectsUsingBlock({ (key:AnyObject,  object:AnyObject, stop:UnsafeMutablePointer<ObjCBool>) -> Void in
            let envKey:String = key as! String;
            text += "\(envKey): ";
            if let value = object as? String {
                text += "\(value)";
            } else if let value = object as? NSNumber {
                text += "\(value)";
            }
            text += "\n";
        });
        text += "</pre>";

        self.templateVariables["text"] = text;
        return super.presentViewControllerWithRequest(request, response: response);
    }

}
