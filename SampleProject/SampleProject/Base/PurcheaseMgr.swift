//
//  PurcheaseMgr.swift
//  PhotoScan
//
//  Created by 夏栋 on 2020/6/19.
//  Copyright © 2020 DP Intelligence LLC. All rights reserved.
//

import Foundation
import UIKit
import SwiftyStoreKit
import StoreKit
import SVProgressHUD

class PurcheaseMgr: NSObject {
    static let shard = PurcheaseMgr()
    
    let purchaseStateChange = "com.purchase.change"
    
    override init() {
        super.init()
        SVProgressHUD.setDefaultMaskType(.black)
        SVProgressHUD.setMaximumDismissTimeInterval(2.0)
    }
    
    static public func productIdWeek() -> String {
        if let id = Bundle.main.bundleIdentifier {
            let pid = id + ".SubscriptionWeekly"
            return pid
        }
        
        return ""
    }
    
    static public func productIdLifeTime() -> String {
        if let id = Bundle.main.bundleIdentifier {
            let pid = id + ".LifeTime"
            return pid
        }
        
        return ""
    }

    private var products: [SKProduct] = [SKProduct]()
    
    static func isVip() -> Bool {
        #if DEBUG
//        return true
        #endif
        
        return SubscribeModel.isVip()
    }
    
    func fetchProducts(_ complication: @escaping ([SKProduct])->()) {
        if products.count > 0 {
            complication(products)
            return
        }
        
        SwiftyStoreKit.retrieveProductsInfo([]) { result in
            if result.error == nil {
                self.products.removeAll()
                for product in result.retrievedProducts {
                    let priceString = product.localizedPrice!
                    print("Product: \(product.localizedDescription), price: \(priceString)")
                    self.products.append(product)
                }
                complication(self.products)
                
                for invalidProductId in result.invalidProductIDs {
                    print("Invalid product identifier: \(invalidProductId)")
                }
            } else {
                if let error = result.error {
                    print("Error: \(error)")
                }
            }
        }
    }
    
    func completeTransactions() {
        self.verifyReceiptFromServer { (suc, msg) in }
        
        SwiftyStoreKit.completeTransactions(atomically: true) { purchases in
            for purchase in purchases {
                if purchase.transaction.transactionState == .purchased || purchase.transaction.transactionState == .restored {
                   if purchase.needsFinishTransaction {
                       SwiftyStoreKit.finishTransaction(purchase.transaction)
                   }
                }
            }
            
            // 商品状态更新，上传收据到服务器，更新购买状态
            self.verifyReceiptFromServer { (suc, msg) in }
        }
    }
    
    // MARK: - Purchase
    func purchase(productID: String, complete: ((Bool)->Void)?) {
        SVProgressHUD.show(withStatus: "Please wait...")
        // 1.准备开始购买
        MetricsEvent.subscriptionStartPurchase(identifier: productID)
        SwiftyStoreKit.purchaseProduct(productID, quantity: 1, atomically: false) { result in
            switch result {
            case .success(let product):
                debugPrint("Purchase Success: \(product.productId)")
                // 2.1 付款成功
                MetricsEvent.subscriptionEndPurchase(identifier: productID, success: true, error: nil)
                
                SVProgressHUD.show(withStatus: "Verifying...")
                self.verifyReceiptFromServer { (suc, msg) in
                    DispatchQueue.main.async {
                        if suc {
                            // 2.1.1.1 校验成功
                            if product.needsFinishTransaction {
                                SwiftyStoreKit.finishTransaction(product.transaction)
                            }
                            debugPrint("verification succeed: \(product.productId)")
                            SVProgressHUD.dismiss()
                            
                            NotificationCenter.default.post(name: NSNotification.Name(self.purchaseStateChange), object: nil)
                            complete?(true)
                        } else {
                            // 2.1.1.2 校验失败
                            SVProgressHUD.showError(withStatus: "Verification failed")
                            complete?(false)
                        }
                    }
                    
                }
            case .error(let error):
                var errMsg = ""
                
                switch error.code {
                case .unknown: errMsg = "Unknown error. Please contact support"
                case .clientInvalid: errMsg = "Not allowed to make the payment"
                case .paymentCancelled: errMsg = "The user canceled the payment"
                case .paymentInvalid: errMsg = "The purchase identifier was invalid"
                case .paymentNotAllowed: errMsg = "The device is not allowed to make the payment"
                case .storeProductNotAvailable: errMsg = "The product is not available in the current storefront"
                case .cloudServicePermissionDenied: errMsg = "Access to cloud service information is not allowed"
                case .cloudServiceNetworkConnectionFailed: errMsg = "Could not connect to the network"
                case .cloudServiceRevoked: errMsg = "User has revoked permission to use this cloud service"
                default: errMsg = (error as NSError).localizedDescription
                }
                complete?(false)
                
                // 2.2 付款失败
                MetricsEvent.subscriptionEndPurchase(identifier: productID, success: false, error: error as NSError)
                
                if errMsg.count > 0 {
                    SVProgressHUD.showError(withStatus: errMsg)
                } else {
                    SVProgressHUD.dismiss()
                }
            }
        }
    }
    
    // MARK: - Restore
    func restore(success:((_ resulet:Bool)->())?) {
        SVProgressHUD.show(withStatus: "Restoring...")
        MetricsEvent.subscriptionWillRestore()
        DispatchQueue.global().async {
            SwiftyStoreKit.restorePurchases(atomically: false) { results in
                if results.restoreFailedPurchases.count > 0 {
                    debugPrint("Restore Failed: \(results.restoreFailedPurchases)")
                    SVProgressHUD.showError(withStatus: "Restore failed")
                    
                    let errInfo = results.restoreFailedPurchases.first!
                    let err = errInfo.0 as NSError
                    
                    MetricsEvent.subscriptionDidRestore(validate: false, error: err, restoreCount: 0)
                    success?(false)
                }
                else if results.restoredPurchases.count > 0 {
                    MetricsEvent.subscriptionDidRestore(validate: true, error: nil, restoreCount: results.restoredPurchases.count)
                    
                    self.verifyReceiptFromServer { (suc, msg) in
                        DispatchQueue.main.async {
                            if suc {
                                for purchase in results.restoredPurchases {
                                    if purchase.needsFinishTransaction {
                                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                                    }
                                }
                                debugPrint("Restore Success: \(results.restoredPurchases)")
                                SVProgressHUD.showSuccess(withStatus: "Restore Success")
                                NotificationCenter.default.post(name: NSNotification.Name(self.purchaseStateChange), object: nil)
                                success?(true)
                            } else {
                                SVProgressHUD.showError(withStatus: "Restore failed")
                                success?(false)
                            }
                        }
                    }
                    
                }
                else {
                    SVProgressHUD.showSuccess(withStatus: "Restore Success")
                    debugPrint("Nothing to Restore")
                    success?(true)
                    MetricsEvent.subscriptionDidRestore(validate: true, error: nil, restoreCount: 0)
                }
            }
        }
    }
    
    // MARK: - Verify receipt From Server
    func verifyReceiptFromServer(complete: @escaping ((Bool, String)->Void)) {
        MetricsEvent.subscriptionStartVerify()
        if let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
            let receiptData = try? Data(contentsOf: appStoreReceiptURL, options: .alwaysMapped) {
            let receiptString = receiptData.base64EncodedString(options: [])
            ServiceApi.uploadReceipt(receiptString) { (suc, msg, model) in
                MetricsEvent.subscriptionEndVerify(success: suc, error: msg, model: model)
                complete(suc, msg)
            }
        } else {
            MetricsEvent.subscriptionEndVerify(success: false, error: "本地Receipt不存在，可能是用户尚未购买", model: nil)
            complete(false, "Receipt不存在，可能是用户尚未购买")
        }
    }
    
    // MARK: - Verify receipt Local
    func verifyReceipt(service:AppleReceiptValidator.VerifyReceiptURLType, complete: @escaping ((Bool)->Void)) {
        let receiptValidator = AppleReceiptValidator(service: service, sharedSecret: sharedSecret)
        SwiftyStoreKit.verifyReceipt(using: receiptValidator) { (result) in
            switch result {
            case .success (let receipt):
                let status: Int = receipt["status"] as! Int
                if status == 21007 {
                    // sandbox验证
                    print("IAP: 21007")
                    self.verifyReceipt(service: .sandbox, complete: complete)
                    return
                }
                print("receipt：\(receipt)")
                let dic = receipt["receipt"]
                let dicInApp = dic?["in_app"] as! Array<Dictionary<String,Any>>
                print(dicInApp as Any)
                
                var expireTime = 0
                for iapItem in dicInApp{
                    let iapTime = Int(iapItem["expires_date_ms"] as? String ?? "0") ?? 0
                    let productID = iapItem["product_id"] as? String ?? ""
                    print("IAP: \(productID) expireTime=\(iapTime)")
                    if expireTime < iapTime {
                        expireTime = iapTime
                    }
                }
                print("lastTime:\(expireTime)")
                self.updateExpireTime(time: expireTime)
                complete(true)
                break
            case .error(let error):
                print("error：\(error)")
                complete(false)
                break
            }
        }
    }
    
    func updateExpireTime(time:Int) {
        let defaults = UserDefaults.standard
        defaults.set(time, forKey: "product_tag")
        let now = self.getNowStringMilliStamp()
        if time > Int(now) ?? 0 {
            defaults.set(true, forKey: "cur_status")
        }
        defaults.synchronize()
    }
    
    func getCurVipStatus() -> Bool{
        let defaults = UserDefaults.standard
        let expTime = defaults.integer(forKey: "product_tag")
        let now = self.getNowStringMilliStamp()
        if expTime > Int(now) ?? 0 {
            defaults.set(true, forKey: "cur_status")
            defaults.synchronize()
            return true
        }else{
            defaults.set(false, forKey: "cur_status")
            defaults.synchronize()
            return false
        }
    }
    
    func getNowStringMilliStamp()->String{
        //获取当前时间戳
        let date = Date()
        let timeInterval:TimeInterval = TimeInterval(date.timeIntervalSince1970)
        let millisecond = CLongLong(round(timeInterval * 1000))
        return "\(millisecond)"
    }
    
    func toPurchaseVC() {
//        let purchaseVC = PurchaseViewController.loadMyStoryboard(name: "Setting")
//        purchaseVC.hidesBottomBarWhenPushed = true
//        if let delegate = UIApplication.shared.delegate, let window = delegate.window, let w = window, let root = w.rootViewController as? UINavigationController {
//            root.pushViewController(purchaseVC, animated: true)
//        }
    }
}
