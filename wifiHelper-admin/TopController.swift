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
    var jsonData: [String: Any]?
    var wifi: [String: Any]?
    
    var coronaManager: CORONAManager?
    
    @IBOutlet var logoView: UIImageView!
    @IBOutlet var NFCButton: UIButton!

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
    func coronaNFCDetected(deviceId: String, type: Int, json: String) -> Bool
    {
        if type == 1 {
            jsonData = convertToDictionary(json)
            wifi     = jsonData?["wifi"] as? [String: Any]
            
            if (wifi != nil && 1 < (wifi?.count)!) {
                changeSettingMode()
                return true
                
            } else {
                Alert.show(title: "Wi-Fi HELPER未設定", message: "タッチしたNFCにはWi-Fi HELPERの\n設定がありません")
                return false
            }
        } else {
            return false
        }
    }
    
    func coronaNFCCanceled()
    {
        let frame = logoView.frame
        UIView.animate(withDuration: 0.7, delay: 0.0, options: .curveEaseOut, animations: {
            self.logoView.frame = CGRect(x: frame.origin.x, y: frame.origin.y - 50, width: frame.size.width, height: frame.size.height)
        }) { (success) in
            
        }
    }
    
    func coronaIllegalNFCDetected()
    {
        
    }
    
    //String->NSDictionary
    func convertToDictionary(_ text: String) -> [String: Any]?
    {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    
    func changeSettingMode()
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

