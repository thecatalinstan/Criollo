//
//  ViewController.swift
//  CriolloiOSApp
//
//  Created by Cătălin Stan on 27/03/16.
//  Copyright © 2016 Cătălin Stan. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var logTextView: UITextView!;

    @IBOutlet weak var statusImageItem: UIBarButtonItem!;
    @IBOutlet weak var startItem: UIBarButtonItem!;
    @IBOutlet weak var stopItem: UIBarButtonItem!;

    @IBOutlet weak var toolbar: UIToolbar!;
    @IBOutlet weak var statusDetailsButton: UILabel!;

    weak var appDelegate: AppDelegate!;
    strong var linkChecker: NSDataDetector!;

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

