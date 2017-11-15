//
//  SettingViewController.swift
//  wifiHelper-admin
//
//  Created by 溝田隆明 on 2017/11/13.
//  Copyright © 2017年 conol, Inc. All rights reserved.
//

import UIKit
import WifiHelper

class SettingViewController: UIViewController, WifiHelperDelegate
{
    var wifi:Wifi?
    var device_id:String?
    var wifihelper:WifiHelper?
    
    @IBOutlet var NFCButton: UIButton!
    @IBOutlet var InputSSID: UITextField!
    @IBOutlet var InputPASS: UITextField!
    @IBOutlet var SelectTYPE: UISegmentedControl!
    @IBOutlet var InputDAYS: PickerTextField!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        wifihelper = WifiHelper(delegate: self)
        wifihelper?.deviceId = device_id
        
        InputSSID.text = wifi?.ssid
        InputPASS.text = wifi?.pass
        var index = (wifi?.kind)! - 1
        if index < 0 {
            index = 0
        }
        SelectTYPE.selectedSegmentIndex = index
        
        var choiceDay:String? = nil
        let settingDay = wifi?.days ?? 0
        if 0 < settingDay {
            choiceDay = "\(settingDay)"
        }
        InputDAYS.text = choiceDay
        InputDAYS.setup(dataList: ["1","2","3"])
        
        NFCButton.clipsToBounds      = true
        NFCButton.layer.cornerRadius = 4.0
        NFCButton.setBackgroundImage(UIImage.createColor("00318E", alpha: 0.2), for: .disabled)
        NFCButton.setBackgroundImage(UIImage.createColor("00318E", alpha: 1.0), for: .normal)
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func hideKeyboard()
    {
        InputSSID.resignFirstResponder()
        InputPASS.resignFirstResponder()
        InputDAYS.resignFirstResponder()
    }
    
    @IBAction func startNFC()
    {
        if InputDAYS.text!.count == 0 {
            Alert.show(title: "エラー", message: "日数を選択してください")
            return
        }
        wifihelper?.wifi.ssid = InputSSID.text
        wifihelper?.wifi.pass = InputPASS.text
        wifihelper?.wifi.kind = SelectTYPE.selectedSegmentIndex + 1
        wifihelper?.wifi.days = Int(InputDAYS.text!)!
        wifihelper?.start(mode: .Write)
    }
    
    //MARK: - デリゲート
    func successScan() {
        
    }
    
    func failedScan() {
        
    }
    
    func successWrite() {
        DispatchQueue.main.async {
            let view = self.storyboard?.instantiateViewController(withIdentifier: "complate") as! ComplateController
            self.navigationController?.pushViewController(view, animated: true)
        }
    }
    
    func failedWrite() {
        Alert.show(title: "エラー", message: "書込失敗しました")
    }

}
