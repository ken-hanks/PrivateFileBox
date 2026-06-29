//
//  HomeVC.swift
//  PrivateFileBox
//
//  Created by hankang on 2020/6/25.
//  Copyright © 2020 Greycat. All rights reserved.
//

import UIKit
import Photos
//import TBDropdownMenu
import AssetsPickerViewController
import CDAlertView
import FTPopOverMenu_Swift
import collection_view_layouts
import Kingfisher
import ZWAlertController
import SKPhotoBrowser
import TYProgressBar


class HomeVC: BaseViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout,
UIImagePickerControllerDelegate, UINavigationControllerDelegate, AssetsPickerViewControllerDelegate,
LayoutDelegate, PassVCDelegate{

    @IBOutlet var collectMain: UICollectionView!
    @IBOutlet var viewPad: UIView!
    @IBOutlet var bottomCollectionMain: NSLayoutConstraint!
    @IBOutlet var bottomViewPad: NSLayoutConstraint!
    
    @IBOutlet var btnDelete: UIButton!
    @IBOutlet var btnSelectAll: UIButton!

    
    let CELL_WIDTH = 110
    let CELL_HEIGHT = 120
    let progressBar = TYProgressBar()
    
    var assets = [PHAsset]()
    var stackPath : [URL] = []
    var arrayContents: [FileItem] = []
    var arrayDirectories: [FileItem] = []
    var arrayFiles : [FileItem] = []
    
    //排序方式，0:名称; 1:时间
    var sortType = 0
    
    var arrayVideo : [URL] = []
    var startPlayVideoIndex = 0
    
    //是否是选择莫谁
    var isSelectMode = false
    
    //导入队列中拷贝完成的文件数
    var copyedFileCount = 0
    
    //导入队列中的文件总数
    var totalImportFileCount = 0
    
    //当前被选中的文本文件、网页文件的序号
    var curWebFileIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(appResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        
        btnSelectAll.addTarget(self, action: #selector(onBtnSelectAllClicked), for: .touchUpInside)
        btnDelete.addTarget(self, action: #selector(onBtnDeleteClicked), for: .touchUpInside)
        
        collectMain.dataSource = self;
        collectMain.delegate = self;
        
        let longPressGesture = UILongPressGestureRecognizer.init(target: self, action: #selector(onCollectionLongPressed))
        collectMain.addGestureRecognizer(longPressGesture)
        setupCollectionViewLayout()
        
        progressBar.frame = CGRect(x: 0, y: 0, width: 180, height: 180)
        progressBar.center = self.view.center
        progressBar.isHidden = true
        //progressBar.gradients = [UIColor.red, UIColor.yellow]
        progressBar.textColor = .systemBlue
        progressBar.font = UIFont(name: "HelveticaNeue-Medium", size: 17)!
        progressBar.lineDashPattern = [4, 10]   // lineWidth, lineGap
        progressBar.lineHeight = 16
        self.view.addSubview(progressBar)
        
        let globalConfig = GlobalConfig.getInstance()
        globalConfig.loadConfig()
        if globalConfig.startupPassword != nil
        {
            //弹出登录窗口
            self.performSegue(withIdentifier: "PresentPass", sender: self)
        }
        else
        {
            let manager = FileManager.default
            let urlForDocument = manager.urls(for: .documentDirectory, in:.userDomainMask)
            let url = urlForDocument[0]
            enterFolder(url: url)
        }

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    //MARK: - 设置UICollectionView的Layout
    func setupCollectionViewLayout()
    {
        let layout: BaseLayout = TagsLayout()

        layout.delegate = self
        layout.contentPadding = ItemsPadding(horizontal: 10, vertical: 10)
        layout.cellsPadding = ItemsPadding(horizontal: 8, vertical: 8)

        collectMain.collectionViewLayout = layout
    }

    //MARK: - LayoutDelegate
    func cellSize(indexPath: IndexPath) -> CGSize {
        return CGSize(width:CELL_WIDTH, height:CELL_HEIGHT)
    }
    
    //MARK: - PassVCDelegate
    func accessGranted(isFakePassword: Bool) {
        let manager = FileManager.default
        let urlForDocument:[URL]
        if isFakePassword
        {
            //urlForDocument = manager.urls(for: .libraryDirectory, in:.userDomainMask)
            urlForDocument = [URL(fileURLWithPath: NSTemporaryDirectory())]
        }
        else
        {
            urlForDocument = manager.urls(for: .documentDirectory, in:.userDomainMask)
        }
        let url = urlForDocument[0]
        enterFolder(url: url)
    }
    
    //MARK: - 列举目录中的文件及子目录
    func enumerateDir(_ url: URL) {
        let manager = FileManager.default
        
        //let contentsOfPath = try? manager.contentsOfDirectory(atPath: url.path!)
        let resKeys = [URLResourceKey.nameKey, URLResourceKey.isDirectoryKey]
        let contentsOfPath = try? manager.contentsOfDirectory(at: url as URL, includingPropertiesForKeys: resKeys)
        //清空原有的目录文件记录
        arrayContents.removeAll()
        arrayDirectories.removeAll()
        arrayFiles.removeAll()
        
        //print("contentsOfPath: \(contentsOfPath ?? [])")
        if let urls = contentsOfPath
        {
            let setKeys: Set<URLResourceKey> = [URLResourceKey.nameKey, URLResourceKey.isDirectoryKey, URLResourceKey.contentModificationDateKey]
            for url in urls
            {
                let resValues = try? url.resourceValues(forKeys: setKeys)
                let isDirectory = resValues?.isDirectory ?? false
                let name = resValues?.name
                let date = resValues?.contentModificationDate
                let item = FileItem(url: url, isDirectory: isDirectory, name: name ?? "", date: date ?? Date(timeIntervalSince1970: 0))
                
                if isDirectory
                {
                    arrayDirectories.append(item)
                }
                else
                {
                    arrayFiles.append(item)
                }
            }
            
            if self.sortType == 0
            {
                arrayDirectories.sort { (item1, item2) -> Bool in
                    return item1.name < item2.name ? true : false
                }
                arrayFiles.sort { (item1, item2) -> Bool in
                    return item1.name < item2.name ? true : false
                }
            }
            else if self.sortType == 1
            {
                arrayDirectories.sort { (item1, item2) -> Bool in
                    return item1.modifyDate > item2.modifyDate ? true : false
                }
                arrayFiles.sort { (item1, item2) -> Bool in
                    return item1.modifyDate > item2.modifyDate ? true : false
                }
            }
            arrayContents = arrayDirectories + arrayFiles
        }
    }
    
    //MARK: - 进入目录
    func enterFolder(url:URL)
    {
        //如果是初始目录，则不允许退回上一级
        self.navigationItem.leftBarButtonItem?.isEnabled = !(stackPath.count == 0)
        stackPath.append(url)
        enumerateDir(url)
        collectMain.reloadData()
    }
    
    //MARK: - 刷新当前目录
    func refreshFolder(refreshUI: Bool = true)
    {
        if let url = stackPath.last
        {
            enumerateDir(url)
            
            if refreshUI
            {
                collectMain.reloadData()
            }
        }
    }
    
    //MARK: - 弹出创建目录对话框
    func beginCreateFolder()
    {
        let title = "创建文件夹"
        let message = "请输入文件夹的名字"
        let cancelButtonTitle = "取消"
        let otherButtonTitle = "确定"
        
        let alertController = ZWAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.textLimit = 30  // == 限制10个中文字符 limit 10 Chinese characters, equal to 30 English characters
        // Add the text field for text entry.
        alertController.addTextFieldWithConfigurationHandler { textField in
            // If you need to customize the text field, you can ZW so here.
            textField?.textColor = UIColor.black
            textField?.leftView = UIView.init(frame: CGRect(x: 0, y: 0, width: 10, height: textField!.frame.size.height))
            textField?.leftViewMode = .always
        }
        
        // Create the actions.
        let cancelAction = ZWAlertAction(title: cancelButtonTitle, style: .cancel) { action in
        }
        
        let otherAction = ZWAlertAction(title: otherButtonTitle, style: .default) { action in
            if let name = alertController.textFields?.first?.text , let baseUrl = self.stackPath.last as NSURL?
            {
                self.createFolder(name: name, baseUrl: baseUrl)
                self.refreshFolder()
            }
            
        }
        
        // Add the actions.
        alertController.addAction(cancelAction)
        alertController.addAction(otherAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    //MARK: - 创建目录
    func createFolder(name:String, baseUrl:NSURL) {
        
        let manager = FileManager.default
        
        let folder = baseUrl.appendingPathComponent(name, isDirectory: true)
        
        let exist = manager.fileExists(atPath: folder!.path)
        
        if !exist {
            try! manager.createDirectory(at: folder!, withIntermediateDirectories: true, attributes: nil)
            
        }
        
    }

    
    //MARK: - UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return arrayContents.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: ItemCell = collectionView.dequeueReusableCell(withReuseIdentifier: "ItemCell", for: indexPath) as! ItemCell
        
        if indexPath.row < arrayContents.count
        {
            let fileItem = arrayContents[indexPath.row]
            cell.labelName.text = fileItem.name
            cell.ivPlay.isHidden = true
            switch fileItem.type
            {
            case .directory:
                cell.ivThumbnail.image = UIImage(named:"icon_folder")
            case .videoFile:
                if let thumbnail = getThumbnailFrom(path: fileItem.url)
                {
                    cell.ivThumbnail.image = thumbnail
                    cell.ivPlay.isHidden = false
                }
                else
                {
                    cell.ivThumbnail.image = UIImage(named:"icon_video")
                }
            case .textFile:
                cell.ivThumbnail.image = UIImage(named:"icon_text")
            case .imageFile:
                cell.ivThumbnail.kf.setImage(with: fileItem.url)
            case .codeFile:
                cell.ivThumbnail.image = UIImage(named:"icon_code")
            case .wordFile:
                cell.ivThumbnail.image = UIImage(named:"icon_word")
            case .excelFile:
                cell.ivThumbnail.image = UIImage(named:"icon_excel")
            case .pdfFile:
                cell.ivThumbnail.image = UIImage(named:"icon_pdf")
            default:
                cell.ivThumbnail.image = UIImage(named:"icon_unknown_file")
                break
            }
            
            cell.ivCheckBox.isHidden = !isSelectMode
            if isSelectMode
            {
                if fileItem.isSelected
                {
                    cell.ivCheckBox.image = UIImage(named: "icon_checkbox_selected")
                }
                else
                {
                    cell.ivCheckBox.image = UIImage(named: "icon_checkbox")
                }
            }
        }

        return cell
    }
    
    //MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = arrayContents[indexPath.row]
        
        if isSelectMode
        {
            arrayContents[indexPath.row].isSelected = !arrayContents[indexPath.row].isSelected
            collectMain.reloadItems(at: [indexPath])
        }
        else
        {
            switch item.type
            {
            case .directory:
                enterFolder(url: item.url)
            case .videoFile:
                playVideo(startIndex: indexPath.row)
            case .imageFile:
                showImageViewer(startIndex: indexPath.row)
            case .textFile:
                fallthrough
            case .wordFile:
                fallthrough
            case .excelFile:
                fallthrough
            case .webPage:
                fallthrough
            case .pdfFile:
                fallthrough
            case .codeFile:
                curWebFileIndex = indexPath.row
                self.performSegue(withIdentifier: "ShowWebView", sender: self)
            default:
                break
            }
        }
        
    }
    
    //MARK: - 导航栏左按钮被点击的处理
    @objc override func onBtnBackClick() {
        if isSelectMode
        {
            //如果处于选择状态，先退出选择状态
            switchSelectionMode()
        }
        
        stackPath.removeLast()
        if let url = stackPath.last
        {
            self.navigationItem.leftBarButtonItem?.isEnabled = !(stackPath.count == 1)
            enumerateDir(url)
            collectMain.reloadData()
        }
    }
    
    //MARK: - 刷新按钮被点击的处理
    @IBAction func onBtnRefreshClicked(_ sender: Any) {
        refreshFolder()
    }
   
    //MARK: - 排序按钮被点击的处理
    @IBAction func onBtnSortClicked(_ sender: UIBarButtonItem, event: UIEvent) {
        let menuModelArray : [FTPopOverMenuModel] = [FTPopOverMenuModel(title: "按名称排序", image: "", selected: self.sortType == 0),
                                                     FTPopOverMenuModel(title: "按时间排序", image: "", selected: self.sortType == 1)]
        let config = FTConfiguration()
        config.backgoundTintColor = UIColor.white
        config.borderColor = UIColor.lightGray
        config.menuWidth = 150
        config.menuSeparatorColor = UIColor.lightGray
        config.menuRowHeight = 50
        config.cornerRadius = 6
        config.textColor = UIColor.gray
        config.textAlignment = NSTextAlignment.center
        config.selectedTextColor = .systemBlue
        config.selectedCellBackgroundColor = UIColor.white
        
        FTPopOverMenu.showForEvent(event: event,
                                   with: menuModelArray,
                                   config: config,
                                   done: { (selectedIndex) -> () in
                                    self.sortType = selectedIndex
                                    self.refreshFolder()
                                    
        },
                                   cancel: {
                                    
        })
    }
    
    //MARK: - 导航栏右按钮被点击的处理
    var selectedIndex : NSInteger = 0
    @IBAction func onBtnRightClicked(_ sender: UIBarButtonItem, event: UIEvent) {
        
        let menuModelArray : [FTPopOverMenuModel] = [FTPopOverMenuModel(title: "导入本机照片", image: "", selected: self.selectedIndex == 0),
                                                     FTPopOverMenuModel(title: "导入本机视频", image: "", selected: self.selectedIndex == 1),
                                                     FTPopOverMenuModel(title: "WIFI传输文件", image: "", selected: self.selectedIndex == 2),
                                                     FTPopOverMenuModel(title: "创建目录", image: "", selected: self.selectedIndex == 3),
                                                     FTPopOverMenuModel(title: "选择", image: "", selected: self.selectedIndex == 4)]

        
        let config = FTConfiguration()
        config.backgoundTintColor = UIColor.white
        config.borderColor = UIColor.lightGray
        config.menuWidth = 150
        config.menuSeparatorColor = UIColor.lightGray
        config.menuRowHeight = 50
        config.cornerRadius = 6
        config.textColor = UIColor.black
        config.textAlignment = NSTextAlignment.center
        config.selectedTextColor = UIColor.black
        config.selectedCellBackgroundColor = UIColor.white
        
        FTPopOverMenu.showForEvent(event: event,
                                   with: menuModelArray,
                                   config: config,
                                   done: { (selectedIndex) -> () in
                                    self.selectedIndex = selectedIndex
                                    switch self.selectedIndex
                                    {
                                    case 0:
                                        self.popPhotoPicker()
                                    case 1:
                                        self.popVideoPicker()
                                    case 2:
                                        self.performSegue(withIdentifier: "ShowHttpServer", sender: self)
                                    case 3:
                                        self.beginCreateFolder()
                                    case 4:
                                        self.switchSelectionMode()
                                    default:
                                        break
                                    }
                                    
        },
                                   cancel: {
                                    
        })
    }
    
    //MARK: - 弹出相册选择界面（选择照片）
    func popPhotoPicker()
    {
//        let photoPicker =  UIImagePickerController()
//        photoPicker.delegate = self
//        photoPicker.allowsEditing = true
//        photoPicker.sourceType = .photoLibrary
//
//        //在需要的地方present出来
//        self.present(photoPicker, animated: true, completion: nil)
        

        let picker = AssetsPickerViewController()
        picker.isShowLog = false
        picker.pickerDelegate = self

        let pickerConfig = AssetsPickerConfig()
        let options = PHFetchOptions()
        
        //只显示图片资源
        options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        pickerConfig.assetFetchOptions = [
            .smartAlbum: options,
            .album: options
        ]
        picker.pickerConfig = pickerConfig
        present(picker, animated: true, completion: nil)
    }
    
    //MARK: - 弹出相册选择界面（选择视频）
    func popVideoPicker()
    {
        let picker = AssetsPickerViewController()
        picker.isShowLog = false
        picker.pickerDelegate = self

        let pickerConfig = AssetsPickerConfig()
        let options = PHFetchOptions()
        
        //只显示视频资源
        options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
        pickerConfig.assetFetchOptions = [
            .smartAlbum: options,
            .album: options
        ]
        picker.pickerConfig = pickerConfig
        present(picker, animated: true, completion: nil)
    }
    
    //MARK: - AssetsPickerViewControllerDelegate
    func assetsPickerCannotAccessPhotoLibrary(controller: AssetsPickerViewController) {
        logw("Need permission to access photo library.")
    }
    
    func assetsPickerDidCancel(controller: AssetsPickerViewController) {
        logi("Cancelled.")
    }
    
    func assetsPicker(controller: AssetsPickerViewController, selected assets: [PHAsset]) {
        if let asset = assets.first
        {
            let mediaType: String
            if asset.mediaType == .video
            {
                mediaType = "段视频"
            }
            else if asset.mediaType == .image
            {
                mediaType = "张照片"
            }
            else
            {
                mediaType = "个文件"
            }
            let msg = String(format: "将这%d%@导入到当前文件夹吗？", assets.count, mediaType);
            let alert = CDAlertView(title: "确认导入", message: msg, type: .notification)
            let noAction = CDAlertViewAction(title: "算了", handler: { action->Bool in
                return true;
            })
            alert.add(action: noAction)
            let yesAction = CDAlertViewAction(title: "确定", handler: { action->Bool in
                if asset.mediaType == .video
                {
                    self.importVideoAssets()
                }
                else
                {
                    self.importImageAssets()
                }
                return true;
            })
            alert.add(action: yesAction)
            alert.show()
            
            self.assets = assets
        }

    }
    
    func assetsPicker(controller: AssetsPickerViewController, shouldSelect asset: PHAsset, at indexPath: IndexPath) -> Bool {
        logi("shouldSelect: \(indexPath.row)")
        
        // can limit selection count
        if controller.selectedAssets.count > 3 {
            // do your job here
        }
        return true
    }
    
    func assetsPicker(controller: AssetsPickerViewController, didSelect asset: PHAsset, at indexPath: IndexPath) {
        logi("didSelect: \(indexPath.row)")
    }
    
    func assetsPicker(controller: AssetsPickerViewController, shouldDeselect asset: PHAsset, at indexPath: IndexPath) -> Bool {
        logi("shouldDeselect: \(indexPath.row)")
        return true
    }
    
    func assetsPicker(controller: AssetsPickerViewController, didDeselect asset: PHAsset, at indexPath: IndexPath) {
        logi("didDeselect: \(indexPath.row)")
    }
    
    func assetsPicker(controller: AssetsPickerViewController, didDismissByCancelling byCancel: Bool) {
        logi("dismiss completed - byCancel: \(byCancel)")
    }
    

    
    //MARK: - 导入照片资源
    func importImageAssets()
    {
        totalImportFileCount = self.assets.count
        copyedFileCount = 0
        progressBar.progress = 0
        progressBar.isHidden = false
        
        for asset in self.assets
        {
            saveImage(asset: asset)
        }
    }
    
    //MARK: - 导入视频资源
    func importVideoAssets()
    {
        totalImportFileCount = self.assets.count
        copyedFileCount = 0
        self.showHud(message: "正在导入，请稍候...")
        for asset in self.assets
        {
            saveVideo(asset: asset)
        }
    }
    
    //MARK: - 将指定的asset保存到当前目录下
    /**
        Param:
            asset: asset对象
     */
    func saveImage(asset: PHAsset)
    {
        let fileManager = FileManager.default
        let manager = PHImageManager.default()
        
        let imageOptions = PHImageRequestOptions()
        imageOptions.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
        imageOptions.isNetworkAccessAllowed = true

        var imageName: String? = nil
        let resources = PHAssetResource.assetResources(for: asset)
        if let resource = resources.first(where: { $0.type == .photo }) ?? resources.first {
            imageName = resource.originalFilename
        }
        
        if imageName == nil {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
            let dateString = dateFormatter.string(from: asset.creationDate ?? Date())
            imageName = "IMG_\(dateString).jpg"
        }

        if #available(iOS 13.0, *)
        {
            manager.requestImageDataAndOrientation(for: asset, options: imageOptions) { (imageData, dataUTI, orientation, info) in
                saveImageToDisk(imageData: imageData, imageName: imageName)
            }
        }
        else
        {
            manager.requestImageData(for: asset, options: imageOptions, resultHandler:
            { (imageData, dataUTI, orientation, info) in
                saveImageToDisk(imageData: imageData, imageName: imageName)
            })
        }

        func saveImageToDisk(imageData: Data?, imageName: String?)
        {
            if let destPath = self.stackPath.last , let destName = imageName , let sourceData = imageData
            {
                let destFileString = destPath.absoluteString + destName
                let destUrl = URL(string: destFileString)!
                
                if fileManager.fileExists(atPath: destUrl.path)
                {
                    let msg = String(format: "文件%@与文件夹中原有文件重名，是否覆盖？", destName);
                    let alert = CDAlertView(title: "文件重名", message: msg, type: .warning)
                    let noAction = CDAlertViewAction(title: "跳过", handler: { action->Bool in
                        self.refreshCopyCount()
                        return true;
                    })
                    alert.add(action: noAction)
                    let yesAction = CDAlertViewAction(title: "覆盖", handler: { action->Bool in
                        try? sourceData.write(to: destUrl)
                        self.refreshCopyCount()
                        return true;
                    })
                    alert.add(action: yesAction)
                    alert.show()
                }
                else
                {
                    try? sourceData.write(to: destUrl)
                    self.refreshCopyCount()
                }
                
            }
        }
    }
    
    //MARK: - 保存视频
    func saveVideo(asset: PHAsset)
    {
        let globalConfig = GlobalConfig.getInstance()
        let option = PHVideoRequestOptions()
        option.isNetworkAccessAllowed = true
        option.deliveryMode = .fastFormat
        switch globalConfig.videoImportQuality
        {
        case 0:
            option.deliveryMode = .fastFormat
        case 1:
            option.deliveryMode = .mediumQualityFormat
        case 2:
            if #available(iOS 13.0,*)       //iOS13开始才支持高质量
            {
                option.deliveryMode = .highQualityFormat
            }
            else
            {
                option.deliveryMode = .automatic
            }
        default:
            option.deliveryMode = .fastFormat
        }
        PHCachingImageManager.default().requestExportSession(forVideo: asset, options: option, exportPreset: AVAssetExportPresetHighestQuality) { (exportSession, info) in
            guard let exportSession = exportSession, let destPath = self.stackPath.last?.path else {
                self.showPop(type: .error, message: "导出视频失败")
                return
            }
            
            let destName = String(Int(NSDate().timeIntervalSince1970 * 100)) + ".mp4"
            let fullDestName = destPath + "/" + destName
            exportSession.outputURL = URL(fileURLWithPath: fullDestName)
            exportSession.outputFileType = .mp4
            exportSession.exportAsynchronously {
                switch exportSession.status {
                case .completed:
                    DispatchQueue.main.async {
                        self.refreshCopyCount(mediaType: asset.mediaType)
                    }
                case .failed:
                    //print(exportSession.error)
                    DispatchQueue.main.async {
                        self.refreshCopyCount(mediaType: asset.mediaType)
                    }

                    
                default:
                    break
                }
            }
        }
    }
    
    //MARK: - 更新已拷贝文件数量
    func refreshCopyCount(mediaType: PHAssetMediaType = .image)
    {
        //待拷贝文件数-1
        self.copyedFileCount += 1
        if self.totalImportFileCount == self.copyedFileCount
        {
            //如果全部文件已拷贝完，刷新列表
            refreshFolder()
            
            if mediaType == .image
            {
                //隐藏进度条
                progressBar.isHidden = true
            }
            
            self.showPop(type: .success, message: "导入操作已完成")
        }
        else if mediaType == .image
        {
            progressBar.progress = Double(copyedFileCount) / Double(totalImportFileCount)
        }
    }
    
    //MARK: - 切换选择界面
    func switchSelectionMode()
    {
        isSelectMode = !isSelectMode
        if(viewPad.isHidden)
        {
            bottomViewPad.constant = 0 - viewPad.bounds.height
            viewPad.isHidden = false
            UIView.animate(withDuration: 0.3, animations: {
                self.bottomViewPad.constant = 0
                self.viewPad.center.y -= self.viewPad.bounds.height
                self.bottomCollectionMain.constant = self.viewPad.bounds.height
            }) { (_) in
                self.collectMain.reloadData()
            }
            
        }
        else
        {
            UIView.animate(withDuration: 0.3, animations: {
                self.bottomViewPad.constant = 0 - self.viewPad.bounds.height
                self.viewPad.center.y += self.viewPad.bounds.height
                self.bottomCollectionMain.constant = 0
            }) { (_) in
                self.viewPad.isHidden = true
                self.collectMain.reloadData()
            }
            
            
        }
    }
    
    //MARK: - “选择全部”按钮被点击的处理
    @objc func onBtnSelectAllClicked()
    {
        for i in 0..<arrayContents.count
        {
            arrayContents[i].isSelected = true
        }
        collectMain.reloadData()
    }
    
    //MARK: - "删除"按钮被点击的处理
    @objc func onBtnDeleteClicked()
    {
        var deleteCount = 0
        for item in arrayContents
        {
            if item.isSelected
            {
                deleteCount+=1
            }
        }
        
        if deleteCount > 0
        {
            let msg = String(format: "删除内容不可恢复\n您确定删除这%d个项目吗？", deleteCount);
            let alert = CDAlertView(title: "确认删除", message: msg, type: .warning)
            alert.isHeaderIconFilled = true
            alert.hideAnimations = { (center, transform, alpha) in
                transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                alpha = 0
            }
            alert.hideAnimationDuration = 0.3
            let noAction = CDAlertViewAction(title: "再想想", handler: { action->Bool in
                return true;
            })
            alert.add(action: noAction)
            let yesAction = CDAlertViewAction(title: "确定", handler: { action->Bool in
                for item in self.arrayContents
                {
                    if item.isSelected
                    {
                        do {
                            try FileManager.default.removeItem(at: item.url)
                        }
                        catch let error as NSError {
                            print("An error took place: \(error)")
                        }
                    }
                }
                
                //更新目录内容
                self.refreshFolder(refreshUI: false)
                
                //退出选择模式
                self.switchSelectionMode()
                return true;
            })
            alert.add(action: yesAction)
            alert.show()
        }
    }
    
    //MARK: - 启动图片全屏浏览
    func showImageViewer(startIndex: Int)
    {
        var images = [SKPhoto]()
        
        var startImageIndex = 0
        for i in 0..<arrayContents.count
        {
            //将目录下的所有图片文件加入到数组中
            if arrayContents[i].type == .imageFile
            {
                let photo = SKPhoto.photoWithImageURL(arrayContents[i].url.absoluteString)
                photo.shouldCachePhotoURLImage = true
                images.append(photo)
                
                if i == startIndex
                {
                    //设定起始图片
                    startImageIndex = images.count - 1
                }
            }
        }

        let browser = SKPhotoBrowser(photos: images)
        browser.initializePageIndex(startImageIndex)
        present(browser, animated: true, completion: {})
    }
    
    func playVideo(startIndex: Int)
    {
        self.arrayVideo.removeAll()
        
        for i in 0..<arrayContents.count
        {
            //将目录下的所有图片文件加入到数组中
            if arrayContents[i].type == .videoFile
            {
                arrayVideo.append(arrayContents[i].url)
                
                if i == startIndex
                {
                    //设定起始视频
                    startPlayVideoIndex = arrayVideo.count - 1
                }
            }
        }
        
        self.performSegue(withIdentifier: "ShowBMPlayer", sender: self)
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowBMPlayer"
        {
            let destVC:BMPlayerVC = segue.destination as! BMPlayerVC
                        
            destVC.arrayUrls = self.arrayVideo
            destVC.startPlayIndex = self.startPlayVideoIndex
        }
        else if segue.identifier == "ShowWebView"
        {
            let destVC:WebViewVC = segue.destination as! WebViewVC
            let fileItem = arrayContents[curWebFileIndex]
            destVC.url = fileItem.url
            destVC.title = fileItem.name
        }
        else if segue.identifier == "PresentPass"
        {
            let destVC:PassVC = segue.destination as! PassVC
            destVC.delegate = self
        }
    }
    
    //MARK: - 获取缩略图
    func getThumbnailFrom(path: URL) -> UIImage? {
        
        do {
            let asset = AVURLAsset(url: path , options: nil)
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            imgGenerator.appliesPreferredTrackTransform = true
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil)
            let thumbnail = UIImage(cgImage: cgImage)
            
            return thumbnail
            
        } catch let error {
            
            print("*** Error generating thumbnail: \(error.localizedDescription)")
            return nil
            
        }
    }
    
    //MARK: - 长按Cell的处理
    @objc func onCollectionLongPressed(recognizer: UILongPressGestureRecognizer)
    {
        if recognizer.state != .began
        {
            return
        }
        
        //如果处于选择模式，先退出选择模式
        if isSelectMode
        {
            switchSelectionMode()
        }
        
        let p: CGPoint = recognizer.location(in: collectMain)
        if let indexPath = collectMain.indexPathForItem(at: p)
        {
            if let cell = collectMain.cellForItem(at: indexPath)
            {
                var menuModelArray : [FTPopOverMenuModel] = [FTPopOverMenuModel(title: "分享", image: "", selected: self.selectedIndex == 0),
                                                             FTPopOverMenuModel(title: "重命名", image: "", selected: self.selectedIndex == 1),
                                                             FTPopOverMenuModel(title: "删除", image: "", selected: self.selectedIndex == 2)]
                let fileItem = arrayContents[indexPath.row]
                if fileItem.type == .directory
                {
                    menuModelArray.removeFirst()
                }
                
                let config = FTConfiguration()
                config.backgoundTintColor = UIColor.white
                config.borderColor = UIColor.lightGray
                config.menuWidth = 100
                config.menuSeparatorColor = UIColor.lightGray
                config.menuRowHeight = 50
                config.cornerRadius = 6
                config.textColor = UIColor.black
                config.textAlignment = NSTextAlignment.center
                config.selectedTextColor = UIColor.black
                config.selectedCellBackgroundColor = UIColor.white
                
                //弹出菜单
                if fileItem.type == .directory
                {
                    FTPopOverMenu.showForSender(sender: cell, with: menuModelArray, menuImageArray: nil, popOverPosition: .automatic, config: config, done: { (selectedIndex) in
                        self.selectedIndex = selectedIndex
                        switch self.selectedIndex
                        {
                        case 0:
                            self.beginRenameItem(indexPath: indexPath)
                        case 1:
                            self.deleteItem(indexPath: indexPath)
                        default:
                            break
                        }
                    }) {
                            
                    }
                }
                else
                {
                    FTPopOverMenu.showForSender(sender: cell, with: menuModelArray, menuImageArray: nil, popOverPosition: .automatic, config: config, done: { (selectedIndex) in
                        self.selectedIndex = selectedIndex
                        switch self.selectedIndex
                        {
                        case 0:
                            self.shareItem(indexPath: indexPath)
                        case 1:
                            self.beginRenameItem(indexPath: indexPath)
                        case 2:
                            self.deleteItem(indexPath: indexPath)
                        default:
                            break
                        }
                    }) {
                            
                    }
                }

            }
        }
    }
    
    //MARK: - 删除指定的项目
    func deleteItem(indexPath: IndexPath)
    {
        let msg = String(format: "删除内容不可恢复\n您确定删除这个项目吗？");
        let alert = CDAlertView(title: "确认删除", message: msg, type: .warning)
        alert.isHeaderIconFilled = true
        alert.hideAnimations = { (center, transform, alpha) in
            transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            alpha = 0
        }
        alert.hideAnimationDuration = 0.3
        let noAction = CDAlertViewAction(title: "再想想", handler: { action->Bool in
            return true;
        })
        alert.add(action: noAction)
        let yesAction = CDAlertViewAction(title: "确定", handler: { action->Bool in
            let item = self.arrayContents[indexPath.row]
            
            do {
                try FileManager.default.removeItem(at: item.url)
            }
            catch let error as NSError {
                print("An error took place: \(error)")
            }
            
            //更新目录内容
            self.refreshFolder()

            return true;
        })
        alert.add(action: yesAction)
        alert.show()
    }
    
    //MARK: - 重命名项目
    func beginRenameItem(indexPath: IndexPath)
    {
        let title = "重命名"
        let message = "请输入新的名字"
        let cancelButtonTitle = "取消"
        let otherButtonTitle = "确定"
        
        let alertController = ZWAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.textLimit = 30  // == 限制10个中文字符 limit 10 Chinese characters, equal to 30 English characters
        // Add the text field for text entry.
        alertController.addTextFieldWithConfigurationHandler { textField in
            // If you need to customize the text field, you can ZW so here.
            textField?.textColor = UIColor.black
            textField?.leftView = UIView.init(frame: CGRect(x: 0, y: 0, width: 10, height: textField!.frame.size.height))
            textField?.leftViewMode = .always
        }
        
        // Create the actions.
        let cancelAction = ZWAlertAction(title: cancelButtonTitle, style: .cancel) { action in
        }
        
        let otherAction = ZWAlertAction(title: otherButtonTitle, style: .default) { action in
            if let name = alertController.textFields?.first?.text
            {
                let item = self.arrayContents[indexPath.row]
                self.renameItem(oldUrl: item.url, newName: name)
                self.refreshFolder()
            }
            
        }
        
        // Add the actions.
        alertController.addAction(cancelAction)
        alertController.addAction(otherAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    //MARK: - 项目改名
    func renameItem(oldUrl: URL, newName: String)
    {
        if let baseUrl = self.stackPath.last as NSURL?, let destUrl = baseUrl.appendingPathComponent(newName)
        {
            if FileManager.default.fileExists(atPath: destUrl.path)
            {
                self.showPop(type: .error, message: "已有同名文件，请换个名字吧。")
                return
            }
            
            do {
                try FileManager.default.moveItem(at: oldUrl, to: destUrl)
            }
            catch let error as NSError {
                if let errMsg = error.localizedFailureReason
                {
                    self.showPop(type: .error, message: errMsg)
                }
                else
                {
                    self.showPop(type: .error, message: error.debugDescription)
                }
                return
            }
            self.refreshFolder()
            self.showPop(type: .success, message: "重命名完成")
        }
    }

    //MARK: - 分享项目
    func shareItem(indexPath: IndexPath)
    {
        if let url = arrayContents[indexPath.row].url
        {
            let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            self.present(activityVC, animated: true) {
            }
        }
    }
    
    //MARK - 应用程序退到后台的通知
    @objc func appResignActive(noti: Notification)
    {
        let globalConfig = GlobalConfig.getInstance()
        if globalConfig.startupPassword != nil
        {
            //弹出登录窗口
            self.performSegue(withIdentifier: "PresentPass", sender: self)
        }
        else
        {
//            let blur = UIBlurEffect.init(style: .light)
//            let effectView = UIVisualEffectView.init(effect: blur)
//            effectView.frame = self.view.frame
//            self.view.addSubview(effectView)
        }
    }
}
//
//extension HomeVC: DropdownMenuDelegate {
//
//}
