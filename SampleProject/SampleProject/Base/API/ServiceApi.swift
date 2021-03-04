//
//  ServiceApi.swift
//  BatterySaver
//
//  Created by sunguo on 2020/8/13.
//  Copyright © 2020 mac. All rights reserved.
//

import UIKit
import iAd
import HandyJSON

let kConfigKey = "com.api.getConfig"

@objcMembers class ServiceApi: NSObject {
    
    private static let C_VERSION = zy_crypto_version
    private static let TOKEN = ""
    
    private static let BASEURL = "https://xxx.xxx.com/api"
    private static let GETCONFIG = BASEURL + "/getConfig"
    private static let ERRORREPORT = BASEURL + "/uploadCrashLogs"
    private static let ATTRIBUTION = BASEURL + "/uploadAttribution"
    private static let UPLOADRECEIPT = BASEURL + "/verifyReceipt"
    private static let EXPIRESDATE = BASEURL + "/getSubscriptionExpiresDate"

    enum SendResultType {
        case NoError(dic: [String: Any])
        case RequestError(error: Error)
    }

    // MARK: - Send Events
    public static func postEvents(events:Array<Dictionary<String, Any>>, handler : @escaping (SendResultType)->()) {
        let bodyDic = buildBody(events: events)
        let str = convertToJsonData(dict: bodyDic)
        let postBody = zy_encrypt_to_base64(str.data(using: .utf8))
        
        let url = URL.init(string: ERRORREPORT)
        var request = URLRequest.init(url: url!)
        request.httpMethod = "POST"
        request.httpBody = postBody
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.addValue(C_VERSION, forHTTPHeaderField:"X-CRYPTO-VERSION")
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
            if(error != nil) {
                handler(.RequestError(error: error!))
            } else {
                handler(.NoError(dic: ["ok":true]))
            }
        })
        task.resume()
    }
    
    // MARK: - GetConfig
    public static func getConfig(completion: @escaping ((Bool, String, Any?)->())) {
        request(urlString: GETCONFIG) { (succeed, tips, result) in
            completion(succeed, tips, result)
            guard succeed == true else {
                return
            }
            
            if let result = result as? [String: Any] {
                UserDefaults.standard.setValue(result, forKey: kConfigKey)
                if let uploadInterval = result["upload_user_events_interval"] as? Int {
                    UserDefaults.standard.setValue(uploadInterval, forKey: kEventsUploadIntervalKey)
                }
                UserDefaults.standard.synchronize()
            }
        }
    }
    
    private static func convertToJsonData(dict: [String: Any]) -> String {
        let data = try? JSONSerialization.data(withJSONObject: dict, options: JSONSerialization.WritingOptions(rawValue: 0))
        let jsonStr = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
        jsonStr?.replacingOccurrences(of: " ", with: "")
        jsonStr?.replacingOccurrences(of: "\n", with: "")

        return jsonStr! as String
    }
}


// MARK: - Base request
extension ServiceApi {
    private static func request(urlString: String, body: [String: Any]? = nil, completion: ((Bool, String, Any?)->())?) {
        
        var bodyDic = buildBody(events: [])
        
        if let body = body {
            bodyDic = bodyDic.merging(body, uniquingKeysWith: { (_, last) in last })
        }

        #if DEBUG
        debugPrint("\n---------------------")
        debugPrint("请求接口:" + urlString)
        debugPrint("请求参数如下:")
        debugPrint(bodyDic)
        debugPrint("---------------------\n")
        #endif
        
        let str = convertToJsonData(dict: bodyDic)
        let postBody = zy_encrypt_to_base64(str.data(using: .utf8))

        let url = URL(string: urlString)
        var request = URLRequest(url: url!)
        
        if urlString == GETCONFIG {
            request.timeoutInterval = 5
        } else {
            request.timeoutInterval = 10
        }
        
        request.httpMethod = "POST"
        request.httpBody = postBody
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.addValue(C_VERSION, forHTTPHeaderField: "X-CRYPTO-VERSION")
        let task = URLSession.shared.dataTask(with: request, completionHandler: { data, _, error in
            
            guard error == nil else {
                #if DEBUG
                debugPrint("\n---------------------")
                debugPrint("请求接口:" + urlString)
                debugPrint("请求错误如下:")
                debugPrint(error!.localizedDescription)
                debugPrint("---------------------\n")
                #endif
                DispatchQueue.main.async {
                    (completion != nil) ? completion!(false, error!.localizedDescription, error) : nil
                }
                return
            }
            
            guard let base64Data = zy_decrypt_with_base64(data) else {
                #if DEBUG
                debugPrint("\n---------------------")
                debugPrint("请求接口:" + urlString)
                debugPrint("处理zy_decrypt_with_base64错误")
                debugPrint("---------------------\n")
                #endif
                DispatchQueue.main.async {
                    (completion != nil) ? completion!(false, "zy_decrypt_with_base64 failure", nil) : nil
                }
                return
            }
            
            guard let json = try? JSONSerialization.jsonObject(with: base64Data, options: .mutableLeaves) as? [String: Any] else {
                #if DEBUG
                debugPrint("\n---------------------")
                debugPrint("请求接口:" + urlString)
                debugPrint("处理JSONSerialization错误")
                debugPrint("---------------------\n")
                #endif
                DispatchQueue.main.async {
                    (completion != nil) ? completion!(false, "JSONSerialization failure", nil) : nil
                }
                return
            }
            
            DispatchQueue.main.async {
                (completion != nil) ? completion!(true, "request succeed", json) : nil
            }

            #if DEBUG
            debugPrint("\n---------------------")
            debugPrint("请求接口:" + urlString)
            debugPrint("请求成功结果如下:")
            debugPrint(json)
            debugPrint("---------------------\n")
            #endif
            
        })
        task.resume()
        
    }
    
    private static func buildBody(events: [[String: Any]]) -> [String: Any] {
        var dic = [String: Any]()
        let bundleId = UIDevice.getBundleID()
        dic["app_id"] = bundleId
        #if IS_PRODUCT
        dic["environment"] = "production"
        #else
        dic["environment"] = "sandbox"
        #endif
        dic["app_build_version"] = UIDevice.getLocalAppBundleVersion()
        dic["crypto_version"] = C_VERSION
        dic["device_system_name"] = UIDevice.current.systemName
        dic["user_region"] = UIDevice.getLocaleCode()
        dic["user_language"] = UIDevice.getLocaleLanguage()
        dic["app_version"] = UIDevice.getLocalAppVersion()
        dic["user_id"] = UIDevice.getUUIDByKeyChain(bundleId: bundleId)
        dic["device_system_version"] = UIDevice.getSystemVersion()
        dic["device_model"] = UIDevice.modelName()
        dic["client_region"] = UIDevice.getLocaleCode()
        dic["client_language"] = UIDevice.getLocaleLanguage()
        dic["request_uuid"] = UIDevice.getRequestUUID()
        dic["token"] = TOKEN
        
        if events.count > 0 {
            dic["events"] = events
        }
        return dic
    }
    
}

// MARK: - Subscribe
extension ServiceApi {
    public static func uploadReceipt(_ receipt: String, completion: @escaping ((Bool, String) -> Void)) {
        
        let body = ["receipt_data": receipt]
        request(urlString: UPLOADRECEIPT, body: body) { (succeed, tips, result) in
            if let result = result as? [String: Any],
               let model = SubscribeModel.deserialize(from: result) {
                let _ = model.checkVip()
                completion(model.ok, tips)
            } else {
                completion(false, tips)
            }
        }
        
    }
    
    public static func getSubscriptionExpiresDate() {
        request(urlString: EXPIRESDATE) { (succeed, tips, result) in
            if let result = result as? [String: Any],
               let model = SubscribeModel.deserialize(from: result) {
                let _ = model.checkVip()
            }
        }
    }
    
}

class SubscribeModel: HandyJSON {
    var ok = false
    var server_time = ""
    var subscription_expires_date = ""
    var check_expiration_interval = 600
    
    var server_timestamp: TimeInterval = 0
    var subscription_expires_timestamp: TimeInterval = 0
    var isVip = false
    
    func checkVip() -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "UTC")
        
        if let date_server = formatter.date(from: server_time),
           let date_expire = formatter.date(from: subscription_expires_date) {
            server_timestamp = date_server.timeIntervalSince1970
            subscription_expires_timestamp = date_expire.timeIntervalSince1970
        }
        
        isVip = subscription_expires_timestamp > server_timestamp
        UserDefaults.standard.set(subscription_expires_timestamp, forKey: "com.iap.expireTime")
        UserDefaults.standard.synchronize()
        return isVip
    }
    
    static func isVip() -> Bool {
        let expire = UserDefaults.standard.integer(forKey: "com.iap.expireTime")
        return TimeInterval(expire) > Date().timeIntervalSince1970
    }
    
    static func expireTimestamp() -> Int {
        let expire = UserDefaults.standard.integer(forKey: "com.iap.expireTime")
        return expire
    }
    
    required init() {
        
    }
}

// MARK: - Search ads
extension ServiceApi {
    
    public static func getSearchAdsAttribution() {
        
        if let lastVersion = UserDefaults.standard.value(forKey: "kSearchAdsLastVersion") as? String {
            let currentVersion = UIDevice.getLocalAppVersion()
            
            if compareVersion(lastVersion, to: currentVersion) != ComparisonResult.orderedAscending {
                return
            }
        }
        
        ADClient.shared().requestAttributionDetails { (attributionDetails, error) in
            self.uploadSearchAds(attributionDetails)
        }
        
    }

    private static func uploadSearchAds(_ attributionDetails: [String : Any]?) {
        guard let attributionDetails = attributionDetails else { return }

        let body = ["attribution": attributionDetails]
        request(urlString: ATTRIBUTION, body: body) { (succeed, tips, result) in
            if let result = result as? [String: Any],
               let bl = result["ok"] as? Bool,
               bl {
                let currentVersion = UIDevice.getLocalAppVersion()
                UserDefaults.standard.setValue(currentVersion, forKey: "kSearchAdsLastVersion")
                UserDefaults.standard.synchronize()
            }
        }
        
    }
    
    private class func compareVersion(_ ver: String, to toVer: String) -> ComparisonResult {
        var ary0 = ver.components(separatedBy: ".").map({ return Int($0) ?? 0 })
        var ary1 = toVer.components(separatedBy: ".").map({ return Int($0) ?? 0 })
        while ary0.count < 3 {
            ary0.append(0)
        }
        while ary1.count < 3 {
            ary1.append(0)
        }
        let des0 = ary0[0...2].description
        let des1 = ary1[0...2].description
        return des0.compare(des1, options: .numeric)
    }
}
