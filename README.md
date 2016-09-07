# GDGameExtensions

[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-brightgreen.svg?style=flat)](https://github.com/Carthage/Carthage)
[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](https://github.com/Osnobel/GDGameExtensions/blob/master/LICENSE)
[![Platform](https://img.shields.io/badge/platform-ios-lightgrey.svg?style=flat)](https://github.com/Osnobel/GDGameExtensions)

## Requirements

- iOS 8.0+
- Xcode 7.3+

## Getting Started

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate Alamofire into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "Osnobel/GDGameExtensions" ~> 1.0
```

Run `carthage update` to build the framework and drag the built `GDGameExtensions.framework` into your Xcode project.

### Source Files / Git Submodule

- Open up Terminal, `cd` into your top-level project directory, and run the following command "if" your project is not initialized as a git repository:

```bash
$ git init
```

- Add GDGameExtensions as a git [submodule](http://git-scm.com/docs/git-submodule) by running the following command:

```bash
$ git submodule add https://github.com/Osnobel/GDGameExtensions.git
```

- Open the new `GDGameExtensions` folder, and drag the `GDGameExtensions.xcodeproj` into the Project Navigator of your application's Xcode project.

> It should appear nested underneath your application's blue project icon. Whether it is above or below all the other Xcode groups does not matter.

- Select the `GDGameExtensions.xcodeproj` in the Project Navigator and verify the deployment target matches that of your application target.
- Next, select your application project in the Project Navigator (blue project icon) to navigate to the target configuration window and select the application target under the "Targets" heading in the sidebar.
- In the tab bar at the top of that window, open the "General" panel.
- Click on the `+` button under the "Embedded Binaries" section.
- You will see a `GDGameExtensions.xcodeproj` folders of the `GDGameExtensions.framework` nested inside a `Products` folder.

- And that's it!

> The `GDGameExtensions.framework` is automagically added as a target dependency, linked framework and embedded framework in a copy files build phase which is all you need to build on the simulator and a device.

---

## Usage

### Add a GDAdBannerView

#### Add a GDADBannerView in storyboard

![](https://firebase.google.com/docs/admob/images/ios-quickstart-08.png)

Open Main.storyboard. In the Object library in the bottom right corner, search for UIView, and drag a UIView element into your view controller. Then in the Identity inspector in the top right corner, give this view the custom class `GDADBannerView`.

#### Add constraints on the GDADBannerView

We'll set constraints on the `GDADBannerView` to center it at the bottom of the screen, and have a size of 320x50.

![](https://firebase.google.com/docs/admob/images/ios-quickstart-09.png)

Make sure the view is selected, and click the Pin icon at the bottom of the screen. Add a Spacing to nearest neighbor constraint on the bottom of the banner with the value of 0. This will pin the view to the bottom of the screen.

Also check the width and height constraints and set the values to 320 and 50, respectively, to set the size of the view.

![](https://firebase.google.com/docs/admob/images/ios-quickstart-10.png)

Next, click the Align icon to the left of the Pin icon, and add a constraint for Horizontal Center in Container with a value of 0.

![](https://firebase.google.com/docs/admob/images/ios-quickstart-11.png)

After making changes to constraints, you can see where your view will be positioned by selecting the Resolve Auto Layout Issues icon to the right of Pin and selecting Update frames.

![](https://firebase.google.com/docs/admob/images/ios-quickstart-12.png)

The banner will now be correctly positioned.

#### Adding a reference to your GDADBannerView in code

![](https://firebase.google.com/docs/admob/images/ios-quickstart-13.png)

The `GDADBannerView` needs a reference in code to load ads into it. Open up the Assistant Editor by navigating to **View > Assistant Editor > Show Assistant Editor**. In the assistant editor, make sure the `ViewController.h` file is showing. Next, holding the control key, click the `GDADBannerView` and drag your cursor over to `ViewController.h`. For a Swift project, follow the steps above, but add a reference to the `GDADBannerView` in the `ViewController.swift` file.

![](https://firebase.google.com/docs/admob/images/ios-quickstart-14.png)

Xcode will generate and connect a property for you. Name it "bannerView", and select **Connect**.
```swift
import GDGameExtensions

class ViewController: UIViewController {

    @IBOutlet weak var bannerView: GDADBannerView!

    override func viewDidLoad() {
        super.viewDidLoad()

        bannerView.admobAdUnitID = "ca-app-pub-4262535465518947/9872678116"
        bannerView.loadAds()
    }
} 
```

#### Remove Ads for GDADBannerView
```swift
bannerView.unloadAds()
```

### Add a check for version
```swift
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
```

### Use Game Center
```swift
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
```

### Use In App Purchase
```swift
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
```

### Share with GDOpenSocial
> Use Swift rewrite Object-C project [OpenShare](https://github.com/100apps/openshare). Auth identity and share infomation with no QQ, wechat, weibo SDK. Please see [more](http://www.gfzj.us/series/openshare/).

#### Add call back in AppDelegate
```swift
func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
    return GDOpenSocial.handleOpenURL(url)
}
```

#### Register appkey
```swift
GDOpenSocial.registerQQApi("appkey")
GDOpenSocial.registerWeChatApi("appkey")
GDOpenSocial.registerWeiboApi("appkey")
```

### Auth
```swift
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
```

#### Share
```swift
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
```
Use GDOpenSocialViewController to share
```swift
GDOpenSocial.shareViewController = GDOpenSocialViewController(message: message)
GDOpenSocial.shareViewController!.completionWithItemsHandler = { (activityType, completed, returnedItems, activityError) -> Void in
    if completed {
        if let at = activityType, excludedActivityTypes = GDOpenSocial.shareViewController!.excludedActivityTypes where !excludedActivityTypes.contains(at) {
        // share success
        }
    }
}
presentViewController(GDOpenSocial.shareViewController!, animated: true, completion: nil)
```

### Show the Rate Alert
```swift
GDRate.sharedReview().interval = 24*60*60 // 1 day
GDRate.sharedReview().trackId = "appleid"
GDRate.sharedReview().rateAlert()
```

## Credits

GDGameExtensions is owned and maintained by the [Goshdo](http://goshdo.sinaapp.com).

## License

GDGameExtensions is released under the MIT license. See LICENSE for details.