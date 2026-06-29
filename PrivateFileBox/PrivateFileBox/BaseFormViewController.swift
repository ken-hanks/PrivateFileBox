//
//  BaseFormViewController.swift
//  PrivateFileBox
//
//  Created by hankang on 2020/7/4.
//  Copyright © 2020 Greycat. All rights reserved.
//

import UIKit
import KRProgressHUD
import Eureka

class BaseFormViewController: FormViewController {
    enum HudType
    {
        case success
        case warning
        case info
        case error
        case onlyText
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //定制返回按钮
        let leftItem = UIBarButtonItem.init(image: UIImage(named: "icon_back"),
                                            style: .done,
                                            target: self,
                                            action: #selector(onBtnBackClick))
        //leftItem.tintColor = UIColor.red
        self.navigationItem.leftBarButtonItem = leftItem
        
        //设置HUD显示的样式
        KRProgressHUD.set(style: .black)
        KRProgressHUD.set(duration: 2)
    }
    
    //MARK: - 显示等待提示
    func showHud(message: String)
    {
        KRProgressHUD.show(withMessage: message)
    }
    
    //MARK: - 隐藏等待提示
    func hideHud()
    {
        KRProgressHUD.dismiss()
    }
    
    //MARK: - 显示自动隐藏的提示框
    func showPop(type: HudType = .onlyText, message: String)
    {
        switch type
        {
        case .success:
            KRProgressHUD.showSuccess(withMessage: message)
        case .warning:
            KRProgressHUD.showWarning(withMessage: message)
        case .info:
            KRProgressHUD.showInfo(withMessage: message)
        case .error:
            KRProgressHUD.showError(withMessage: message)
        default:
            KRProgressHUD.showMessage(message)
        }
    }
    
    @objc func onBtnBackClick()
    {
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
