//
//  MyVC.swift
//  PrivateFileBox
//
//  Created by hankang on 2020/7/3.
//  Copyright © 2020 Greycat. All rights reserved.
//

import UIKit

class MyVC: BaseViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var table: UITableView!
    
    let titles = ["启动密码", "导入视频质量"]
    let icons = ["setting_password", "setting_video_quality"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        if let header = Bundle.main.loadNibNamed("SettingTitleView", owner: nil, options: nil)?.first as? SettingTitleView
//        {
//            header.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 170)
//            table.tableHeaderView = header
//        }
        table.dataSource = self
        table.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    //MARK: - UITableDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titles.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.init(style: UITableViewCell.CellStyle.default, reuseIdentifier: "CellIdentifier")
        cell.accessoryType = .disclosureIndicator
        cell.imageView?.image = UIImage(named: icons[indexPath.row])
        cell.textLabel?.text = titles[indexPath.row]
        return cell
    }
    
    //MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.row {
        case 0:
            self.performSegue(withIdentifier: "ShowSetPassword", sender: self)
        case 1:
            self.performSegue(withIdentifier: "ShowImportVideoQuality", sender: self)
        default:
            
            break
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
