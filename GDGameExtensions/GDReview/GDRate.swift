//
//  GDRate.swift
//  GDRate
//
//  Created by Bell on 16/5/28.
//  Copyright © 2016年 Bell. All rights reserved.
//

import UIKit

public class GDRate: NSObject {
    // Singleton
    public static func sharedReview() -> GDRate {
        return _sharedInstance
    }
    private static let _sharedInstance = GDRate()
    private override init() { super.init() }
    // Singleton end
    public var interval: NSTimeInterval = 86400 // 1 day
    private var _lastAlertTime: NSTimeInterval {
        get {
            return NSUserDefaults.standardUserDefaults().doubleForKey("RateAlertTime")
        }
        set {
            NSUserDefaults.standardUserDefaults().setDouble(newValue, forKey: "RateAlertTime")
        }
    }
    public var trackId: String?
    public var rated: Bool {
        return self._rated
    }
    private var _rated: Bool {
        get {
            return NSUserDefaults.standardUserDefaults().boolForKey("RateApp\(self._version)")
        }
        set {
            if self._rated != newValue {
                NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: "RateApp\(self._version)")
            }
        }
    }
    private let _version = NSBundle.mainBundle().localizedInfoDictionary?["CFBundleShortVersionString"] as? String ?? NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let _bundleName = NSBundle.mainBundle().localizedInfoDictionary?["CFBundleDisplayName"] as? String ?? NSBundle.mainBundle().infoDictionary?["CFBundleDisplayName"] as? String ?? NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleName") as! String
    
    public func rate() {
        guard let trackId = self.trackId else {
            print("Invalid Track ID for Rate App")
            return
        }
        self._rated = true
        let requestString = "itms-apps://itunes.apple.com/app/id\(trackId)"
        print("[GDRate] Rate App request URL: [\(requestString)]")
        UIApplication.sharedApplication().openURL(NSURL(string: requestString)!)
    }
    
    public func rateAlert() {
        guard !self._rated else { return }
        guard NSDate().timeIntervalSinceDate(NSDate(timeIntervalSince1970: self._lastAlertTime)) > self.interval else { return }
        self._lastAlertTime = NSDate().timeIntervalSince1970
        let alert = UIAlertController(title: "Enjoying \(self._bundleName)?", message: nil, preferredStyle: .Alert)
        let cancel = UIAlertAction(title: "No, Thanks.", style: .Cancel, handler: nil)
        let rating = UIAlertAction(title: "Give us a rating on the App Store.", style: .Default) { (action) -> Void in
            self.rate()
        }
        let feedback = UIAlertAction(title: "Give us some feedback.", style: .Default) { (action) -> Void in
            self.rate()
        }
        alert.addAction(cancel)
        alert.addAction(rating)
        alert.addAction(feedback)
        UIApplication.sharedApplication().keyWindow?.rootViewController?.presentViewController(alert, animated: true, completion: nil)
    }
}