//
//  ScanViewController.swift
//  CommunityApp
//
//  Created by iOS-Dev on 9/29/16.
//  Copyright © 2016 liusanchun. All rights reserved.
//

import UIKit
import AVFoundation

enum Direction {
    case Up, Down
}

private struct Action {
    static let scanLinePositionChanged = #selector(ScanViewController.scanLinePositionChanged)
    static let flashStatusChanged = #selector(ScanViewController.flashStatusChanged(sender:))
    static let backButtonTapped = #selector(ScanViewController.backButtonTapped(sender:))
}

class ScanViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    static let SCREEN_WIDTH: CGFloat = UIScreen.main.bounds.width
    static let SCREEN_HEIGHT: CGFloat = UIScreen.main.bounds.height

    // MARK: - Property
    
    var device: AVCaptureDevice?
    var input: AVCaptureDeviceInput?
    var output: AVCaptureMetadataOutput?
    var session: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    var backButton: UIButton?
    var flashButton: UIButton?
    var scanLineImageView: UIImageView?
    var imageView: UIImageView?
    
    var direction: Direction = Direction.Down
    var number: Int = 0
    var flash: Bool = false
    
    var timer: Timer?
    
    // MARK: - ViewController Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupView()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
        self.setupCamera()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.isNavigationBarHidden = false
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Event Response
    
    @IBAction func flashStatusChanged(sender: UIButton) {
        if self.flash {
            self.closeFlashFlight()
            self.flash = false
        } else {
            self.openFlashFlight()
            self.flash = true
        }
    }
    
    @IBAction func backButtonTapped(sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Customize Method
    
    func setupView() {
        self.navigationItem.title = "扫一扫"
        self.view.backgroundColor = UIColor.white
        let width = self.view.center.x + 30.0
        
        self.backButton = UIButton(type: UIButtonType.custom)
        self.backButton?.setImage(UIImage(named: "icon_nav_back"), for: UIControlState.normal)
        self.backButton?.setImage(UIImage(named: "icon_nav_back"), for: UIControlState.selected)
        self.backButton?.frame = CGRect(x: 0.0, y: 20.0, width: 44.0, height: 44.0)
        self.backButton?.addTarget(self, action: Action.backButtonTapped, for: UIControlEvents.touchUpInside)
        self.view.addSubview(self.backButton!)
        
        self.flashButton = UIButton(type: UIButtonType.custom)
        self.flashButton?.setImage(UIImage(named: "icon_flash_normal"), for: UIControlState.normal)
        self.flashButton?.setImage(UIImage(named: "icon_flash_selected"), for: UIControlState.selected)
        self.flashButton?.frame = CGRect(x: ScanViewController.SCREEN_WIDTH - 44.0, y: 20.0, width: 44.0, height: 44.0)
        self.flashButton?.addTarget(self, action: Action.flashStatusChanged, for: UIControlEvents.touchUpInside)
        self.view.addSubview(self.flashButton!)
        
        self.imageView = UIImageView(frame: CGRect(x: ( ScanViewController.SCREEN_WIDTH - width ) / 2.0, y: ( ScanViewController.SCREEN_HEIGHT - width ) / 2.0, width: width, height: width))
        self.imageView?.image = UIImage(named: "icon_scan_bg")
        
        self.view.addSubview(self.imageView!)
        
        self.scanLineImageView = UIImageView(frame: CGRect(x: (imageView?.frame.minX)! + 5.0, y: (imageView?.frame.minY)! + 5.0, width: width + 10.0, height: 1.0))
        self.scanLineImageView?.image = UIImage(named: "icon_scan_line")
        self.view.addSubview(self.scanLineImageView!)
        
        let introductionLabel = UILabel(frame: CGRect(x: 15.0, y: ScanViewController.SCREEN_HEIGHT - 100.0, width: ScanViewController.SCREEN_WIDTH - 30.0, height: 20.0))
        introductionLabel.text = "将扫描框对准二维码，即可扫描"
        introductionLabel.textAlignment = NSTextAlignment.center
        introductionLabel.textColor = UIColor.white
        introductionLabel.font = UIFont.systemFont(ofSize: 14.0)
        self.view.addSubview(introductionLabel)
    }
    
    func scanLinePositionChanged() {
        self.timer = Timer.scheduledTimer(timeInterval: 0.02, target: self, selector: Action.scanLinePositionChanged, userInfo: nil, repeats: true)
        let width = self.view.center.x + 30.0
        if self.direction == .Down {
            self.number += 1
            self.scanLineImageView?.frame = CGRect(x: (self.imageView?.frame.minX)! + 5.0, y: (self.imageView?.frame.minY)! + 5.0 + CGFloat(2 * self.number), width: width, height: 1.0)
            if self.number == Int( (width - 10) / 2 ) {
                self.direction = .Up
            }
        } else {
            self.number -= 1
            self.scanLineImageView?.frame = CGRect(x: (self.imageView?.frame.minX)! + 5.0, y: (self.imageView?.frame.minY)! + 5.0 + CGFloat(2 * self.number), width: width, height: 1.0)
            if self.number == 0 {
                self.direction = .Down
            }
        }
    }
    
    func setupCamera() {
        let authStatus = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeAudio)
        if authStatus == AVAuthorizationStatus.notDetermined {
            print("未授权")
            return
        }
        if authStatus == AVAuthorizationStatus.denied || authStatus == AVAuthorizationStatus.restricted {
            print("不具有相机权限")
            return
        }
        
        self.device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        do {
            self.input = try AVCaptureDeviceInput(device: self.device)
            self.output = AVCaptureMetadataOutput()
            
            self.output?.rectOfInterest = self.scanViewRect(rect: (self.imageView?.frame)!)
            
            self.session = AVCaptureSession()
            self.session?.sessionPreset = AVCaptureSessionPresetHigh
            
            if (self.session?.canAddInput(self.input))! {
                self.session?.addInput(self.input)
            }
            if (self.session?.canAddOutput(self.output))! {
                self.session?.addOutput(self.output)
                self.output?.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                self.output?.metadataObjectTypes = [
                    AVMetadataObjectTypeEAN13Code,
                    AVMetadataObjectTypeEAN8Code,
                    AVMetadataObjectTypeCode128Code,
                    AVMetadataObjectTypeQRCode
                ]
                
            }
            if self.previewLayer != nil {
                self.previewLayer?.removeFromSuperlayer()
                self.previewLayer = nil
            }
            self.previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
            self.previewLayer?.videoGravity = AVLayerVideoGravityResize
            self.previewLayer?.frame = self.view.bounds
            self.view.layer.insertSublayer(self.previewLayer!, at: 0)
            
            self.session?.startRunning()
        } catch {
            print("异常了")
        }
    }
    
    func stopReading() {
        self.session?.stopRunning()
        self.session = nil
        self.timer?.invalidate()
    }
    
    private func scanViewRect(rect: CGRect) -> CGRect {
        let width = self.view.frame.width
        let height = self.view.frame.height
        
        let x = ( height - rect.height ) / 2.0 / height
        let y = ( width - rect.width ) / 2.0 / width
        
        let w = rect.height / height
        let h = rect.width / width
        
        return CGRect(x: x, y: y, width: w, height: h)
    }
    
    private func openFlashFlight() {
        do {
            if (self.device?.hasTorch)! {
                try self.device?.lockForConfiguration()
                self.device?.torchMode = AVCaptureTorchMode.on
                self.device?.unlockForConfiguration()
            }
        } catch {
            print("异常了")
        }
        
    }
    
    private func closeFlashFlight() {
        do {
            if (self.device?.hasTorch)! {
                try self.device?.lockForConfiguration()
                self.device?.torchMode = AVCaptureTorchMode.off
                self.device?.unlockForConfiguration()
            }
        } catch {
            print("异常了")
        }
    }
    
    func processScanResult(result: String?) {
        print("result is \(result!)")
    }
    
    // MARK: - AVCaptureMetadataOutputObjectsDelegate
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        var result: String?
        if metadataObjects.count > 0 {
            let metaDataObject = metadataObjects.first as! AVMetadataMachineReadableCodeObject
            result = metaDataObject.stringValue
        }
        self.processScanResult(result: result)
        self.stopReading()
    }

}
