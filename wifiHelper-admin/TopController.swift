//
//  TopController.swift
//  wifiHelper-admin
//
//  Created by 溝田隆明 on 2017/10/13.
//  Copyright © 2017年 conol, Inc. All rights reserved.
//

import UIKit
import CORONAWriter

class TopController: UIViewController, CORONAManagerDelegate
{
    var coronaManager: CORONAManager?
    @IBOutlet var NFCButton:UIButton!

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        NFCButton.clipsToBounds      = true
        NFCButton.layer.cornerRadius = 4.0
        NFCButton.setBackgroundImage(UIImage.createColor("00318E", alpha: 0.2), for: .disabled)
        NFCButton.setBackgroundImage(UIImage.createColor("00318E", alpha: 1.0), for: .normal)
        
        coronaManager = CORONAManager(delegate: self)
    }
    
    //CORONA Delegate
    func coronaNFCDetected(deviceId: Data, serviceId: Data) -> Bool
    {
        return true
    }
    
    func coronaNFCCanceled()
    {
        
    }
    
    func coronaIllegalNFCDetected()
    {
        
    }
    
    //Button Action
    @IBAction func startNFC()
    {
        coronaManager?.startReadingNFC()
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }


}

