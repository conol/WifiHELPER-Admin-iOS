//
//  ComplateController.swift
//  wifiHelper-admin
//
//  Created by 溝田隆明 on 2017/11/14.
//  Copyright © 2017年 conol, Inc. All rights reserved.
//

import UIKit

class ComplateController: UIViewController {

    @IBOutlet var CompButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        CompButton.clipsToBounds      = true
        CompButton.layer.cornerRadius = 4.0
        CompButton.setBackgroundImage(UIImage.createColor("00318E", alpha: 0.2), for: .disabled)
        CompButton.setBackgroundImage(UIImage.createColor("00318E", alpha: 1.0), for: .normal)
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
