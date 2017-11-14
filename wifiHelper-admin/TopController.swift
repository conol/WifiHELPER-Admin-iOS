//
//  TopController.swift
//  wifiHelper-admin
//
//  Created by 溝田隆明 on 2017/10/13.
//  Copyright © 2017年 conol, Inc. All rights reserved.
//

import UIKit
import WifiHelper

class TopController: UIViewController, WifiHelperDelegate
{
    var wifihelper:WifiHelper?
    
    @IBOutlet var logoView: UIImageView!
    @IBOutlet var NFCButton: UIButton!

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        wifihelper = WifiHelper(delegate: self)
        
        NFCButton.clipsToBounds      = true
        NFCButton.layer.cornerRadius = 4.0
        NFCButton.setBackgroundImage(UIImage.createColor("00318E", alpha: 0.2), for: .disabled)
        NFCButton.setBackgroundImage(UIImage.createColor("00318E", alpha: 1.0), for: .normal)
    }
    
    func changeSettingMode()
    {
        
    }
    
    //Button Action
    @IBAction func startNFC()
    {
        wifihelper?.start(mode: .Admin)
    }
    
    func successScan()
    {
        DispatchQueue.main.async {
            let view = self.storyboard?.instantiateViewController(withIdentifier: "setting") as! SettingViewController
            view.wifi = self.wifihelper?.wifi
            view.device_id = self.wifihelper!.deviceId
            self.navigationController?.pushViewController(view, animated: true)
        }
    }
    
    func failedScan() {
        
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }


}

