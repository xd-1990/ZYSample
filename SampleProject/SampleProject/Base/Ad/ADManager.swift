//
//  ADManager.swift
//  AITranslator
//
//  Created by 夏栋 on 2020/7/8.
//  Copyright © 2020 夏栋. All rights reserved.
//

import Foundation
import GoogleMobileAds

class ADManager: NSObject, GADInterstitialDelegate, GADBannerViewDelegate {
    static let shard = ADManager()
    var interstitial: GADInterstitial!
    var dicBannerCallBlock = [String: ((GADBannerView)->Void)]()
    var dicBannerCloseBlock = [String: (()->Void)]()
    var dicInterstitialCallBlock = [String: GADInterstitial]()
    var dicInterstitialCloseBlock = [String: (()->Void)]()
    var adLoader: GADAdLoader?
    var nativeAdBlock: ((GADUnifiedNativeAd?, String?)->Void) = {(ad, errMsg) in }
    var nativeCloseBlock: (()->Void)?

    // 测试广告
    private let interstitialTestKey = "ca-app-pub-3940256099942544/4411468910"
    private let bannerTestKey = "ca-app-pub-3940256099942544/2934735716"
    private let nativeTestKey = "ca-app-pub-3940256099942544/3986624511"
    
    private let interstitialKey = kAdInterstitialKey
    private let bannerKey = kAdBannerKey
    private let nativeKey = kAdNativeKey

    override init() {
        super.init()
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [kGADSimulatorID] as? [String]
        interstitial = createAndLoadInterstitial()
        
        NotificationCenter.default.addObserver(self, selector: #selector(removeAllAd), name: NSNotification.Name(PurcheaseMgr.shard.purchaseStateChange), object: nil)
    }
    
    @objc func removeAllAd() {
        if PurcheaseMgr.isVip() {
            for value in dicBannerCloseBlock.values {
                value()
            }
            
            nativeCloseBlock?()
        }
    }
    
    // MARK: - 插页
    func createAndLoadInterstitial() -> GADInterstitial {
        let interstitialItem = GADInterstitial(adUnitID: interstitialKey)
        interstitialItem.delegate = self
        interstitialItem.load(GADRequest())
        return interstitialItem
    }

    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        var keyFound = ""
        for key in dicInterstitialCallBlock.keys {
            if let adTemp = dicInterstitialCallBlock[key] {
                if adTemp == ad {
                    keyFound = key
                    let closeBlock = dicInterstitialCloseBlock[key]
                    closeBlock?()
                    break
                }
            }
        }
        
        dicInterstitialCloseBlock[keyFound] = nil
        dicInterstitialCallBlock[keyFound] = nil
        
        interstitial = createAndLoadInterstitial()
    }
    
    func hasAd() -> Bool {
        if PurcheaseMgr.isVip() {
            return false
        }
        
        return interstitial.isReady
    }
    
    func showAd(from: UIViewController, closeBlock: @escaping (()->Void)) -> Bool {
        if hasAd() {
            let key = NSStringFromClass(from.classForCoder)
            dicInterstitialCallBlock[key] = interstitial
            dicInterstitialCloseBlock[key] = closeBlock
            
            interstitial.present(fromRootViewController: from)
            
            return true
        } else {
            print("Ad wasn't ready")
        }
        
        return false
    }
    
    /// Tells the delegate an ad request succeeded.
    func interstitialDidReceiveAd(_ ad: GADInterstitial) {
      print("interstitialDidReceiveAd")
    }

    /// Tells the delegate an ad request failed.
    func interstitial(_ ad: GADInterstitial, didFailToReceiveAdWithError error: GADRequestError) {
      print("interstitial:didFailToReceiveAdWithError: \(error.localizedDescription)")
    }
    
    /// Tells the delegate the interstitial is to be animated off the screen.
    func interstitialWillDismissScreen(_ ad: GADInterstitial) {
        interstitialDidDismissScreen(ad)
    }
    
    // MARK: - 横幅
    func requestBanner(adUnit: String, from: UIViewController, callback: @escaping ((GADBannerView)->Void), closeBlock: @escaping (()->Void)) -> GADBannerView? {
        if PurcheaseMgr.isVip() {
            return nil
        }
        
        let key = NSStringFromClass(from.classForCoder)
        dicBannerCallBlock[key] = callback
        dicBannerCloseBlock[key] = closeBlock
        
        let bannerView = GADBannerView(adSize: GADAdSizeFromCGSize(CGSize(width: UIScreen.main.bounds.size.width, height: 50)))
        bannerView.adUnitID = bannerKey
        bannerView.rootViewController = from
        bannerView.delegate = self
        bannerView.load(GADRequest())
        return bannerView
    }
    
    /// Tells the delegate an ad request loaded an ad.
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        if let root = bannerView.rootViewController {
            let id = NSStringFromClass(root.classForCoder)
            if let callback = dicBannerCallBlock[id] {
                callback(bannerView)
            }
        }
      print("adViewDidReceiveAd")
    }

    /// Tells the delegate an ad request failed.
    func adView(_ bannerView: GADBannerView,
        didFailToReceiveAdWithError error: GADRequestError) {
      print("adView:didFailToReceiveAdWithError: \(error.localizedDescription)")
    }

    /// Tells the delegate that a full-screen view will be presented in response
    /// to the user clicking on an ad.
    func adViewWillPresentScreen(_ bannerView: GADBannerView) {
      print("adViewWillPresentScreen")
    }

    /// Tells the delegate that the full-screen view will be dismissed.
    func adViewWillDismissScreen(_ bannerView: GADBannerView) {
      print("adViewWillDismissScreen")
    }

    /// Tells the delegate that the full-screen view has been dismissed.
    func adViewDidDismissScreen(_ bannerView: GADBannerView) {
      print("adViewDidDismissScreen")
    }

    /// Tells the delegate that a user click will open another app (such as
    /// the App Store), backgrounding the current app.
    func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
      print("adViewWillLeaveApplication")
    }
}

extension ADManager: GADUnifiedNativeAdLoaderDelegate {
    
    // MARK: - 原生广告
    func hasNaviveAd() -> Bool {
        if PurcheaseMgr.isVip() {
            return false
        }
        
        return true
    }
    
    func requestNativeAd(from: UIViewController, result: @escaping ((GADUnifiedNativeAd?, String?)->Void), closeAd: @escaping (()->Void)) {
        if !hasNaviveAd() {
            return
        }
        
        nativeAdBlock = result
        nativeCloseBlock = closeAd
        
        adLoader = GADAdLoader(adUnitID: nativeKey, rootViewController: from, adTypes: [GADAdLoaderAdType.unifiedNative], options: nil)
        adLoader?.delegate = self
        adLoader?.load(GADRequest())
    }
    
    func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADUnifiedNativeAd) {
        nativeAdBlock(nativeAd, nil)
    }
    
    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: GADRequestError) {
        nativeAdBlock(nil, error.localizedDescription)
    }
}
