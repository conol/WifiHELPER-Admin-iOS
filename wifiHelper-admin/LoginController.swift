//
//  LoginController.swift
//  wifiHelper-admin
//
//  Created by 溝田隆明 on 2017/11/14.
//  Copyright © 2017年 conol, Inc. All rights reserved.
//

import UIKit
import WifiHelper

class LoginController: UIViewController, WifiHelperDelegate
{
    var wifihelper:WifiHelper?
    
    @IBOutlet var logoView: UIImageView!
    @IBOutlet var inputEmail: UITextField!
    @IBOutlet var inputPassWord: UITextField!
    @IBOutlet var LoginButton: UIButton!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        wifihelper = WifiHelper(delegate: self)
        
        LoginButton.clipsToBounds      = true
        LoginButton.layer.cornerRadius = 4.0
        LoginButton.setBackgroundImage(UIImage.createColor("00318E", alpha: 0.2), for: .disabled)
        LoginButton.setBackgroundImage(UIImage.createColor("00318E", alpha: 1.0), for: .normal)
        
        if wifihelper!.hasToken() {
            successSignIn(response: [:])
        }
    }
    
    @IBAction func hideKeyboard()
    {
        inputEmail.resignFirstResponder()
        inputPassWord.resignFirstResponder()
    }
    
    @IBAction func doLogin()
    {
        let email = inputEmail.text!
        let pass  = inputPassWord.text!
        
        if !isValidEmailAddress(emailAddressString: email) {
            Alert.show(title: "エラー", message: "メールアドレスの形式ではありません")
            return
        }
        
        if pass.count < 6 {
            Alert.show(title: "エラー", message: "パスワードが短すぎます")
            return
        }
        
        wifihelper?.login(email: email, password: pass)
    }
    
    func successScan() {
        
    }
    
    func failedScan() {
        
    }
    
    func successSignIn(response: [String : Any])
    {
        DispatchQueue.main.async {
            let view = self.storyboard?.instantiateViewController(withIdentifier: "first")
            self.navigationController?.pushViewController(view!, animated: true)
        }
    }
    
    func failedSignIn(status: NSInteger, response: [String : Any])
    {
        Alert.show(title: "エラー", message: "ログインに失敗しました")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func isValidEmailAddress(emailAddressString: String) -> Bool
    {
        var returnValue = true
        let emailRegEx = "[A-Z0-9a-z.-_]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,3}"
        
        do {
            let regex = try NSRegularExpression(pattern: emailRegEx)
            let nsString = emailAddressString as NSString
            let results = regex.matches(in: emailAddressString, range: NSRange(location: 0, length: nsString.length))
            
            if results.count == 0
            {
                returnValue = false
            }
            
        } catch let error as NSError {
            print("invalid regex: \(error.localizedDescription)")
            returnValue = false
        }
        return  returnValue
    }

}
