//
//  HelloWorldViewController.swift
//  HelloWorld-Swift
//
//  Created by Cătălin Stan on 11/24/15.
//
//

import Criollo

class MultiRouteViewController: CRViewController {

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?, prefix: String?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil, prefix: prefix)


        self.add("/hello") { (request, response, completionHandler) in
            response.setValue("text/plain", forHTTPHeaderField: "Content-type")
            response.send("Hello")
        }

        self.add("/method") { (request, response, completionHandler) in
            response.setValue("text/plain", forHTTPHeaderField: "Content-type")
            response.send(NSStringFromCRHTTPMethod(request.method))
        }

        self.add("/hello-c", viewController:HelloWorldViewController.self, withNibName: String(describing: HelloWorldViewController.self), bundle: nil)
        self.add("/api", controller:APIController.self)

        // Public folders path
        self.mount("/pub", directoryAtPath: "~", options:CRStaticDirectoryServingOptions.autoIndex)

        // Static file
        self.mount("/file.txt", fileAtPath:"/etc/hosts", options:CRStaticFileServingOptions.cache, fileName:"hosts", contentType:"text/plain", contentDisposition:CRStaticFileContentDisposition.inline)
    }

    override func present(with request: CRRequest, response: CRResponse) -> String {
        self.vars["title"] = String(describing: type(of: self))

        var text:String = String()
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
