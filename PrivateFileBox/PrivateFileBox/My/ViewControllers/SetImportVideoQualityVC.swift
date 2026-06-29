//
//  SetImportVideoQualityVC.swift
//  PrivateFileBox
//
//  Created by hankang on 2020/7/5.
//  Copyright © 2020 Greycat. All rights reserved.
//

import UIKit
import Eureka

class SetImportVideoQualityVC: BaseFormViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let globalConfig = GlobalConfig.getInstance()
        let options = ["低质量（最快）", "中质量", "高质量（最慢）"]
        let curIndex = globalConfig.videoImportQuality

        
        form +++ Section("请点击选择")

        <<< ActionSheetRow<String>() {
            $0.title = "导入质量"
            $0.selectorTitle = "请选择导入质量"
            $0.options = options
            $0.value = options[curIndex]
            }
        .onPresent { from, to in
                to.popoverPresentationController?.permittedArrowDirections = .up
            }
        .onChange({ (row) in
            let globalConfig = GlobalConfig.getInstance()
            switch row.value
            {
            case "低质量（最快）":
                globalConfig.videoImportQuality = 0
            case "中质量":
                globalConfig.videoImportQuality = 1
            case "高质量（最慢）":
                globalConfig.videoImportQuality = 2
            default:
                break
            }
            globalConfig.saveConfig()
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
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
