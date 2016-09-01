//
//  GDOpenSocial.swift
//  GDOpenSocial
//
//  Created by Bell on 16/5/28.
//  Copyright © 2016年 GoshDo <http://goshdo.sinaapp.com>. All rights reserved.
//

import UIKit

public typealias GDOSServiceCompletionHandler = (Dictionary<String, AnyObject>, NSError?) -> Void
public typealias GDOSHandleOpenURLHandler = (NSURL) -> Bool

public class GDOpenSocial {
    // #public
    public static func handleOpenURL(openUrl: NSURL) -> Bool {
        if let handler = self.handleOpenURLHandler(openUrl.scheme) {
            return handler(openUrl)
        }
        return false
    }
    
    // #internal
    static func openURLString(urlString: String) {
        if let url = NSURL(string: urlString) {
            UIApplication.sharedApplication().openURL(url)
        }
    }
    
    static func canOpenURLString(urlString: String) -> Bool {
        if let url = NSURL(string: urlString) {
            return UIApplication.sharedApplication().canOpenURL(url)
        }
        return false
    }
    
    static func canService(serviceType: String, completionHandler handler: GDOSServiceCompletionHandler?) -> Bool {
        if self.appId(serviceType) != nil {
            self.serviceCompletionHandler = handler
            return true
        }
        print("place register\(serviceType)Api before you can use service with it!!!")
        return false
    }
    
    static var bundleDisplayName: String {
        get {
            return NSBundle.mainBundle().localizedInfoDictionary?["CFBundleDisplayName"] as? String ?? NSBundle.mainBundle().infoDictionary?["CFBundleDisplayName"] as? String ?? NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleName") as? String ?? ""
        }
    }
    
    static var bundleIdentifier: String {
        get {
            return NSBundle.mainBundle().bundleIdentifier!
        }
    }
    
    static func parseUrl(url: NSURL) -> Dictionary<String, AnyObject> {
        var queryStringDictionary = Dictionary<String, String>()
        if let urlComponents: [String] = url.query?.componentsSeparatedByString("&") {
            for keyValuePair in urlComponents {
                if let range = keyValuePair.rangeOfString("=") {
                    let key = keyValuePair[keyValuePair.startIndex..<range.startIndex]
                    let value = keyValuePair[range.endIndex..<keyValuePair.endIndex]
                    queryStringDictionary[key] = value
                }
            }
        }
        return queryStringDictionary
    }
    
    static func base64Encode(string: String) -> String {
        return string.dataUsingEncoding(NSUTF8StringEncoding)!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
    }
    
    static func base64Decode(string: String) -> String {
        return String(data: NSData(base64EncodedString: string, options: NSDataBase64DecodingOptions(rawValue: 0))!, encoding: NSUTF8StringEncoding)!
    }
    
    static func urlEncode(string: String) -> String {
        return string.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet())!
    }
    
    static func urlDecode(string: String) -> String {
        return string.stringByReplacingOccurrencesOfString("+", withString: "").stringByRemovingPercentEncoding!
    }
    
    static func imageData(image: UIImage) -> NSData {
        return UIImagePNGRepresentation(image) ?? NSData()
    }
    
    static func imageData(image: UIImage, toSize: CGSize) -> NSData {
        UIGraphicsBeginImageContext(toSize)
        image.drawInRect(CGRectMake(0, 0, toSize.width, toSize.height))
        let resizeImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return UIImagePNGRepresentation(resizeImage) ?? NSData()
    }
    
    // 分享／auth以后，应用被调起，回调。
    static var serviceCompletionHandler: GDOSServiceCompletionHandler?
        
    /**
    粘贴板数据编码方式，目前只有两种:
    1. NSKeyedArchiver.archivedDataWithRootObject(data)
    2. NSPropertyListSerialization.dataWithPropertyList(data, format: .BinaryFormat_v1_0, options: 0)
    */
    enum GDOSPasteboardEncoding {
        case KeyedArchiver
        case PropertyListSerialization
    }
    
    static func setGeneralPasteboardData(pasteboardType: String, value: Dictionary<String, AnyObject>, encoding: GDOSPasteboardEncoding) {
        var data: NSData?
        
        switch encoding {
        case .KeyedArchiver:
            data = NSKeyedArchiver.archivedDataWithRootObject(value)
        case .PropertyListSerialization:
            do {
                data = try NSPropertyListSerialization.dataWithPropertyList(value, format: .BinaryFormat_v1_0, options: 0)
            } catch let error {
                print("error when NSPropertyListSerialization: \(error)")
            }
        }
        
        if data != nil {
            UIPasteboard.generalPasteboard().setData(data!, forPasteboardType: pasteboardType)
        }
    }
    
    static func generalPasteboardData(pasteboardType: String, encoding: GDOSPasteboardEncoding) -> Dictionary<String, AnyObject> {
        var value: Dictionary<String, AnyObject> = [:]
        guard let data = UIPasteboard.generalPasteboard().dataForPasteboardType(pasteboardType) else { return value }
        
        switch encoding {
        case .KeyedArchiver:
            value = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? Dictionary<String, AnyObject> ?? [:]
        case .PropertyListSerialization:
            do {
                var propertyListFormat = NSPropertyListFormat.BinaryFormat_v1_0
                value = try NSPropertyListSerialization.propertyListWithData(data, options: NSPropertyListReadOptions(rawValue: 0), format: &propertyListFormat) as? Dictionary<String, AnyObject> ?? [:]
            } catch let error {
                print("error when NSPropertyListSerialization: \(error)")
            }
        }
        
        return value
    }
    
    static func setGeneralPasteboardItems(items s: [Dictionary<String, AnyObject>], encoding: GDOSPasteboardEncoding) {
        var data: NSData?
        var item = Dictionary<String, AnyObject>()
        var items = [Dictionary<String, AnyObject>]()
        for i in s {
            for (key, value) in i {
                switch encoding {
                case .KeyedArchiver:
                    data = NSKeyedArchiver.archivedDataWithRootObject(value)
                case .PropertyListSerialization:
                    do {
                        data = try NSPropertyListSerialization.dataWithPropertyList(value, format: .BinaryFormat_v1_0, options: 0)
                    } catch let error {
                        print("error when NSPropertyListSerialization: \(error)")
                    }
                }
                
                if data != nil {
                    item[key] = data
                    data = nil
                }
            }
            if !item.isEmpty {
                items.append(item)
                item.removeAll()
            }
        }
        
        if !items.isEmpty {
            UIPasteboard.generalPasteboard().items = items
        }
    }
    
    static func generalPasteboardItems(encoding: GDOSPasteboardEncoding) -> [Dictionary<String, AnyObject>] {
        var items = [Dictionary<String, AnyObject>]()
        let s = UIPasteboard.generalPasteboard().items
        if s.isEmpty {
            return items
        }
        var data: AnyObject? = nil
        for var item in s as! [Dictionary<String, AnyObject>] {
            for (key, value) in item {
                switch encoding {
                case .KeyedArchiver:
                    if let v = value as? NSData {
                        data = NSKeyedUnarchiver.unarchiveObjectWithData(v)
                    }
                case .PropertyListSerialization:
                    if let v = value as? NSData {
                        do {
                            var propertyListFormat = NSPropertyListFormat.BinaryFormat_v1_0
                            data = try NSPropertyListSerialization.propertyListWithData(v, options: NSPropertyListReadOptions(rawValue: 0), format: &propertyListFormat)
                        } catch let error {
                            print("error when NSPropertyListSerialization: \(error)")
                        }
                    }
                }
                if data != nil {
                    item[key] = data
                    data = nil
                }
            }
            items.append(item)
        }
        
        return items
    }
    
    static func cacheService(serviceType: String, schemes: [String], appId: String, handleOpenURLHandler handler: GDOSHandleOpenURLHandler) {
        for scheme in schemes {
            schemeServiceTypeMap[scheme] = serviceType
        }
        serviceTypeAppIdMap[serviceType] = appId
        serviceTypeHandleOpenURLMap[serviceType] = handler
    }
    
    static func appId(serviceType: String) -> String? {
        return serviceTypeAppIdMap[serviceType]
    }
    
    // #private
    private static var schemeServiceTypeMap: [String :String] = [:]
    private static var serviceTypeAppIdMap: [String :String] = [:]
    private static var serviceTypeHandleOpenURLMap: [String :GDOSHandleOpenURLHandler] = [:]
    
    private static func handleOpenURLHandler(scheme: String) -> GDOSHandleOpenURLHandler? {
        if let serviceType = schemeServiceTypeMap[scheme] {
            return serviceTypeHandleOpenURLMap[serviceType]
        }
        return nil
    }
}

/**
*  GDOSMessage保存分享消息数据。
*/
public class GDOSMessage {
    /**
    分享类型，除了news以外，还可能是video／audio／app等。
    */
    public enum MultimediaType {
        case News
        case Audio
        case Video
        case App
        case File
        case Undefined
    }
    public var title: String?
    public var description: String?
    public var link: String?
    public var image: UIImage?
    public var thumbnail: UIImage?
    public var multimediaType: MultimediaType?
    //for 微信
    public var extInfo: String?
    public var mediaDataUrl: String?
    public var fileExt: String?
    public var file: NSData?   /// 微信分享gif/文件
}