//
//  GDCheckVersion.swift
//  GDCheckVersion
//
//  Created by Bell on 16/1/6.
//  Copyright © 2016年 GoshDo <http://goshdo.sinaapp.com>. All rights reserved.
//

import UIKit

@available(iOS 7.0, *)
public class GDCheckVersion {
    init(artistId: String) {
        let version = NSUserDefaults.standardUserDefaults().stringForKey("Version") ?? NSBundle.mainBundle().localizedInfoDictionary?["CFBundleShortVersionString"] as? String ?? NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let bundleId = NSBundle.mainBundle().localizedInfoDictionary?["CFBundleIdentifier"] as? String ?? NSBundle.mainBundle().infoDictionary?["CFBundleIdentifier"] as? String ?? ""
        let country = NSLocale.currentLocale().objectForKey(NSLocaleCountryCode) as? String ?? "US"
        check("/\(version)/\(bundleId)/\(artistId)/\(country)")
    }
    
    init(trackId: String) {
        let version = NSUserDefaults.standardUserDefaults().stringForKey("Version") ?? NSBundle.mainBundle().localizedInfoDictionary?["CFBundleShortVersionString"] as? String ?? NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let country = NSLocale.currentLocale().objectForKey(NSLocaleCountryCode) as? String ?? "US"
        check("/\(version)/\(trackId)/\(country)")
    }
    
    public func canUpdate(completionHandler:((Version) -> Void)) -> Self {
        canUpdateCompletionHandler = completionHandler
        return self
    }
    
    public func mustUpdate(completionHandler:((Version) -> Void)) -> Self {
        mustUpdateCompletionHandler = completionHandler
        return self
    }
    
    private var canUpdateCompletionHandler:((Version) -> Void)?
    private var mustUpdateCompletionHandler:((Version) -> Void)?
    
    private func check(parameters: String) {
        let url = "https://goshdo.sinaapp.com/checkVersion" + parameters
        let request = NSURLRequest(URL: NSURL(string: url)!)
        let session = NSURLSession(configuration: NSURLSessionConfiguration.ephemeralSessionConfiguration())
        let task = session.dataTaskWithRequest(request) { (data, response, error) -> Void in
            guard error == nil else {
                print(error!)
                return
            }
            guard let validData = data where validData.length > 0 else {
                print("JSON could not be serialized. Input data was nil or zero length.")
                return
            }
            print(String(data: validData, encoding: NSUTF8StringEncoding)!)
            do {
                let JSON = try NSJSONSerialization.JSONObjectWithData(validData, options: .AllowFragments)
                if let result = JSON as? [String: AnyObject] {
                    let code = result["code"] as? Int
                    if code == 1 {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.canUpdateCompletionHandler?(Version(result))
                        })
                    } else if code == 2 {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.mustUpdateCompletionHandler?(Version(result))
                        })
                    }
                }
                return
            } catch let e as NSError {
                print(e)
                return
            }
        }
        task.resume()
        session.finishTasksAndInvalidate()
    }
}

public struct Version {
    public var value: String
    public var date = NSDate()
    public var notes: String
    public var url: NSURL
    init(_ data:[String: AnyObject]) {
        value = data["version"] as? String ?? "1.0"
        if let releaseDate = data["releaseDate"] as? String {
            let dateformatter = NSDateFormatter()
            dateformatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
            date = dateformatter.dateFromString(releaseDate) ?? NSDate()
        }
        notes = data["releaseNotes"] as? String ?? ""
        url = NSURL(string: data["url"] as? String ?? "") ?? NSURL()
    }
    public func ignore() {
        NSUserDefaults.standardUserDefaults().setObject(value, forKey: "Version")
    }
}