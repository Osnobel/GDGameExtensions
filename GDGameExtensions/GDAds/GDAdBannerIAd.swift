//
//  GDAdBannerIAd.swift
//  GDAds
//
//  Created by Bell on 16/5/26.
//  Copyright © 2016年 GoshDo <http://goshdo.sinaapp.com>. All rights reserved.
//

import iAd

// Starting July 1, 2016, iAd will no longer be available for developers to earn revenue by running ads sold by iAd or promote their apps on the iAd App Network.
@available(*, deprecated)
class GDAdBannerIAd: GDAdBannerBase, ADBannerViewDelegate {
    var availableCountryCode: [String] = []
    private var _statusCode: UInt64 = 0
    private var _weight: UInt64 = 0
    override init() {
        super.init()
        self.bannerView = ADBannerView(adType: .Banner)
    }
    
    override func create(superview: UIView) {
        if let bannerView = self.bannerView as? ADBannerView {
            bannerView.delegate = self
            superview.addSubview(bannerView)
            bannerView.hidden = true
            print("[GDAdBannerIAd]#create.")
        }
        super.create(superview)
    }
    
    override func destroy() {
        super.destroy()
        if let bannerView = self.bannerView as? ADBannerView {
            bannerView.delegate = nil
            bannerView.removeFromSuperview()
            self.visible = false
            print("[GDAdBannerIAd]#destroy.")
        }
    }
    
    override var weight: UInt64 {
        get {
            let available: UInt64 = self.availableCountryCode.contains(NSLocale.currentLocale().objectForKey(NSLocaleCountryCode) as! String) ? 1 : 0
            print("[GDAdBannerIAd]#weight=\(self._weight), status_code=\(self._statusCode), country_code_is_available=\(available).")
            return self._weight * self._statusCode * available
        }
        set {
            self._weight = newValue
        }
    }
    
    //MARK: ADBannerViewDelegate methods
    // 当 requiredContentSizeIdentifiers 成功时发送
    func bannerViewDidLoadAd(banner: ADBannerView!) {
        self._statusCode = 1
        self.delegate?.bannerBaseDidReceiveAd?(self)
    }
    // 当 requiredContentSizeIdentifiers 失败时发送
    func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
        self._statusCode = 0
        self.delegate?.bannerBase?(self, didFailToReceiveAdWithError: error)
    }
    // 在系统响应用户触摸发送者的操作而即将向其展示全屏广告用户界面时发送
    func bannerViewActionShouldBegin(banner: ADBannerView!, willLeaveApplication willLeave: Bool) -> Bool {
        self.delegate?.bannerBaseWillPresentScreen?(self)
        if willLeave {
            self.delegate?.bannerBaseWillLeaveApplication?(self)
        }
        return true
    }
    // 当用户已退出发送者的全屏用户界面时发送
    func bannerViewActionDidFinish(banner: ADBannerView!) {
        self.delegate?.bannerBaseDidDismissScreen?(self)
    }
}