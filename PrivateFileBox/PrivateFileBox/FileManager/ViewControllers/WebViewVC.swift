//
//  WebViewVC.swift
//  PrivateFileBox
//
//  Created by hankang on 2020/7/4.
//  Copyright © 2020 Greycat. All rights reserved.
//

import UIKit
import WebKit

class WebViewVC: BaseViewController {

    @IBOutlet weak var webkit: WKWebView!
    
    var url: URL?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let destUrl = url
        {
            webkit.loadFileURL(destUrl, allowingReadAccessTo: destUrl)
        }
    }
    
    @IBAction func onBtnShareClicked(_ sender: Any) {
        let activityVC = UIActivityViewController(activityItems: [url!], applicationActivities: nil)
        self.present(activityVC, animated: true) {
            
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
