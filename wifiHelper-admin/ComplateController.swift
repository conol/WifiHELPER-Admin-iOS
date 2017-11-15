//
//  ComplateController.swift
//  wifiHelper-admin
//
//  Created by 溝田隆明 on 2017/11/14.
//  Copyright © 2017年 conol, Inc. All rights reserved.
//

import UIKit
import WifiHelper

class ComplateController: UIViewController
{
    var wifi:Wifi?
    
    @IBOutlet var SSIDLabel:UILabel!
    @IBOutlet var PASSLabel:UILabel!
    @IBOutlet var TYPELabel:UILabel!
    @IBOutlet var DAYSLabel:UILabel!
    @IBOutlet var SSIDValue:UILabel!
    @IBOutlet var PASSValue:UILabel!
    @IBOutlet var TYPEValue:UILabel!
    @IBOutlet var DAYSValue:UILabel!
    
    @IBOutlet var CompButton: UIButton!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        SSIDLabel.backgroundColor = .black
        SSIDLabel.layer.cornerRadius = 12
        SSIDLabel.textColor = .white
        SSIDLabel.clipsToBounds = true
        PASSLabel.backgroundColor = .black
        PASSLabel.layer.cornerRadius = 12
        PASSLabel.textColor = .white
        PASSLabel.clipsToBounds = true
        TYPELabel.backgroundColor = .black
        TYPELabel.layer.cornerRadius = 12
        TYPELabel.textColor = .white
        TYPELabel.clipsToBounds = true
        DAYSLabel.backgroundColor = .black
        DAYSLabel.layer.cornerRadius = 12
        DAYSLabel.textColor = .white
        DAYSLabel.clipsToBounds = true
        
        SSIDValue.text = wifi?.ssid
        PASSValue.text = wifi?.pass
        TYPEValue.text = showType((wifi?.kind)!)
        DAYSValue.text = "\((wifi?.days)!)日"

        CompButton.clipsToBounds      = true
        CompButton.layer.cornerRadius = 4.0
        CompButton.setBackgroundImage(UIImage.createColor("00318E", alpha: 0.2), for: .disabled)
        CompButton.setBackgroundImage(UIImage.createColor("00318E", alpha: 1.0), for: .normal)
    }
    
    func showType(_ type: Int) -> String
    {
        switch type {
        case 0: return "None"
        case 1: return "WPA/WPA2"
        case 2: return "WEP"
        case 3: return "None"
        default: return "None"
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func goBack()
    {
        navigationController?.popToRootViewController(animated: true)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
