//
//  GDAdBannerView.swift
//  GDAds
//
//  Created by Bell on 16/5/26.
//  Copyright © 2016年 Bell. All rights reserved.
//

import UIKit

public class GDAdBannerView: UIView, GDAdBannerBaseDelegate {
    public var admobAdUnitID: String = "ca-app-pub-4262535465518947/9872678116"
    
    private var _adBannerViews: [GDAdBannerBase] = []
    private var _currentBanner: GDAdBannerBase? {
        didSet {
            if self._currentBanner == oldValue {
                return
            }
            if let banner = self._currentBanner {
                self.bannerBaseSizeDidChanged(banner.bannerView.frame.size)
            } else {
                self.bannerBaseSizeDidChanged(CGSizeZero)
            }
        }
    }
    private var _rootViewController: UIViewController? {
        return self.findViewController(self)
    }
    
    private func findViewController(view: UIView) -> UIViewController? {
        if let vc = view.nextResponder() as? UIViewController {
            return vc
        } else if let superview = view.superview {
            return self.findViewController(superview)
        } else {
            return nil
        }
    }
    
    private var _widthConstraint: NSLayoutConstraint?
    private var _heightConstraint: NSLayoutConstraint?
    
    public func loadAds() {
        for constraint in self.constraints {
            if constraint.firstItem as? NSObject == self && constraint.firstAttribute == .Width {
                self._widthConstraint = constraint
            } else if constraint.firstItem as? NSObject == self && constraint.firstAttribute == .Height {
                self._heightConstraint = constraint
            }
        }
        
/**  
        //Starting July 1, 2016, iAd will no longer be available for developers to earn revenue by running ads sold by iAd or promote their apps on the iAd App Network.
         
        let iad = GDAdBannerIAd()
        iad.delegate = self
        iad.weight = 200
        iad.availableCountryCode = ["AU", "CA", "FR", "DE", "HK", "IE", "IT", "JP", "MX", "NZ", "ES", "TW", "GB", "US"]
        iad.create(self)
        self._adBannerViews.append(iad)
 **/
        
        let admob = GDAdBannerAdmob()
        admob.rootViewController = self._rootViewController
        admob.delegate = self
        admob.weight = 100
        admob.adUnitID = self.admobAdUnitID
        admob.create(self)
        self._adBannerViews.append(admob)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(GDAdBannerView.reload), name: UIApplicationWillEnterForegroundNotification, object: nil)
    }
    
    public func unloadAds() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        for banner in self._adBannerViews {
            banner.destroy()
        }
        self._adBannerViews.removeAll()
        _currentBanner = nil
    }
    
    @objc private func reload() {
        //处理非完全退出后重新进入时无法发起广告请求
        self.unloadAds()
        self.loadAds()
        //FIXME: 尚无法解决安装后admob首次运行无网络转有网络的情况
    }
    
    private func best() {
        var bestBanner: GDAdBannerBase?
        for banner in self._adBannerViews {
            if bestBanner != nil {
                bestBanner = banner.weight > bestBanner!.weight ? banner : bestBanner
            } else {
                bestBanner = banner.weight > 0 ? banner : nil
            }
        }
        if self._currentBanner != bestBanner {
            self._currentBanner?.visible = false
            bestBanner?.visible = true
            self._currentBanner = bestBanner
        }
    }
    
    //MARK: GDAdBannerBaseDelegate methods
    public func bannerBaseDidReceiveAd(banner: GDAdBannerBase!) {
        print("[GDAdBannerView]#bannerBaseDidReceiveAd.")
        self.best()
    }
    public func bannerBase(banner: GDAdBannerBase!, didFailToReceiveAdWithError error: NSError!) {
        print("[GDAdBannerView]#bannerBaseDidFailToReceiveAdWithError:\(error.localizedDescription).")
        self.best()
    }
    public func bannerBaseWillPresentScreen(banner: GDAdBannerBase!) {
        print("[GDAdBannerView]#bannerBaseWillPresentScreen.")
    }
    public func bannerBaseWillDismissScreen(banner: GDAdBannerBase!) {
        print("[GDAdBannerView]#bannerBaseWillDismissScreen.")
    }
    public func bannerBaseDidDismissScreen(banner: GDAdBannerBase!) {
        print("[GDAdBannerView]#bannerBaseDidDismissScreen.")
    }
    public func bannerBaseWillLeaveApplication(banner: GDAdBannerBase!) {
        print("[GDAdBannerView]#bannerBaseWillLeaveApplication.")
    }
    public func bannerBaseSizeDidChanged(size: CGSize) {
        print("[GDAdBannerView]#bannerBaseSizeDidChanged:\(size).")
        self._widthConstraint?.constant = size.width
        self._heightConstraint?.constant = size.height
        self.setNeedsUpdateConstraints()
        self.layoutIfNeeded()
    }
}