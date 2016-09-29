//
//  RootViewController.swift
//  ScanDemo
//
//  Created by iOS-Dev on 9/29/16.
//  Copyright © 2016 liusanchun. All rights reserved.
//

import UIKit

class RootViewController: UIViewController {
    
    // MARK: ViewController Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationItem.title = "扫一扫"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Event Reponse
    
    @IBAction func scanButtonTapped(sender: UIButton) {
        let viewController = DemoViewController()
        self.navigationController?.pushViewController(viewController, animated: true)
    }

}
