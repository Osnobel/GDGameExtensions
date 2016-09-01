//
//  GDAdBannerBase.swift
//  GDAds
//
//  Created by Bell on 16/5/25.
//  Copyright © 2016年 GoshDo <http://goshdo.sinaapp.com>. All rights reserved.
//

import UIKit

@objc public protocol GDAdBannerBaseDelegate : NSObjectProtocol {
    //MARK: Ad Request Lifecycle Notifications
    optional func bannerBaseDidReceiveAd(banner: GDAdBannerBase!)
    optional func bannerBase(banner: GDAdBannerBase!, didFailToReceiveAdWithError error: NSError!)
    //MARK: Click-Time Lifecycle Notifications
    optional func bannerBaseWillPresentScreen(banner: GDAdBannerBase!)
    optional func bannerBaseWillDismissScreen(banner: GDAdBannerBase!)
    optional func bannerBaseDidDismissScreen(banner: GDAdBannerBase!)
    optional func bannerBaseWillLeaveApplication(banner: GDAdBannerBase!)
    //MARK: Banner View Size Changed
    optional func bannerBaseSizeDidChanged(size: CGSize)
}

public class GDAdBannerBase: NSObject {
    weak public var delegate: GDAdBannerBaseDelegate?
    public var weight: UInt64 = 0
    public var visible: Bool = false {
        didSet {
            UIView.animateWithDuration(0.25, animations: {
//                self.bannerView.frame = self.bannerFrame
                self.bannerView.hidden = !self.visible
            })
            if self.visible {
                self.delegate?.bannerBaseSizeDidChanged?(self.bannerView.frame.size)
            }
        }
    }
//    public var onTop: Bool = false {
//        didSet {
//            self.bannerView.frame = self.bannerFrame
//        }
//    }
    private let frameKeyPath = "frame"
    private var frameContext = ""
    
    public var bannerView: UIView = UIView() {
        didSet {
            if self.bannerView == oldValue {
                return
            }
//            oldValue.removeObserver(self, forKeyPath: frameKeyPath, context: &frameContext)
//            self.bannerView.addObserver(self, forKeyPath: frameKeyPath, options: .Initial, context: &frameContext)
        }
    }
    
    public override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard let view = object as? UIView else { return }
        
        if context == &frameContext && keyPath == frameKeyPath && self.visible {
            self.delegate?.bannerBaseSizeDidChanged?(view.frame.size)
        }
    }
    
//    public var sizeBannerPortrait: CGSize {
//        return CGSizeZero
//    }
//    
//    public var sizeBannerLandscape: CGSize {
//        return CGSizeZero
//    }
    
//    public var bannerFrame: CGRect {
//        var frame = CGRectZero
//        let rootViewFrame = UIScreen.mainScreen().bounds
//        print(rootViewFrame)
//        if rootViewFrame.size.width < rootViewFrame.size.height {
//            frame.size = self.sizeBannerPortrait
//        } else {
//            frame.size = self.sizeBannerLandscape
//        }
//        if self.visible {
//            frame.origin.y = 0
//        } else if !self.visible && self.onTop {
//            frame.origin.y = -frame.size.height
//        } else if !self.visible && !self.onTop {
//            frame.origin.y = frame.size.height
//        }
//        return frame
//    }
    
    public func create(superview: UIView) {
        self.bannerView.addObserver(self, forKeyPath: frameKeyPath, options: .Initial, context: &frameContext)
    }
    
    public func destroy() {
        self.bannerView.removeObserver(self, forKeyPath: frameKeyPath, context: &frameContext)
    }
}