//
//  BaseViewController.swift
//  PhotoScan
//
//  Created by 夏栋 on 2020/6/17.
//  Copyright © 2020 DP Intelligence LLC. All rights reserved.
//

import Foundation
import UIKit

open class BaseViewController: UIViewController {
    var isShowing = false
    var bannerShowBlock: (()->Void) = {  }
    var bannerDismissBlock: (()->Void) = {  }

    @IBOutlet weak var adContentView: UIView!
    @IBOutlet weak var adHeight: NSLayoutConstraint!
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        if let naviVC = self.navigationController, naviVC.viewControllers.count > 1 {
            let leftItem = UIBarButtonItem.init(image: UIImage(named: "nav_back")?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(backAction))
            self.navigationItem.leftBarButtonItem = leftItem
        }
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isShowing = true
        var key = NSStringFromClass(self.classForCoder)
        if key.components(separatedBy: ".").count > 1 {
            key = key.components(separatedBy: ".")[1]
        }
        
        key = "viewWillAppear: " + key
        
        debugPrint(key)
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isShowing = false
    }
    
    func setBackCloseImage() {
        if let naviVC = self.navigationController, naviVC.viewControllers.count > 1 {
            let leftItem = UIBarButtonItem.init(image: UIImage(named: "nav_close")?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(backAction))
            self.navigationItem.leftBarButtonItem = leftItem
        }
    }

    @objc func backAction() {
        self.navigationController?.popViewController(animated: true)
    }
    
    open override var shouldAutorotate: Bool {
        return false
    }
    
    open override var prefersStatusBarHidden: Bool {
        return false
    }
    
    func addBannerAd() {
        DispatchQueue.main.async {
            let v = ADManager.shard.requestBanner(adUnit: "", from: self, callback: { (banner) in
                self.adHeight.constant = banner.frame.size.height
                self.bannerShowBlock()
                for v in self.adContentView.subviews {
                    v.removeFromSuperview()
                }
                self.adContentView.addSubview(banner)
                UIView.animate(withDuration: 0.25) {
                    self.view.layoutIfNeeded()
                }
            }) {
                self.adHeight.constant = 0
                self.bannerDismissBlock()
                for v in self.adContentView.subviews {
                    v.removeFromSuperview()
                }
                self.view.layoutIfNeeded()
            }
            
            if let v = v {
                self.adContentView.addSubview(v)
            }
        }
    }
}
