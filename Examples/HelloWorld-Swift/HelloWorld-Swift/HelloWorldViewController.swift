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
        self.templateVariables["TITLE"] = self.className;
        self.templateVariables["TEXT"] = request.query.description;
        return super.presentViewControllerWithRequest(request, response: response);
    }

}
