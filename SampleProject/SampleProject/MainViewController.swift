//
//  ViewController.swift
//  SampleProject
//
//  Created by 夏栋 on 2021/3/2.
//

import Foundation
import GoogleMobileAds
class MainViewController: BaseViewController {
    @IBOutlet weak var nativeAdPlaceholder: UIView!
    var nativeAdView: GADUnifiedNativeAdView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 加载banner广告
        addBannerAd()
        
        // 加载原生广告
        getNativeAd()
    }
    
    @IBAction func testAd(_ sender: Any) {
        ADManager.shard.showAd(from: self) {
            debugPrint("Ad dismiss")
        }
    }

}

// MARK: - 原生广告
extension MainViewController {
    func setAdView(_ view: GADUnifiedNativeAdView, ad: GADUnifiedNativeAd) {
        // Remove the previous ad view.
        nativeAdView = view
        nativeAdPlaceholder.addSubview(nativeAdView!)
        nativeAdView!.translatesAutoresizingMaskIntoConstraints = false

        // Layout constraints for positioning the native ad view to stretch the entire width and height
        // of the nativeAdPlaceholder.
        let viewDictionary = ["_nativeAdView": nativeAdView!]
        self.view.addConstraints(
        NSLayoutConstraint.constraints(
          withVisualFormat: "H:|[_nativeAdView]|",
          options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: viewDictionary)
        )
        self.view.addConstraints(
        NSLayoutConstraint.constraints(
          withVisualFormat: "V:|[_nativeAdView]|",
          options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: viewDictionary)
        )
        
        func imageOfStars(from starRating: NSDecimalNumber?) -> UIImage? {
            guard let rating = starRating?.doubleValue else {
                return nil
            }
            if rating >= 5 {
                return UIImage(named: "stars_5")
            } else if rating >= 4.5 {
                return UIImage(named: "stars_4_5")
            } else if rating >= 4 {
                return UIImage(named: "stars_4")
            } else if rating >= 3.5 {
                return UIImage(named: "stars_3_5")
            } else {
                return nil
            }
        }
        
        if let lblHead = nativeAdView!.headlineView as? UILabel {
            lblHead.text = ad.headline
        }

        nativeAdView!.mediaView?.mediaContent = ad.mediaContent

        if let mediaView = nativeAdView!.mediaView, ad.mediaContent.aspectRatio > 0 {
            let heightConstraint = NSLayoutConstraint(
              item: mediaView,
              attribute: .height,
              relatedBy: .equal,
              toItem: mediaView,
              attribute: .width,
              multiplier: CGFloat(1 / ad.mediaContent.aspectRatio),
              constant: 0)
            heightConstraint.isActive = true
        }

        if let lblBody = nativeAdView!.bodyView as? UILabel {
            lblBody.text = ad.body
            lblBody.isHidden = ad.body == nil
        }

        if let lblCall = nativeAdView!.callToActionView as? UIButton {
            lblCall.setTitle(ad.callToAction, for: .normal)
            lblCall.isHidden = ad.callToAction == nil
        }

        if let imgIcon = nativeAdView!.iconView as? UIImageView {
            imgIcon.image = ad.icon?.image
            imgIcon.isHidden = ad.icon == nil
        }

        if let imgStar = nativeAdView!.starRatingView as? UIImageView {
            imgStar.image = imageOfStars(from: ad.starRating)
            imgStar.isHidden = ad.starRating == nil
        }

        if let lblStore = nativeAdView!.storeView as? UILabel {
            lblStore.text = ad.store
            lblStore.isHidden = ad.store == nil
        }

        if let lblPrice = nativeAdView!.priceView as? UILabel {
            lblPrice.text = ad.price
            lblPrice.isHidden = ad.price == nil
        }

        if let lblAd = nativeAdView!.advertiserView as? UILabel {
            lblAd.text = ad.advertiser
            lblAd.isHidden = ad.advertiser == nil
        }

        nativeAdView!.callToActionView?.isUserInteractionEnabled = false
        nativeAdView!.nativeAd = ad
    }
    
    func getNativeAd() {
        ADManager.shard.requestNativeAd(from: self) { (ad, errMsg) in
            if let ad = ad {
                guard
                  let nibObjects = Bundle.main.loadNibNamed("UnifiedNativeAdView", owner: nil, options: nil),
                  let adView = nibObjects.first as? GADUnifiedNativeAdView
                else {
                  assert(false, "Could not load nib file for adView")
                    return
                }
                self.setAdView(adView, ad: ad)
            }
        } closeAd: {
            self.nativeAdPlaceholder.isHidden = true
        }
    }
}
