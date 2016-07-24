//
//  HelloWorldViewController.swift
//  HelloWorld-Swift
//
//  Created by Cătălin Stan on 11/24/15.
//
//

import Criollo

class MultiRouteViewController: CRViewController {

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?, prefix: String?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil, prefix: prefix)

        self.addBlock( { (request, response, completionHandler) -> Void in
            response.setValue("text/plain", forHTTPHeaderField: "Content-type")
            response.send("Hello")
            }, forPath:"/hello")

        self.addBlock( { (request, response, completionHandler) -> Void in
            response.setValue("text/plain", forHTTPHeaderField: "Content-type")
            response.send(NSStringFromCRHTTPMethod(request.method))
            }, forPath:"/method")

        self.addViewController(HelloWorldViewController.self, withNibName: String(HelloWorldViewController.self), bundle: nil, forPath: "/hello-c", HTTPMethod: CRHTTPMethod.All, recursive: true)
        self.addController(APIController.self, forPath: "/api", HTTPMethod: CRHTTPMethod.All, recursive: true)
    }

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
