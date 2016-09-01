//
//  GDOpenSocialActivity.swift
//  GDOpenSocial
//
//  Created by Bell on 16/1/18.
//  Copyright © 2016年 BINGZHONG ZENG. All rights reserved.
//

import Foundation
import UIKit

public class GDOpenSocialActivity: UIActivity {
    public override class func activityCategory() -> UIActivityCategory {
        return .Share
    }
    
    public override func activityImage() -> UIImage? {
        if let imageString = activityImageBase64EncodedString() {
            return UIImage(data: NSData(base64EncodedString: imageString, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)!)
        }
        return nil
    }
    
    public override func canPerformWithActivityItems(activityItems: [AnyObject]) -> Bool {
        for item in activityItems {
            if item is GDOSMessage {
                return true
            }
        }
        return false
    }
    
    public override func prepareWithActivityItems(activityItems: [AnyObject]) {
        for item in activityItems {
            if item is GDOSMessage {
                _message = item as! GDOSMessage
            }
        }
    }
    
    public func activityImageBase64EncodedString() -> String? {
        return nil
    }
    
    public var message: GDOSMessage {
        get {
            return _message
        }
    }
    
    private var _message = GDOSMessage()
}