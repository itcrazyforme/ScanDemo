//
//  DemoViewController.swift
//  ScanDemo
//
//  Created by iOS-Dev on 9/29/16.
//  Copyright © 2016 liusanchun. All rights reserved.
//

import UIKit

class DemoViewController: ScanViewController {

    // MARK: - ViewController LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Customize Method

    override func processScanResult(result: String?) {
        let alertView = UIAlertController(title: "扫描结果", message: result, preferredStyle: UIAlertControllerStyle.alert)
        alertView.addAction(UIAlertAction.init(title: "确定", style: UIAlertActionStyle.cancel, handler: { [weak self] action in
            self?.setupCamera()
        }))
        self.present(alertView, animated: true, completion: nil)
    }

}
