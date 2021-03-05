//
//  StartViewController.swift
//  SampleProject
//
//  Created by 夏栋 on 2021/3/2.
//

import Foundation
import UIKit
import GoogleMobileAds
import Alamofire

class StartViewController: UIViewController, GADInterstitialDelegate {
    var enterMainViewWhenTimeout:Bool = false
    var interstitial:GADInterstitial?
    
    // 是否获取过配置
    var didLoadConfig = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let _ = UserDefaults.standard.object(forKey: kConfigKey) {
            didLoadConfig = true
        }
        
        // 国行版本的系统首次安装会提示网络访问权限，为防止获取配置失败，需要监听到网络可用再访问接口
        if let manager = NetworkReachabilityManager() {
            manager.startListening(onQueue: .main) { (status) in
                debugPrint("network status = \(status)")
                if status == .reachable(.cellular) || status == .reachable(.ethernetOrWiFi) {
                    manager.stopListening()
                    self.getConfig()
                }
            }
        }
    }
    
    func getConfig() {
        ServiceApi.getConfig { (suc, tips, result) in
            if suc {
                // 配置读取成功，正常流程
                debugPrint("获取配置成功")
                self.doNext()
            } else {
                // 读取配置失败
                if self.didLoadConfig {
                    debugPrint("后续获取配置失败")
                    // 后续使用是否强制需要获取配置，取决于项目需求
                    let allowUseWithoutConfig = true
                    if allowUseWithoutConfig {
                        self.doNext()
                    }
                } else {
                    // 从未读取过配置，不做任何处理，无法使用
                    debugPrint("首次获取配置失败，无法使用")
                    
                    // 演示工程，允许进入，实际项目中删除这段代码
                    self.doNext()
                }
            }
        }
    }
    
    func doNext() {
        // 是否有广告，根据项目实际情况来
        let hasLanuchAd = true
        
        if hasLanuchAd {
            if !PurcheaseMgr.isVip() {
                self.interstitial = GADInterstitial(adUnitID: kAdInterstitialKey)
                self.interstitial?.delegate = self
                let request = GADRequest()
                self.interstitial?.load(request)
                self.enterMainViewWhenTimeout = true
                // 5秒时间加载广告，无论是否成功，都进入首页
                self.perform(#selector(self.timeOutenterMainPage), with: nil, afterDelay: 5.0)
            } else {
                self.enterMainPage()
            }
        } else {
            enterMainPage()
        }
    }
    
   @objc func timeOutenterMainPage() {
        if enterMainViewWhenTimeout {
            DispatchQueue.main.async {
                self.enterMainPage()
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        MetricsEvent.pageDidEnter(.start)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        MetricsEvent.pageDidLeave(.start)
    }
    
    func enterMainPage(){
        self.interstitial?.delegate = nil
        let vc = MainViewController.loadMyStoryboard(name: "Main")
        if let d = UIApplication.shared.delegate, let w = d.window, let window = w {
            window.rootViewController = vc
        }
    }
    func interstitialWillPresentScreen(_ ad: GADInterstitial) {
        self.enterMainViewWhenTimeout = false
    }
    
    func interstitialDidReceiveAd(_ ad: GADInterstitial) {
        interstitial?.present(fromRootViewController: self)
    }
    
    func interstitialDidFail(toPresentScreen ad: GADInterstitial) {
        self.enterMainViewWhenTimeout = true
    }
    
    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        
    }
    
    func interstitialWillDismissScreen(_ ad: GADInterstitial) {
        enterMainPage()
    }
    
    func interstitial(_ ad: GADInterstitial, didFailToReceiveAdWithError error: GADRequestError) {
        self.enterMainViewWhenTimeout = true
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
