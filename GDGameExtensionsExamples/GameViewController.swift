//
//  GameViewController.swift
//  GDGameExtensionsExamples
//
//  Created by Bell on 16/9/6.
//  Copyright (c) 2016年 GoshDo <http://goshdo.sinaapp.com>. All rights reserved.
//

import UIKit
import SpriteKit
import GDGameExtensions

class GameViewController: UIViewController {

    @IBOutlet weak var adView: GDAdBannerView!
    override func viewDidLoad() {
        super.viewDidLoad()

        if let scene = GameScene(fileNamed:"GameScene") {
            // Configure the view.
            let skView = self.view as! SKView
            skView.showsFPS = true
            skView.showsNodeCount = true
            
            /* Sprite Kit applies additional optimizations to improve rendering performance */
            skView.ignoresSiblingOrder = true
            
            /* Set the scale mode to scale to fit the window */
            scene.scaleMode = .AspectFill
            
            skView.presentScene(scene)
        }
/**-----------------------------GDGameExtensions Usage--------------------------------------*/
        // GDAds
        adView.admobAdUnitID = "ca-app-pub-4262535465518947/9872678116"
        adView.loadAds()
        adView.unloadAds()
        
        // GDCheckVersion
        GDCheckVersion(artistId: "appleid").canUpdate({ (version) -> Void in
            let dateformatter = NSDateFormatter()
            dateformatter.dateFormat = "yyyy'-'MM'-'dd"
            let date = dateformatter.stringFromDate(version.date)
            let alert = UIAlertController(title: "发现新版本 v\(version.value)", message: "发布时间：\(date)\n\(version.notes)", preferredStyle: .Alert)
            let cancel = UIAlertAction(title: "下次提醒", style: .Cancel, handler: nil)
            let ignore = UIAlertAction(title: "忽略该版本", style: .Default) { (action) -> Void in
                version.ignore()
            }
            let go = UIAlertAction(title: "前往App Store", style: .Default) { (action) -> Void in
                UIApplication.sharedApplication().openURL(version.url)
            }
            alert.addAction(cancel)
            alert.addAction(ignore)
            alert.addAction(go)
            self.presentViewController(alert, animated: true, completion: nil)
        }).mustUpdate({ (version) -> Void in
            let dateformatter = NSDateFormatter()
            dateformatter.dateFormat = "yyyy'-'MM'-'dd"
            let date = dateformatter.stringFromDate(version.date)
            let alert = UIAlertController(title: "发现新版本 v\(version.value)", message: "发布时间：\(date)\n\(version.notes)", preferredStyle: .Alert)
            let go = UIAlertAction(title: "前往App Store", style: .Default) { (action) -> Void in
                UIApplication.sharedApplication().openURL(version.url)
            }
            alert.addAction(go)
            self.presentViewController(alert, animated: true, completion: nil)
        })
        
        // GDGameCenter
        GDGameCenter.sharedGameCenter().authenticateLocalPlayer()
        GDGameCenter.sharedGameCenter().reportScore(100, forLeaderboardIdentifier: "LeaderboardIdentifier")
        GDGameCenter.sharedGameCenter().loadScoreOfLocalPlayer("LeaderboardIdentifier") { (score, error) in
            if error == nil {
                print("my score = \(score!)")
            }
        }
        GDGameCenter.sharedGameCenter().showLeaderboard("LeaderboardIdentifier")
        GDGameCenter.sharedGameCenter().reportAchievement(100, forAchievementIdentifier: "AchievementIdentifier")
        GDGameCenter.sharedGameCenter().loadAchievements { (achievements, error) in
            if error == nil {
                for achievement in achievements! {
                    print("AchievementIdentifier: \(achievement.identifier), percent: \(achievement.percentComplete)")
                }
            }
        }
        
        // GDInAppPurchase
        let productIdentifiers:Set<String> = ["productIdentifier1", "productIdentifier2", "..."]
        GDPayment.sharedPayment().productStore.preloadProducts(productIdentifiers)
        GDPayment.sharedPayment().purchase("productIdentifier1") { (paymentTransaction, error) -> Void in
            guard error == nil else { return }
            if let transaction = paymentTransaction {
                //Verify Receipt at Local
                GDPayment.sharedPayment().verifyReceipt(transaction, completedHandler: { (err) -> Void in
                    if err != nil {
                        // false with verify
                    } else {
                        // success with verify and do something
                    }
                })
            }
        }
        
        // GDOpenSocial
        // register appkey
        GDOpenSocial.registerQQApi("appkey")
        GDOpenSocial.registerWeChatApi("appkey")
        GDOpenSocial.registerWeiboApi("appkey")
        // auth
        GDOpenSocial.authQQ { (resultData, error) -> Void in
            if let access_token = resultData["access_token"] as? String {
                let openid = resultData["openid"] as! String
                GDOpenSocial.getQQUserInfo(access_token, openId: openid, completionHandler: { (userinfo, e) -> Void in
                    if e == nil {
                        let userName = userinfo["nickname"] as? String
                        let userIcon = userinfo["figureurl_2"] as? String
                        // success
                        print(openid, userName, userIcon)
                    } else {
                        //false
                    }
                })
            } else {
                //false
            }
        }
        GDOpenSocial.authWeChat { (resultData, error) -> Void in
            if let code = resultData["code"] as? String {
                GDOpenSocial.getWeChatUserInfo("appSecret", code: code, completionHandler: { (userinfo, e) -> Void in
                    if e == nil {
                        let openid = userinfo["openid"] as? String
                        let userName = userinfo["nickname"] as? String
                        let userIcon = userinfo["headimgurl"] as? String
                        // success
                        print(openid, userName, userIcon)
                    } else {
                        //false
                    }
                })
            } else {
                // false
            }
        }
        GDOpenSocial.authWeibo { (resultData, error) -> Void in
            if let accessToken = (resultData["transferObject"] as? Dictionary<String, AnyObject>)?["accessToken"] as? String {
                let openid = (resultData["transferObject"] as? Dictionary<String, AnyObject>)?["userID"] as! String
                GDOpenSocial.getWeiboUserInfo(accessToken, userID: openid, completionHandler: { (userinfo, e) -> Void in
                    if e == nil {
                        let userName = userinfo["screen_name"] as? String
                        let userIcon = userinfo["avatar_hd"] as? String
                        // success
                        print(openid, userName, userIcon)
                    } else {
                        //false
                    }
                })
            } else {
                // false
            }
        }
        // share
        let message = GDOSMessage()
        message.title = "title"
        message.description = "description"
        message.image = UIImage(named: "logo")
        message.link = "http://goshdo.sinaapp.com"
        GDOpenSocial.shareToQQZone(message) { (data, error) -> Void in
            if error == nil {
                // share success
            }
        }
        GDOpenSocial.shareToQQFriends(message) { (data, error) -> Void in
            if error == nil {
                // share success
            }
        }
        GDOpenSocial.shareToQQFavorites(message) { (data, error) -> Void in
            if error == nil {
                // share success
            }
        }
        GDOpenSocial.shareToQQDataline(message) { (data, error) -> Void in
            if error == nil {
                // share success
            }
        }
        GDOpenSocial.shareToWeChatSession(message) { (data, error) -> Void in
            if error == nil {
                // share success
            }
        }
        GDOpenSocial.shareToWeChatTimeline(message) { (data, error) -> Void in
            if error == nil {
                // share success
            }
        }
        GDOpenSocial.shareToWeChatFavorite(message) { (data, error) -> Void in
            if error == nil {
                // share success
            }
        }
        GDOpenSocial.shareToWeibo(message) { (data, error) -> Void in
            if error == nil {
                // share success
            }
        }
        GDOpenSocial.shareViewController = GDOpenSocialViewController(message: message)
        GDOpenSocial.shareViewController!.completionWithItemsHandler = { (activityType, completed, returnedItems, activityError) -> Void in
            if completed {
                if let at = activityType, excludedActivityTypes = GDOpenSocial.shareViewController!.excludedActivityTypes where !excludedActivityTypes.contains(at) {
                    // share success
                }
            }
        }
        presentViewController(GDOpenSocial.shareViewController!, animated: true, completion: nil)
        
        // GDRate
        GDRate.sharedReview().interval = 24*60*60 // 1 day
        GDRate.sharedReview().trackId = "appleid"
        GDRate.sharedReview().rateAlert()
    }

    override func shouldAutorotate() -> Bool {
        return true
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return .AllButUpsideDown
        } else {
            return .All
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
