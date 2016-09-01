//
//  GDOpenSocial+QQ.swift
//  GDOpenSocial
//
//  Created by BINGZHONG ZENG on 15/11/6.
//  Copyright © 2015年 BINGZHONG ZENG. All rights reserved.
//

import UIKit

public extension GDOpenSocial {
    public static var isQQInstalled: Bool {
        get {
            return self.canOpenURLString("mqqapi://")
        }
    }
    
    public static var getQQInstallUrl: NSURL {
        get {
            return NSURL(string: "https://itunes.apple.com/cn/app/id444934666?mt=8")!
        }
    }
    
    public static var isQQApiAvailable: Bool {
        get {
            return self.isQQInstalled && (self.appId(OSServiceTypeQQ) != nil)
        }
    }
    
    public static func registerQQApi(appId: String) {
        self.cacheService(OSServiceTypeQQ, schemes: [self.qqCallbackName(appId), "tencent\(appId)", "tencent\(appId).content"], appId: appId, handleOpenURLHandler: self.qqHandleOpenURL)
    }
    
    public static func shareToQQFriends(message: GDOSMessage, completionHandler handler: GDOSServiceCompletionHandler?) {
        if self.canService(OSServiceTypeQQ, completionHandler: handler) {
            self.openURLString(self.genQQShareUrl(message, to:0))
        }
    }
    
    public static func shareToQQZone(message: GDOSMessage, completionHandler handler: GDOSServiceCompletionHandler?) {
        if self.canService(OSServiceTypeQQ, completionHandler: handler) {
            self.openURLString(self.genQQShareUrl(message, to:1))
        }
    }
    
    public static func shareToQQFavorites(message: GDOSMessage, completionHandler handler: GDOSServiceCompletionHandler?) {
        if self.canService(OSServiceTypeQQ, completionHandler: handler) {
            self.openURLString(self.genQQShareUrl(message, to:8))
        }
    }
    
    public static func shareToQQDataline(message: GDOSMessage, completionHandler handler: GDOSServiceCompletionHandler?) {
        if self.canService(OSServiceTypeQQ, completionHandler: handler) {
            self.openURLString(self.genQQShareUrl(message, to:16))
        }
    }
    // scope = "get_user_info,get_simple_userinfo,add_album,add_idol,add_one_blog,add_pic_t,add_share,add_topic,check_page_fans,del_idol,del_t,get_fanslist,get_idollist,get_info,get_other_info,get_repost_list,list_album,upload_pic,get_vip_info,get_vip_rich_info,get_intimate_friends_weibo,match_nick_tips_weibo"
    public static func authQQ(scope: String = "get_user_info,get_simple_userinfo,add_share", completionHandler handler: GDOSServiceCompletionHandler?) {
        if self.canService(OSServiceTypeQQ, completionHandler: handler) {
            let appid = self.appId(OSServiceTypeQQ)!
            let authData: Dictionary<String, AnyObject> = ["app_id" : appid,
                "app_name" : self.bundleDisplayName,
                "client_id" : appid,
                "response_type" : "token",
                "scope" : scope,
                "sdkp" : "i",
                "sdkv" : "2.9.3",
                "status_machine" : UIDevice.currentDevice().model,
                "status_os" : UIDevice.currentDevice().systemVersion,
                "status_version" : UIDevice.currentDevice().systemVersion]
            self.setGeneralPasteboardData("com.tencent.tencent\(appid)", value: authData, encoding: .KeyedArchiver)
            
            let authUrlString = "mqqOpensdkSSoLogin://SSoLogin/tencent\(appid)/com.tencent.tencent\(appid)?generalpastboard=1&sdkv=2.9.3"
            self.openURLString(authUrlString)
        }
    }
    
    public static func getQQUserInfo(accessToken: String, openId: String, completionHandler handler: GDOSServiceCompletionHandler?) {
        guard let appid = self.appId(OSServiceTypeQQ) else {
            print("place register\(OSServiceTypeQQ)Api before you can use service with it!!!")
            return
        }
        let urlString = "https://openmobile.qq.com/user/get_simple_userinfo?openid=\(openId)&oauth_consumer_key=\(appid)&access_token=\(accessToken)"
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
                    let err = NSError(domain: "com.opensocial.getqquserinfo", code: -1, userInfo: [NSLocalizedDescriptionKey:"Get User Info with \(OSServiceTypeQQ) Failed"])
                    handler?([:], err)
                })
                return
            }
            print(String(data: validData, encoding: NSUTF8StringEncoding)!)
            do {
                let JSON = try NSJSONSerialization.JSONObjectWithData(validData, options: .AllowFragments)
                if let result = JSON as? [String: AnyObject] {
                    var err: NSError? = nil
                    let errcode = result["ret"] as? Int ?? -1
                    if errcode != 0 {
                        let errmsg = result["msg"] as? String ?? ""
                        err = NSError(domain: "com.opensocial.getqquserinfo", code: errcode, userInfo: [NSLocalizedDescriptionKey:"Get User Info with \(OSServiceTypeQQ) Failed: \(errmsg)"])
                    }
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        handler?(result, err)
                    })
                } else {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        let err = NSError(domain: "com.opensocial.getqquserinfo", code: -1, userInfo: [NSLocalizedDescriptionKey:"Get User Info with \(OSServiceTypeQQ) Failed"])
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
    
    private static let OSServiceTypeQQ: String = "QQ"
    private static func qqCallbackName(appId: String) -> String {
        return String(format: "QQ%08llx", NSString(string: appId).longLongValue)
    }
    
    private static func genQQShareUrl(message: GDOSMessage, to: Int) -> String {
        let msg = message
        var ret: String = "mqqapi://share/to_fri?thirdAppDisplayName="
        ret += self.base64Encode(self.bundleDisplayName)
        ret += "&version=1&cflag=\(to)"
        ret += "&callback_type=scheme&generalpastboard=1&callback_name=\(self.qqCallbackName(self.appId(OSServiceTypeQQ)!))"
        ret += "&src_type=app&shareType=0&file_type="
        
        if msg.link != nil && msg.multimediaType == nil {
            msg.multimediaType = .News
        }
        
        if msg.image == nil && msg.link == nil && msg.title != nil {
            //纯文本分享
            ret += "text&file_data="
            ret += self.urlEncode(self.base64Encode(msg.title!))
        } else if msg.link == nil && msg.title != nil && msg.image != nil && msg.description != nil {
            //图片分享
            var data: Dictionary<String, AnyObject> = [:]
            data["file_data"] = self.imageData(msg.image!)
            data["previewimagedata"] = msg.thumbnail != nil ? self.imageData(msg.thumbnail!) : self.imageData(msg.image!, toSize: CGSizeMake(36, 36))
            self.setGeneralPasteboardData("com.tencent.mqq.api.apiLargeData", value: data, encoding: .KeyedArchiver)
            
            ret += "img&title="
            ret += self.base64Encode(msg.title!)
            ret += "&objectlocation=pasteboard&description="
            ret += self.base64Encode(msg.description!)
        } else if msg.title != nil && msg.image != nil && msg.description != nil && msg.link != nil && msg.multimediaType != nil {
            //新闻／多媒体分享（图片加链接）发送新闻消息 预览图像数据，最大1M字节 URL地址,必填 最长512个字符
            let data: Dictionary<String, AnyObject> = ["previewimagedata": self.imageData(msg.image!)]
            self.setGeneralPasteboardData("com.tencent.mqq.api.apiLargeData", value: data, encoding: .KeyedArchiver)
            var msgType = "news"
            if (msg.multimediaType == .Audio) {
                msgType = "audio"
            }
            
            ret += msgType
            ret += "&title=" + self.urlEncode(self.base64Encode(msg.title!))
            ret += "&url=" + self.urlEncode(self.base64Encode(msg.link!))
            ret += "&description=" + self.urlEncode(self.base64Encode(msg.description!))
            ret += "&objectlocation=pasteboard"
        }
        return ret
    }
    
    private static let qqHandleOpenURL: GDOSHandleOpenURLHandler = {(url) -> Bool in
        var result = false
        var data = Dictionary<String, AnyObject>()
        var error: NSError? = nil
        if url.scheme.hasPrefix("QQ") {
            //分享
            data = GDOpenSocial.parseUrl(url)
            if let err_desc = data["error_description"] as? String {
                data["error_description"] = GDOpenSocial.base64Decode(err_desc)
            }
            let err_code = (data["error"] as? NSString)?.integerValue ?? -1
            if err_code != 0 {
                error = NSError(domain: "com.opensocial.sharetoqq", code: err_code, userInfo: [NSLocalizedDescriptionKey:data["error_description"] as? String ?? "Share to \(OSServiceTypeQQ) Failed"])
            }
            result = true
        } else if url.scheme.hasPrefix("tencent") {
            //登陆auth
            let appId = GDOpenSocial.appId(OSServiceTypeQQ)!
            data = GDOpenSocial.generalPasteboardData("com.tencent.tencent\(appId)", encoding: .KeyedArchiver)
            let ret_code = data["ret"] as? Int ?? -1
            if ret_code != 0 {
                error = NSError(domain: "com.opensocial.authwithqq", code: ret_code, userInfo: [NSLocalizedDescriptionKey:"Auth with \(OSServiceTypeQQ) Failed"])
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