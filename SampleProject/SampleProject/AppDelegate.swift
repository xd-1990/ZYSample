//
//  AppDelegate.swift
//  SampleProject
//
//  Created by 夏栋 on 2021/3/2.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        thirdInit()
        // Override point for customization after application launch.
        
        return true
    }
    
    func thirdInit() {
        MetricsEvent.setup(umengAppID: "5f058ce8978eea082dbd3680")
        MetricsEvent.app(state: "启动")
        MetricsKit.shared.syncStart()
        
        ServiceApi.getSearchAdsAttribution()
        PurcheaseMgr.shard.completeTransactions()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        MetricsKit.shared.syncResume()
        MetricsEvent.app(state: "进入前台")
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        MetricsEvent.app(state: "进入后台")
        MetricsKit.shared.syncAndPause()
    }

}

