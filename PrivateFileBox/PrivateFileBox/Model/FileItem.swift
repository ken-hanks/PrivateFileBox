//
//  FileItem.swift
//  PrivateFileBox
//
//  Created by hankang on 2020/6/29.
//  Copyright © 2020 Greycat. All rights reserved.
//

import UIKit

enum ItemType
{
    case directory
    case videoFile
    case audioFile
    case imageFile
    case textFile
    case webPage
    case wordFile
    case excelFile
    case pdfFile
    case codeFile
    case unknown
}

struct FileItem{
    var name = ""
    var extName = ""
    var type : ItemType = .unknown
    var isSelected : Bool = false
    var modifyDate : Date
    var url : URL!
    
    init(url: URL, isDirectory: Bool, name: String, date: Date)
    {
        self.url = url
        self.name = name
        self.extName = url.pathExtension
        self.modifyDate = date
        if isDirectory
        {
            self.type = .directory
        }
        else
        {
            switch self.extName.lowercased()
            {
            case "mp4","mov","mpg","mkv","mpeg","flv":
                self.type = .videoFile
            case "jpg","jpeg","png","bmp","gif","heic":
                self.type = .imageFile
            case "mp3","wma":
                self.type = .audioFile
            case "txt":
                self.type = .textFile
            case "htm","html","mht":
                self.type = .webPage
            case "doc","docx","rtf":
                self.type = .wordFile
            case "xls","xlsx":
                self.type = .excelFile
            case "pdf":
                self.type = .pdfFile
            case "json","js","h","c","cpp","mm","swift","php","bat","java":
                self.type = .codeFile
            default:
                break
            }
        }
    }
}
