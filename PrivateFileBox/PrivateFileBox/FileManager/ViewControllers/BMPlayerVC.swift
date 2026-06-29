//
//  BMPlayerVC.swift
//  PrivateFileBox
//
//  Created by hankang on 2020/7/5.
//  Copyright © 2020 Greycat. All rights reserved.
//

import UIKit
import BMPlayer

class BMPlayerVC: BaseViewController {

    var arrayUrls : [URL] = []
    var startPlayIndex = 0
    @IBOutlet weak var player: BMPlayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        var playerItems:[BMPlayerResource] = []
        for i in 0 ..< arrayUrls.count
        {
            let playerItem = BMPlayerResource(url: arrayUrls[i], name: arrayUrls[i].lastPathComponent)
            playerItems.append(playerItem)
        }
        
        player.setVideo(resource: playerItems[startPlayIndex])

        player.backBlock = { [unowned self] (isFullScreen) in
            if isFullScreen == true { return }
            let _ = self.navigationController?.popViewController(animated: true)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
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
