//
//  GDOpenSocialActivity+QQ.swift
//  GDOpenSocial
//
//  Created by Bell on 16/1/18.
//  Copyright © 2016年 BINGZHONG ZENG. All rights reserved.
//

import Foundation
import UIKit

public let UIActivityTypePostToQQFriends: String = "com.opensocial.activity.PostToQQFriends"
public let UIActivityTypePostToQQZone: String = "com.opensocial.activity.PostToQQZone"

public class GDOpenSocialQQFriendsActivity: GDOpenSocialActivity {
    public override func activityType() -> String? {
        return UIActivityTypePostToQQFriends
    }
    
    public override func activityTitle() -> String? {
        return NSBundle.mainBundle().preferredLocalizations.first == "zh-Hans" ? "QQ好友" : "QQ Friends"
    }
    
    public override func activityImageBase64EncodedString() -> String? {
        return "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"
    }
    
    public override func canPerformWithActivityItems(activityItems: [AnyObject]) -> Bool {
        return super.canPerformWithActivityItems(activityItems) && GDOpenSocial.isQQApiAvailable
    }
    
    public override func performActivity() {
        GDOpenSocial.shareToQQFriends(message) { (data, error) -> Void in
            if error == nil {
                self.activityDidFinish(true)
            } else {
                self.activityDidFinish(false)
            }
        }
    }
}

public class GDOpenSocialQQZoneActivity: GDOpenSocialActivity {
    public override func activityType() -> String? {
        return UIActivityTypePostToQQZone
    }
    
    public override func activityTitle() -> String? {
        return NSBundle.mainBundle().preferredLocalizations.first == "zh-Hans" ? "QQ空间" : "Qzone"
    }
    
    public override func activityImageBase64EncodedString() -> String? {
        return "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"
    }
    
    public override func canPerformWithActivityItems(activityItems: [AnyObject]) -> Bool {
        return super.canPerformWithActivityItems(activityItems) && GDOpenSocial.isQQApiAvailable
    }
    
    public override func performActivity() {
        GDOpenSocial.shareToQQZone(message) { (data, error) -> Void in
            if error == nil {
                self.activityDidFinish(true)
            } else {
                self.activityDidFinish(false)
            }
        }
    }
}