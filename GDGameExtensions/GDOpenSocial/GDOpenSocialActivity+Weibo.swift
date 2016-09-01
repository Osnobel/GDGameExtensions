//
//  GDOpenSocialActivity+Weibo.swift
//  GDOpenSocial
//
//  Created by Bell on 16/5/28.
//  Copyright © 2016年 GoshDo <http://goshdo.sinaapp.com>. All rights reserved.
//

import Foundation
import UIKit

public let UIActivityTypePostToWeiboApp: String = "com.opensocial.activity.PostToWeiboApp"

public class GDOpenSocialWeiboActivity: GDOpenSocialActivity {
    public override func activityType() -> String? {
        return UIActivityTypePostToWeiboApp
    }
    
    public override func activityTitle() -> String? {
        return NSBundle.mainBundle().preferredLocalizations.first == "zh-Hans" ? "新浪微博" : "Sina Weibo"
    }
    
    public override func activityImageBase64EncodedString() -> String? {
        return "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"
    }
    
    public override func canPerformWithActivityItems(activityItems: [AnyObject]) -> Bool {
        return super.canPerformWithActivityItems(activityItems) && GDOpenSocial.isWeiboApiAvailable
    }
    
    public override func performActivity() {
        GDOpenSocial.shareToWeibo(message) { (data, error) -> Void in
            if error == nil {
                self.activityDidFinish(true)
            } else {
                self.activityDidFinish(false)
            }
        }
    }
}