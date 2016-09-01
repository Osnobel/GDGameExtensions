//
//  GDOpenSocialViewController.swift
//  GDOpenSocial
//
//  Created by Bell on 16/5/28.
//  Copyright © 2016年 GoshDo <http://goshdo.sinaapp.com>. All rights reserved.
//

import Foundation
import UIKit

@available(iOS 8.0, *)
public class OpenSocialViewController: UIActivityViewController {
    public var sourceView: UIView? = UIApplication.sharedApplication().keyWindow?.subviews.first {
        didSet {
            if let view = sourceView {
                popoverPresentationController?.sourceView = view
                popoverPresentationController?.sourceRect = view.frame
            }
        }
    }
    public init(message: GDOSMessage, checkThirdPartyLogin: Bool) {
        var activityItems: [AnyObject] = [message]
        if message.description != nil {
            activityItems.append(message.description!)
        }
        if message.image != nil {
            activityItems.append(message.image!)
        }
        if message.link != nil {
            activityItems.append(NSURL(string: message.link!)!)
        }
        var activities: [UIActivity]? = nil
        if checkThirdPartyLogin {
            activities = [GDOpenSocialWeChatSessionActivity(), GDOpenSocialWeChatTimelineActivity(), GDOpenSocialQQFriendsActivity(), GDOpenSocialQQZoneActivity(), GDOpenSocialWeiboActivity()]
        }
        
        super.init(activityItems: activityItems, applicationActivities: activities)
        if let view = sourceView {
            popoverPresentationController?.sourceView = view
            popoverPresentationController?.sourceRect = view.frame
        }
        popoverPresentationController?.permittedArrowDirections = .Any
        excludedActivityTypes = [UIActivityTypePrint, UIActivityTypeCopyToPasteboard, UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll, UIActivityTypeAddToReadingList, UIActivityTypeAirDrop]
        if #available(iOS 9.0, *) {
            excludedActivityTypes?.append(UIActivityTypeOpenInIBooks)
            excludedActivityTypes?.append("com.apple.reminders.RemindersEditorExtension")
            excludedActivityTypes?.append("com.apple.mobilenotes.SharingExtension")
        }
        // have app
        if GDOpenSocial.isWeiboApiAvailable && checkThirdPartyLogin {
            excludedActivityTypes?.append(UIActivityTypePostToWeibo)
        }
    }
    
//    private func _shouldExcludeActivityType(activity: UIActivity) -> Bool {
//        if (activity.classForCoder as! UIActivity.Type).activityCategory() == .Action {
//            return true
//        }
//        if let excludedActivityTypes = excludedActivityTypes {
//            if let activityType = activity.activityType() {
//                return excludedActivityTypes.contains(activityType)
//            }
//        }
//        return false
//    }
}

public extension GDOpenSocial {
    public static var shareViewController: OpenSocialViewController?
}

