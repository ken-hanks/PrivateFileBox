//
//  SetPasswordVC.swift
//  PrivateFileBox
//
//  Created by hankang on 2020/7/4.
//  Copyright © 2020 Greycat. All rights reserved.
//

import UIKit
import Eureka

class SetPasswordVC: BaseFormViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let globalConfig = GlobalConfig.getInstance()
        
        var rules = RuleSet<String>()
        rules.add(rule: RuleMaxLength(maxLength: 20))

        form +++ Section(header:"启动密码", footer:"如想取消密码，直接将密码设为空即可。这个APP没有密码找回机制，忘了密码就悲剧哟。")
            <<< PasswordRow(){ row in
                row.tag = "old_password"
                row.title = "旧密码"
                row.placeholder = "请输入旧启动密码"
                row.add(ruleSet: rules)
                if globalConfig.startupPassword == nil
                {
                    row.hidden = true
                }
            }
            <<< PasswordRow(){ row in
                row.tag = "new_password"
                row.title = "新密码"
                row.placeholder = "请输入启动密码"
                row.add(ruleSet: rules)
            }
            <<< PasswordRow(){
                $0.tag = "confirm_password"
                $0.title = "重复输入"
                $0.placeholder = "再次输入启动密码"
                $0.add(ruleSet: rules)
            }
            
        if !globalConfig.isUserUseFakePassword
        {
            form +++ Section(header: "迷惑密码", footer:"迷惑敌人用的密码，用此密码进入，看不到文件")
            <<< PasswordRow(){
                $0.tag = "fake_password"
                $0.title = "迷惑密码"
                $0.placeholder = "请输入迷惑密码"
                $0.add(ruleSet: rules)
                
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    @IBAction func onBtnSaveClicked(_ sender: Any) {
        let valuesDictionary = form.values()
        let oldPassword = valuesDictionary["old_password"] as? String
        let newPassword = valuesDictionary["new_password"] as? String
        let confirmPassword = valuesDictionary["confirm_password"] as? String
        let fakePassword = valuesDictionary["fake_password"] as? String
        
        let globalConfig = GlobalConfig.getInstance()
        
        //取消密码
        if newPassword == nil, confirmPassword == nil
        {


            //如果原先设置了密码
            if let oldPassInConfig = globalConfig.startupPassword
            {
                //FORM中输入了旧密码
                if let old = oldPassword
                {
                    //FORM中的原密码和保存的不一致，报错
                    if oldPassInConfig != old
                    {
                        self.showPop(type: .error, message: "原密码输入不正确")
                        return
                    }
                    else
                    {
                        globalConfig.startupPassword = nil
                        globalConfig.saveConfig()
                    }
                }
                else
                {
                    //FORM中没有输入原密码，报错
                    self.showPop(type: .error, message: "原密码输入不正确")
                    return
                }

            }
        }
        
        //设置新密码
        if let new = newPassword, let confirm = confirmPassword
        {
            //两次密码不一致
            if new != confirm
            {
                self.showPop(type: .error, message: "两次输入的密码不一致")
                return
            }
            
            let oldPasswordInConfig: String?
            if globalConfig.isUserUseFakePassword   //如果是使用迷惑密码进入的用户
            {
                oldPasswordInConfig = globalConfig.fakePassword
            }
            else
            {
                oldPasswordInConfig = globalConfig.startupPassword
            }
            
            //如果原先设置了密码
            if let oldPassInConfig = oldPasswordInConfig
            {
                //FORM中输入了旧密码
                if let old = oldPassword
                {
                    //FORM中的原密码和保存的不一致，报错
                    if oldPassInConfig != old
                    {
                        self.showPop(type: .error, message: "原密码输入不正确")
                        return
                    }
                    else
                    {
                        if globalConfig.isUserUseFakePassword
                        {
                            globalConfig.fakePassword = new
                        }
                        else
                        {
                            globalConfig.startupPassword = new
                        }
                        globalConfig.saveConfig()
                    }
                }
                else
                {
                    //FORM中没有输入原密码，报错
                    self.showPop(type: .error, message: "原密码输入不正确")
                    return
                }
            }
            else
            {
                if globalConfig.isUserUseFakePassword
                {
                    globalConfig.fakePassword = new
                }
                else
                {
                    globalConfig.startupPassword = new
                }
                globalConfig.saveConfig()
            }
        }
        
        //如果用户设置了迷惑密码
        if let fake = fakePassword
        {
            globalConfig.fakePassword = fake
            globalConfig.saveConfig()
        }
        
        self.navigationController?.popViewController(animated: true)
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
