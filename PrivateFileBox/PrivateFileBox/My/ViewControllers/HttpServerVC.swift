//
//  HttpServerVC.swift
//  PrivateFileBox
//
//  Created by hankang on 2020/7/3.
//  Copyright © 2020 Greycat. All rights reserved.
//

import UIKit
import GCDWebServer
import CoreTelephony
import CDAlertView

class HttpServerVC: BaseViewController {

    @IBOutlet weak var labelMessage: UILabel!
    @IBOutlet weak var labelAddress: UILabel!
    
    var webUploader: GCDWebUploader!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.startWebService()
//        let isNetworkReachable = isConnectedToNetwork()
//        if isNetworkReachable
//        {
//            self.startWebService()
//        }
//        else
//        {
//            let alert = CDAlertView(title: "网络无法连通", message: "请检查您的WI-FI开关是否打开，并检查是否在iOS系统设置中打开了APP的WI-FI数据访问权限", type: .error)
//
//            let yesAction = CDAlertViewAction(title: "关闭", handler: { action->Bool in
//
//                return true;
//            })
//            alert.add(action: yesAction)
//            alert.show()
//        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func onBtnBackClick()
    {
        webUploader.stop()
        self.navigationController?.popViewController(animated: true)
    }

    func startWebService()
    {
        let manager = FileManager.default
        let urlForDocument = manager.urls(for: .documentDirectory, in:.userDomainMask)
        let url = urlForDocument[0]
        webUploader = GCDWebUploader.init(uploadDirectory: url.path)
        let port = Int.randomIntNumber(lower: 1000, upper: 9999)
        webUploader.start(withPort: UInt(port), bonjourName: nil)
        labelAddress.text = webUploader.serverURL?.absoluteString
    }
    

    func openEventServiceWithBolck(action :@escaping ((Bool)->())) {
        let cellularData = CTCellularData()
        cellularData.cellularDataRestrictionDidUpdateNotifier = { (state) in
            if state == CTCellularDataRestrictedState.restrictedStateUnknown ||  state == CTCellularDataRestrictedState.notRestricted {
                action(false)
            } else {
                action(true)
            }
        }
        let state = cellularData.restrictedState
        if state == CTCellularDataRestrictedState.restrictedStateUnknown ||  state == CTCellularDataRestrictedState.notRestricted {
            action(false)
        } else {
            action(true)
        }
    }
    
//    func isConnectedToNetwork()->Bool
//    {
//
//        var Status:Bool = false
//
//        let url = URL(string: "http://www.baidu.com/")
//
//        var request = URLRequest(url:url!)
//
//        request.httpMethod = "HEAD"
//
//        request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData
//
//        request.timeoutInterval = 10.0
//
//        var response: URLResponse?
//
//        var data = try? NSURLConnection.sendSynchronousRequest(request, returning: &response) as NSData?
//
//
//        if let httpResponse = response as? HTTPURLResponse {
//
//            if httpResponse.statusCode == 200 {
//
//                Status = true
//
//            }
//
//        }
//
//        return Status
//
//    }
     
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
}

public extension Int {
    /*这是一个内置函数
     lower : 内置为 0，可根据自己要获取的随机数进行修改。
     upper : 内置为 UInt32.max 的最大值，这里防止转化越界，造成的崩溃。
     返回的结果： [lower,upper) 之间的半开半闭区间的数。
     */
    static func randomIntNumber(lower: Int = 0,upper: Int = Int(UInt32.max)) -> Int {
        return lower + Int(arc4random_uniform(UInt32(upper - lower)))
    }
    /**
     生成某个区间的随机数
     */
    static func randomIntNumber(range: Range<Int>) -> Int {
        return randomIntNumber(lower: range.lowerBound, upper: range.upperBound)
    }
}
