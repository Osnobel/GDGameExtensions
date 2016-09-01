//
//  GDAdBannerAdmob.swift
//  GDAds
//
//  Created by Bell on 16/5/26.
//  Copyright © 2016年 GoshDo <http://goshdo.sinaapp.com>. All rights reserved.
//

import GoogleMobileAds

public class GDAdBannerAdmob: GDAdBannerBase, GADBannerViewDelegate {
    public class var sdkVersion: String {
        return "Google Mobile Ads SDK: [\(GADRequest.sdkVersion())]"
    }
    weak public var rootViewController: UIViewController?
    public var adUnitID: String = ""
    private var _statusCode: UInt64 = 0
    private var _weight: UInt64 = 0
    public override init() {
        super.init()
        self.bannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(GDAdBannerAdmob.changeSize), name: UIApplicationDidChangeStatusBarOrientationNotification, object: nil)
        
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    public override func create(superview: UIView) {
        guard let rootViewController = self.rootViewController else {
            print("Invalid RootViewController for GADBannerView")
            return
        }
        if let bannerView = self.bannerView as? GADBannerView {
            bannerView.delegate = self
            superview.addSubview(bannerView)
            bannerView.hidden = true
            bannerView.adUnitID = self.adUnitID
            bannerView.rootViewController = rootViewController
            let request = GADRequest()
            request.testDevices = [kGADSimulatorID]
            bannerView.loadRequest(request)
            self.changeSize()
            print("[GDAdBannerAdmob]#create.")
        }
        super.create(superview)
    }
    
    public override func destroy() {
        super.destroy()
        if let bannerView = self.bannerView as? GADBannerView {
            bannerView.delegate = nil
            bannerView.removeFromSuperview()
            self.visible = false
            print("[GDAdBannerAdmob]#destroy.")
        }
    }
    
    public override var weight: UInt64 {
        get {
            print("[GDAdBannerAdmob]#weight=\(self._weight), status_code=\(self._statusCode).")
            return self._weight * self._statusCode
        }
        set {
            self._weight = newValue
        }
    }
    
    @objc private func changeSize() {
        guard let bannerView = self.bannerView as? GADBannerView else { return }
        if UIApplication.sharedApplication().statusBarOrientation.isPortrait {
            bannerView.adSize = kGADAdSizeSmartBannerPortrait
        } else {
            bannerView.adSize = kGADAdSizeSmartBannerLandscape
        }
        self.delegate?.bannerBaseSizeDidChanged?(bannerView.frame.size)
    }
    
    //MARK: GADBannerViewDelegate methods
    // 当 loadRequest: 成功时发送
    public func adViewDidReceiveAd(bannerView: GADBannerView!) {
        self._statusCode = 1
        self.delegate?.bannerBaseDidReceiveAd?(self)
    }
    
    // 当 loadRequest: 失败时发送
    public func adView(bannerView: GADBannerView!, didFailToReceiveAdWithError error: GADRequestError!) {
        self._statusCode = 0
        self.delegate?.bannerBase?(self, didFailToReceiveAdWithError: error)
    }
    // 在系统响应用户触摸发送者的操作而即将向其展示全屏广告用户界面时发送
    public func adViewWillPresentScreen(bannerView: GADBannerView!) {
        self.delegate?.bannerBaseWillPresentScreen?(self)
    }
    // 在用户关闭发送者的全屏用户界面前发送
    public func adViewWillDismissScreen(bannerView: GADBannerView!) {
        self.delegate?.bannerBaseWillDismissScreen?(self)
    }
    // 当用户已退出发送者的全屏用户界面时发送
    public func adViewDidDismissScreen(bannerView: GADBannerView!) {
        self.delegate?.bannerBaseDidDismissScreen?(self)
    }
    // 在应用因为用户触摸 Click-to-App-Store 或 Click-to-iTunes 横幅广告而转至后台或终止运行前发送
    public func adViewWillLeaveApplication(bannerView: GADBannerView!) {
        self.delegate?.bannerBaseWillLeaveApplication?(self)
    }
}