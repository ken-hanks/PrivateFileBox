//
//  PassVC.swift
//  PrivateFileBox
//
//  Created by hankang on 2020/7/4.
//  Copyright © 2020 Greycat. All rights reserved.
//

import UIKit

protocol PassVCDelegate : NSObjectProtocol {
    func accessGranted(isFakePassword: Bool)
}

class PassVC: BaseViewController {

    @IBOutlet weak var textPassword: UITextField!
    @IBOutlet weak var btnEnter: UIButton!
    
    weak var delegate: PassVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        btnEnter.addTarget(self, action: #selector(onBtnEnterClicked), for: .touchUpInside)
    }
    

    @objc func onBtnEnterClicked()
    {
        let globalConfig = GlobalConfig.getInstance()
        
        if let input = textPassword.text, let pass = globalConfig.startupPassword
        {
            //用户用真实密码进入
            if input == pass
            {
                self.delegate?.accessGranted(isFakePassword: false)
                self.dismiss(animated: true) {
                    
                }
            }
            else if let fake = globalConfig.fakePassword
            {
                //用户用迷惑密码进入
                if input == fake
                {
                    globalConfig.isUserUseFakePassword = true
                    self.delegate?.accessGranted(isFakePassword: true)
                    self.dismiss(animated: true) {
                        
                    }
                }
            }
            else
            {
                self.showPop(type: .error, message: "密码不正确")
            }
        }
        
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
