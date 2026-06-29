//
//  GlobalConfig.swift
//  PrivateFileBox
//
//  Created by hankang on 2020/7/4.
//  Copyright © 2020 Greycat. All rights reserved.
//

import UIKit

class GlobalConfig: NSObject {
    
    //启动密码
    var startupPassword: String?
    
    //迷惑密码
    var fakePassword: String?
    
    //用户是否使用迷惑密码进入
    var isUserUseFakePassword: Bool = false
    
    //视频导入质量
    var videoImportQuality: Int = 0
    
    private static var _sharedInstance: GlobalConfig?
    
    //MARK: - 创建单例
    class func getInstance() -> GlobalConfig
    {
        guard let instance = _sharedInstance else {
            _sharedInstance = GlobalConfig()
            return _sharedInstance!
        }
        return instance
    }
    
    //MARK: - 必须将init设为private，以避免用户直接用init创建更多的实例
    private override init() {}
    
    //MARK: - 销毁单例
    class func destroy() {
        _sharedInstance = nil
    }
    
    //保存配置
    func saveConfig()
    {
        if let startup = startupPassword
        {
            UserDefaults.standard.set(startup, forKey: KEY_STARTUP_PASSWORD)
        }
        else
        {
            UserDefaults.standard.removeObject(forKey: KEY_STARTUP_PASSWORD)
        }
        
        if let fake = fakePassword
        {
            UserDefaults.standard.set(fake, forKey: KEY_FAKE_PASSWORD)
        }
        else
        {
            UserDefaults.standard.removeObject(forKey: KEY_FAKE_PASSWORD)
        }
        
        UserDefaults.standard.set(videoImportQuality, forKey: KEY_VIDEO_IMPORT_QUALITY)
    }
    
    //读取配置
    func loadConfig()
    {
        self.startupPassword = UserDefaults.standard.string(forKey: KEY_STARTUP_PASSWORD)
        self.fakePassword = UserDefaults.standard.string(forKey: KEY_FAKE_PASSWORD)
        self.videoImportQuality = UserDefaults.standard.integer(forKey: KEY_VIDEO_IMPORT_QUALITY)
    }
}
