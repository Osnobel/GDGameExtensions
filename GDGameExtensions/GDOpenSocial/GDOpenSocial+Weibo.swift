//
//  GDOpenSocial+Weibo.swift
//  GDOpenSocial
//
//  Created by Bell on 16/5/28.
//  Copyright © 2016年 GoshDo <http://goshdo.sinaapp.com>. All rights reserved.
//

import UIKit

public extension GDOpenSocial {
    public static var isWeiboInstalled: Bool {
        get {
            return self.canOpenURLString("weibosdk://request")
        }
    }
    
    public static var getWeiboInstallUrl: NSURL {
        get {
            return NSURL(string: "https://itunes.apple.com/cn/app/id350962117?mt=8")!
        }
    }
    
    public static var isWeiboApiAvailable: Bool {
        get {
            return self.isWeiboInstalled && (self.appId(OSServiceTypeWeibo) != nil)
        }
    }
    
    public static func registerWeiboApi(appId: String) {
        self.cacheService(OSServiceTypeWeibo, schemes: ["wb\(appId)"], appId: appId, handleOpenURLHandler: self.wbHandleOpenURL)
    }
    
    public static func shareToWeibo(message: GDOSMessage, completionHandler handler: GDOSServiceCompletionHandler?) {
        if self.canService(OSServiceTypeWeibo, completionHandler: handler) {
            self.openURLString(self.genWeiboShareUrl(message))
        }
    }
    /**
    *  微博登录OAuth
    *
    *  @param scope       scope，如果不填写，默认是all
    *  @param redirectURI 必须填写，可以通过http://open.weibo.com/apps/your_sina_appkey/info/advanced编辑(后台不验证，但是必须填写一致)
    *  @param completionHandler 登录回调
    */
    public static func authWeibo(redirectURI: String = "https://api.weibo.com/oauth2/default.html", scope: String = "all", completionHandler handler: GDOSServiceCompletionHandler?) {
        if self.canService(OSServiceTypeWeibo, completionHandler: handler) {
            let uuid = NSUUID().UUIDString
            let appId = self.appId(OSServiceTypeWeibo)!
            
            let transferObject = ["transferObject": ["__class" : "WBAuthorizeRequest", "redirectURI":redirectURI, "requestID" :uuid, "scope": scope]]
            let userInfo = ["userInfo": ["SSO_From": "SendMessageToWeiboViewController"]]
            let app = ["app": ["appKey" : appId, "bundleID" : self.bundleIdentifier, "name": self.bundleDisplayName]]
            let authData:[[String: AnyObject]] = [transferObject, userInfo, app]
            self.setGeneralPasteboardItems(items: authData, encoding: .KeyedArchiver)
            
            let authUrlString = "weibosdk://request?id=\(uuid)&sdkversion=003133000"
            self.openURLString(authUrlString)
        }
    }
    
    public static func getWeiboUserInfo(accessToken: String, userID: String, completionHandler handler: GDOSServiceCompletionHandler?) {
        let urlString = "https://api.weibo.com/2/users/show.json?access_token=\(accessToken)&uid=\(userID)"
        let url = NSURL(string: urlString)
        let request = NSURLRequest(URL: url!, cachePolicy: NSURLRequestCachePolicy.UseProtocolCachePolicy, timeoutInterval: 20)
        let session = NSURLSession(configuration: NSURLSessionConfiguration.ephemeralSessionConfiguration())
        let task = session.dataTaskWithRequest(request) { (data, response, error) -> Void in
            guard error == nil else {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    handler?([:], error)
                })
                return
            }
            guard let validData = data where validData.length > 0 else {
                // print("JSON could not be serialized. Input data was nil or zero length.")
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    let err = NSError(domain: "com.opensocial.getweibouserinfo", code: -1, userInfo: [NSLocalizedDescriptionKey:"Get User Info with \(OSServiceTypeWeibo) Failed"])
                    handler?([:], err)
                })
                return
            }
            print(String(data: validData, encoding: NSUTF8StringEncoding)!)
            do {
                let JSON = try NSJSONSerialization.JSONObjectWithData(validData, options: .AllowFragments)
                if let result = JSON as? [String: AnyObject] {
                    var err: NSError? = nil
                    if let errcode = result["error_code"] as? Int {
                        let errmsg = result["error"] as? String ?? ""
                        err = NSError(domain: "com.opensocial.getweibouserinfo", code: errcode, userInfo: [NSLocalizedDescriptionKey:"Get User Info with \(OSServiceTypeWeibo) Failed: \(errmsg)"])
                    }
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        handler?(result, err)
                    })
                } else {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        let err = NSError(domain: "com.opensocial.getweibouserinfo", code: -1, userInfo: [NSLocalizedDescriptionKey:"Get User Info with \(OSServiceTypeWeibo) Failed"])
                        handler?([:], err)
                    })
                }
                return
            } catch let e as NSError {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    handler?([:], e)
                })
                return
            }
        }
        task.resume()
        session.finishTasksAndInvalidate()
    }
    
    private static let OSServiceTypeWeibo: String = "Weibo"
    
    private static func genWeiboShareUrl(message: GDOSMessage) -> String {
        let msg = message
        var dic: Dictionary<String, AnyObject> = ["__class": "WBMessageObject"]
        
        if msg.image == nil && msg.link == nil && msg.title != nil {
            //文本
            dic["text"] = msg.title
        } else if msg.link == nil && msg.image != nil && msg.title != nil  {
            //图片
            dic["imageObject"] = ["imageData": self.imageData(msg.image!)]
            dic["text"] = msg.title
        } else if msg.image != nil && msg.link != nil && msg.title != nil {
            //有链接
            var mediaObject: Dictionary<String, AnyObject> = ["__class": "WBWebpageObject"]
            mediaObject["description"] = msg.description != nil ? msg.description :msg.title;
            mediaObject["objectID"] = "identifier1"
            mediaObject["thumbnailData"] = msg.thumbnail != nil ? self.imageData(msg.thumbnail!) : self.imageData(msg.image!, toSize: CGSizeMake(100, 100))
            mediaObject["title"] = msg.title
            mediaObject["webpageUrl"] = msg.link
            dic["mediaObject"] = mediaObject
        }
        let uuid = NSUUID().UUIDString
        let appId = self.appId(OSServiceTypeWeibo)!
        
        let transferObject = ["transferObject": ["__class" : "WBSendMessageToWeiboRequest", "message":dic, "requestID" :uuid]]
        let userInfo = ["userInfo": [:]]
        let app = ["app": ["appKey" : appId, "bundleID" : self.bundleIdentifier]]
        
        self.setGeneralPasteboardItems(items: [transferObject, userInfo, app], encoding: .KeyedArchiver)
        
        return "weibosdk://request?id=\(uuid)&sdkversion=003133000"
    }
    
    private static let wbHandleOpenURL: GDOSHandleOpenURLHandler = {(url) -> Bool in
        var result = false
        var data = Dictionary<String, AnyObject>()
        var error: NSError? = nil
        if url.scheme.hasPrefix("wb") {
            let items = GDOpenSocial.generalPasteboardItems(.KeyedArchiver)
            for item in items {
                for (key, value) in item {
                    data[key] = value
                }
            }
            if let transferObject = data["transferObject"] as? Dictionary<String, AnyObject> {
                if let statusCode = transferObject["statusCode"] as? Int where statusCode != 0 {
                    if transferObject["__class"] as? String == "WBAuthorizeResponse" {
                        //登陆auth
                        error = NSError(domain: "com.opensocial.authwithweibo", code: statusCode, userInfo: [NSLocalizedDescriptionKey:"Auth with \(OSServiceTypeWeibo) Failed"])
                    } else if transferObject["__class"] as? String == "WBSendMessageToWeiboResponse" {
                        //分享
                        error = NSError(domain: "com.opensocial.sharetoweibo", code: statusCode, userInfo: [NSLocalizedDescriptionKey:"Share to \(OSServiceTypeWeibo) Failed"])
                    }
                }
            }
            result = true
        }
        
        if result {
            GDOpenSocial.serviceCompletionHandler?(data, error)
            GDOpenSocial.serviceCompletionHandler = nil
        }
        return result
    }
    
}
