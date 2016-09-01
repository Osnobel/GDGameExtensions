//
//  GDOpenSocial+WeChat.swift
//  GDOpenSocial
//
//  Created by BINGZHONG ZENG on 15/11/7.
//  Copyright © 2015年 BINGZHONG ZENG. All rights reserved.
//

import UIKit

public extension GDOpenSocial {
    public static var isWeChatInstalled: Bool {
        get {
            return self.canOpenURLString("weixin://")
        }
    }
    
    public static var getWeChatInstallUrl: NSURL {
        get {
            return NSURL(string: "https://itunes.apple.com/cn/app/id414478124?mt=8")!
        }
    }
    
    public static var isWeChatApiAvailable: Bool {
        get {
            return self.isWeChatInstalled && (self.appId(OSServiceTypeWeChat) != nil)
        }
    }
    
    public static func registerWeChatApi(appId: String) {
        self.cacheService(OSServiceTypeWeChat, schemes: [appId], appId: appId, handleOpenURLHandler: self.wxHandleOpenURL)
    }
    
    public static func shareToWeChatSession(message: GDOSMessage, completionHandler handler: GDOSServiceCompletionHandler?) {
        if self.canService(OSServiceTypeWeChat, completionHandler: handler) {
            self.openURLString(self.genWeChatShareUrl(message, to:0))
        }
    }
    
    public static func shareToWeChatTimeline(message: GDOSMessage, completionHandler handler: GDOSServiceCompletionHandler?) {
        if self.canService(OSServiceTypeWeChat, completionHandler: handler) {
            self.openURLString(self.genWeChatShareUrl(message, to:1))
        }
    }
    
    public static func shareToWeChatFavorite(message: GDOSMessage, completionHandler handler: GDOSServiceCompletionHandler?) {
        if self.canService(OSServiceTypeWeChat, completionHandler: handler) {
            self.openURLString(self.genWeChatShareUrl(message, to:2))
        }
    }
    // scope = "snsapi_message,snsapi_userinfo,snsapi_friend,snsapi_contact";//,post_timeline,sns
    public static func authWeChat(scope: String = "snsapi_userinfo", completionHandler handler: GDOSServiceCompletionHandler?) {
        if self.canService(OSServiceTypeWeChat, completionHandler: handler) {
            let appid = self.appId(OSServiceTypeWeChat)!
            let authUrlString = "weixin://app/\(appid)/auth/?scope=\(scope)&state=weixinauth"
            self.openURLString(authUrlString)
        }
    }
    
    public static func getWeChatUserInfo(appSecret: String, code: String, completionHandler handler: GDOSServiceCompletionHandler?) {
        self.getWeChatAccessToken(appSecret, code: code) { (accessTokenData, error) -> Void in
            guard error == nil else {
                handler?(accessTokenData, error)
                return
            }
            guard (accessTokenData["scope"] as! String).componentsSeparatedByString(",").contains("snsapi_userinfo") else {
                let err = NSError(domain: "com.opensocial.getwechatuserinfo", code: -1, userInfo: [NSLocalizedDescriptionKey:"Get User Info with \(OSServiceTypeWeChat) Failed"])
                handler?([:], err)
                return
            }
            let access_token = accessTokenData["access_token"] as! String
            let openid = accessTokenData["openid"] as! String
            let urlString = "https://api.weixin.qq.com/sns/userinfo?access_token=\(access_token)&openid=\(openid)"
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
                        let err = NSError(domain: "com.opensocial.getwechatuserinfo", code: -1, userInfo: [NSLocalizedDescriptionKey:"Get User Info with \(OSServiceTypeWeChat) Failed"])
                        handler?([:], err)
                    })
                    return
                }
                print(String(data: validData, encoding: NSUTF8StringEncoding)!)
                do {
                    let JSON = try NSJSONSerialization.JSONObjectWithData(validData, options: .AllowFragments)
                    if let result = JSON as? [String: AnyObject] {
                        var err: NSError? = nil
                        if let errcode = result["errcode"] as? Int {
                            let errmsg = result["errmsg"] as? String ?? ""
                            err = NSError(domain: "com.opensocial.getwechatuserinfo", code: errcode, userInfo: [NSLocalizedDescriptionKey:"Get User Info with \(OSServiceTypeWeChat) Failed: \(errmsg)"])
                        }
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            handler?(result, err)
                        })
                    } else {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            let err = NSError(domain: "com.opensocial.getwechatuserinfo", code: -1, userInfo: [NSLocalizedDescriptionKey:"Get User Info with \(OSServiceTypeWeChat) Failed"])
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
    }
    
    private static let OSServiceTypeWeChat: String = "WeChat"
    
    private static func genWeChatShareUrl(message: GDOSMessage, to: Int) -> String {
        let msg = message
        var dic: Dictionary<String, AnyObject> = ["result": "1", "returnFromApp": "0", "scene": "\(to)", "sdkver": "1.5", "command": "1010"]
        
        if msg.multimediaType == nil {
            //不指定类型
            if msg.image == nil && msg.link == nil && msg.file == nil && msg.title != nil {
                //文本
                dic["command"] = "1020"
                dic["title"] = msg.title
            } else if msg.link == nil && msg.image != nil {
                //图片
                dic["title"] = msg.title ?? ""
                dic["fileData"] = self.imageData(msg.image!)
                dic["thumbData"] = msg.thumbnail != nil ? self.imageData(msg.thumbnail!) : self.imageData(msg.image!, toSize: CGSizeMake(100, 100))
                dic["objectType"] = "2"
            } else if msg.image != nil && msg.link != nil && msg.title != nil {
                //有链接
                dic["description"] = msg.description != nil ? msg.description :msg.title;
                dic["mediaUrl"] = msg.link
                dic["objectType"] = "5"
                dic["thumbData"] = msg.thumbnail != nil ? self.imageData(msg.thumbnail!) : self.imageData(msg.image!, toSize: CGSizeMake(100, 100))
                dic["title"] = msg.title
            } else if msg.link == nil && msg.file != nil {
                //gif
                dic["fileData"] = msg.file
                dic["thumbData"] = msg.thumbnail != nil ? self.imageData(msg.thumbnail!) : self.imageData(msg.image!, toSize: CGSizeMake(100, 100))
                dic["objectType"] = "8"
            }
        } else if msg.multimediaType == .Audio {
            //music
            dic["description"] = msg.description != nil ? msg.description : msg.title
            dic["mediaUrl"] = msg.link
            dic["mediaDataUrl"] = msg.mediaDataUrl
            dic["objectType"] = "3"
            dic["thumbData"] = msg.thumbnail != nil ? self.imageData(msg.thumbnail!) : self.imageData(msg.image!, toSize: CGSizeMake(100, 100))
            dic["title"] = msg.title
        } else if msg.multimediaType == .Video {
            //video
            dic["description"] = msg.description != nil ? msg.description : msg.title
            dic["mediaUrl"] = msg.link
            dic["objectType"] = "4"
            dic["thumbData"] = msg.thumbnail != nil ? self.imageData(msg.thumbnail!) : self.imageData(msg.image!, toSize: CGSizeMake(100, 100))
            dic["title"] = msg.title
        } else if msg.multimediaType == .App {
            //app
            dic["description"] = msg.description != nil ? msg.description : msg.title;
            if msg.extInfo != nil {
                dic["extInfo"] = msg.extInfo
            }
            dic["fileData"] = self.imageData(msg.image!)
            dic["mediaUrl"] = msg.link
            dic["objectType"] = "7"
            dic["thumbData"] = msg.thumbnail != nil ? self.imageData(msg.thumbnail!) : self.imageData(msg.image!, toSize: CGSizeMake(100, 100))
            dic["title"] = msg.title
        } else if msg.multimediaType == .File {
            //file
            dic["description"] = msg.description != nil ? msg.description : msg.title
            dic["fileData"] = self.imageData(msg.image!)
            dic["objectType"] = "6"
            dic["fileExt"] = msg.fileExt != nil ? msg.fileExt : ""
            dic["thumbData"] = msg.thumbnail != nil ? self.imageData(msg.thumbnail!) : self.imageData(msg.image!, toSize: CGSizeMake(100, 100))
            dic["title"] = msg.title
        }
        let appId = self.appId(OSServiceTypeWeChat)!
        self.setGeneralPasteboardData("content", value: [appId: dic], encoding: .PropertyListSerialization)
        
        return "weixin://app/\(appId)/sendreq/?"
    }
    
    private static let wxHandleOpenURL: GDOSHandleOpenURLHandler = {(url) -> Bool in
        var result = false
        var data = Dictionary<String, AnyObject>()
        var error: NSError? = nil
        if url.scheme.hasPrefix("wx") {
            if url.absoluteString.rangeOfString("://oauth")?.isEmpty == false {
                //登陆auth
                data = GDOpenSocial.parseUrl(url)
            } else {
                let appId = GDOpenSocial.appId(OSServiceTypeWeChat)!
                let content = GDOpenSocial.generalPasteboardData("content", encoding: .PropertyListSerialization)
                if let result = content[appId] as? Dictionary<String, AnyObject> {
                    data = result
                    let result_code = (data["result"] as? NSString)?.integerValue ?? -1
                    if result_code != 0 {
                        if data["state"] as? String == "weixinauth" {
                            //登陆auth
                            error = NSError(domain: "com.opensocial.authwithwechat", code: result_code, userInfo: [NSLocalizedDescriptionKey:"Auth with \(OSServiceTypeWeChat) Failed"])
                        } else {
                            //分享
                            error = NSError(domain: "com.opensocial.sharetowechat", code: result_code, userInfo: [NSLocalizedDescriptionKey:"Share to \(OSServiceTypeWeChat) Failed"])
                        }
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
    
    private static func getWeChatAccessToken(appSecret: String, code: String, completionHandler handler: GDOSServiceCompletionHandler?) {
        guard let appid = self.appId(OSServiceTypeWeChat) else {
            print("place register\(OSServiceTypeWeChat)Api before you can use service with it!!!")
            return
        }
        let urlString = "https://api.weixin.qq.com/sns/oauth2/access_token?appid=\(appid)&secret=\(appSecret)&code=\(code)&grant_type=authorization_code"
        let url = NSURL(string: urlString);
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
                    let err = NSError(domain: "com.opensocial.getwechataccesstoken", code: -1, userInfo: [NSLocalizedDescriptionKey:"Access Token with \(OSServiceTypeWeChat) Failed"])
                    handler?([:], err)
                })
                return
            }
            print(String(data: validData, encoding: NSUTF8StringEncoding)!)
            do {
                let JSON = try NSJSONSerialization.JSONObjectWithData(validData, options: .AllowFragments)
                if let result = JSON as? [String: AnyObject] {
                    var err: NSError? = nil
                    if let errcode = result["errcode"] as? Int {
                        let errmsg = result["errmsg"] as? String ?? ""
                        err = NSError(domain: "com.opensocial.getwechataccesstoken", code: errcode, userInfo: [NSLocalizedDescriptionKey:"Access Token with \(OSServiceTypeWeChat) Failed: \(errmsg)"])
                    } else if result["access_token"] as? String == nil {
                        err = NSError(domain: "com.opensocial.getwechataccesstoken", code: -1, userInfo: [NSLocalizedDescriptionKey:"Access Token with \(OSServiceTypeWeChat) Failed"])
                    }
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        handler?(result, err)
                    })
                } else {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        let err = NSError(domain: "com.opensocial.getwechataccesstoken", code: -1, userInfo: [NSLocalizedDescriptionKey:"Access Token with \(OSServiceTypeWeChat) Failed"])
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
}
