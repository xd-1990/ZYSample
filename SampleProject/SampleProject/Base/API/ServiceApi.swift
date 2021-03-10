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
import Alamofire

let kConfigKey = "com.api.getConfig"

@objcMembers class ServiceApi: NSObject {
    
    // 定义默认参数值和接口地址
    private static let kVersion = zy_crypto_version
    private static let kToken = "TXPkyYnSjTRKIkV4aqDvjXyk2852mrBe"
    
    private static let kBaseUrl = "https://xx.xx.com/api"
    private static let kGetConfig = kBaseUrl + "/config"
    private static let kReport = kBaseUrl + "/crash"
    private static let kAttribute = kBaseUrl + "/attribution"
    private static let kUploadReceipt = kBaseUrl + "/receipt"
    private static let kSubscription = kBaseUrl + "/subscription"
    
    
    enum SendResultType {
        case NoError([String: Any])
        case RequestError(Error)
    }

    // MARK: - Send Events
    public static func postEvents(events:Array<Dictionary<String, Any>>, completion: ((SendResultType)->Void)?) {
        request(urlString: kReport, body: ["events": events]) { (result) in
            completion?(result)
        }
    }
    
    // MARK: - GetConfig
    public static func getConfig(completion: ((SendResultType)->Void)?) {
        request(urlString: kGetConfig) { result in
            switch result {
            case .NoError(let info):
                if let config = ConfigResult.deserialize(from: info) {
                    if config.ok {
                        UserDefaults.standard.setValue(config.upload_user_events_interval, forKey: kEventsUploadIntervalKey)
                        UserDefaults.standard.synchronize()
                        completion?(.NoError(info))
                    } else {
                        var msg = config.msg
                        if msg.count == 0 {
                            msg = "api response err"
                        }
                        let err = APIError.init(msg)
                        completion?(.RequestError(err as Error))
                    }
                }
            case .RequestError(let err):
                completion?(.RequestError(err as Error))
            }
        }
    }
    
    public static func convertToJsonData(dict: [String: Any]) -> String? {
        if let data = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted),
            let jsonStr = String(data: data, encoding: .utf8) {
            return jsonStr
        }
        return nil
    }
}


// MARK: - Base request
extension ServiceApi {
    private static func request(urlString: String, body: [String: Any]? = nil, completion: ((SendResultType)->Void)?) {
        
        func debugOutput(suc: Bool, info: Any) {
            #if DEBUG
            debugPrint("\n---------------------")
            debugPrint("请求接口:" + urlString)
            let flag = suc ? "成功" : "失败"
            debugPrint("请求\(flag)如下:")
            debugPrint(info)
            debugPrint("---------------------\n")
            #endif
        }
        
        
        var bodyDic = buildBody(events: [])
        
        if let body = body {
            bodyDic = bodyDic.merging(body, uniquingKeysWith: { (_, last) in last })
        }
        
        guard let bodyStr = convertToJsonData(dict: bodyDic) else {
            let err = APIError.init("param err")
            completion?(.RequestError(err as Error))
            return
        }

        #if DEBUG
        debugPrint("\n---------------------")
        debugPrint("请求接口:" + urlString)
        debugPrint("请求参数如下:")
        debugPrint(bodyDic)
        debugPrint("---------------------\n")
        #endif
        
        let headers: HTTPHeaders = [
            .init(name: "X-CRYPTO-VERSION", value: kVersion)
        ]
        let postBody = zy_encrypt_to_base64(bodyStr.data(using: .utf8))
        
        AF.request(urlString){ (urlRequest) in
            urlRequest.timeoutInterval = 10
            urlRequest.headers = headers
            urlRequest.httpBody = postBody
            urlRequest.method = .post
        }.response { (response) in
            switch response.result {
            case .success(let data):
                guard let data = zy_decrypt_with_base64(data) else {
                    let err = APIError("zy_decrypt_with_base64 failed")
                    debugOutput(suc: false, info: err.localizedDescription)
                    completion?(.RequestError(err))
                    return
                }
                
                guard let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) else {
                    let err = APIError("JSONSerialization failed")
                    debugOutput(suc: false, info: err.localizedDescription)
                    completion?(.RequestError(err))
                    return
                }
                
                guard let result = json as? [String: Any] else {
                    let err = APIError("not [String: Any]")
                    debugOutput(suc: false, info: err.localizedDescription)
                    completion?(.RequestError(err))
                    return
                }
                
                debugOutput(suc: true, info: json)
                completion?(.NoError(result))
            case .failure(let err):
                debugOutput(suc: false, info: err.localizedDescription)
                completion?(.RequestError(err as Error))
            }
        }
    }
    
    public static func buildBody(events: [[String: Any]]) -> [String: Any] {
        var dic = [String: Any]()
        let bundleId = UIDevice.getBundleID()
        dic["app_id"] = bundleId
        #if DEBUG
        dic["environment"] = "sandbox"
        #else
        dic["environment"] = "production"
        #endif
        dic["app_build_version"] = UIDevice.getLocalAppBundleVersion()
        dic["crypto_version"] = kVersion
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
        dic["token"] = kToken
        
        if events.count > 0 {
            dic["events"] = events
        }
        return dic
    }
    
}

// MARK: - Subscribe
extension ServiceApi {
    public static func uploadReceipt(_ receipt: String, completion: @escaping ((Bool, String, SubscribeModel?) -> Void)) {
        let body = ["receipt_data": receipt]
        request(urlString: kUploadReceipt, body: body) { (result) in
            switch result {
            case .NoError(let info):
                if let model = SubscribeModel.deserialize(from: info) {
                    let _ = model.checkVip()
                    completion(true, "", model)
                } else {
                    completion(false, "Deserialize failed", nil)
                }
            case .RequestError(let err):
                completion(false, err.localizedDescription, nil)
            }
        }
    }
    
    public static func getSubscriptionExpiresDate() {
        request(urlString: kSubscription) { (result) in
            switch result {
            case .NoError(let info):
                if let model = SubscribeModel.deserialize(from: info) {
                    let _ = model.checkVip()
                }
            case .RequestError( _):
                print("")
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
        UserDefaults.standard.set(self.toJSONString(), forKey: "com.iap.info")
        UserDefaults.standard.synchronize()
        return isVip
    }
    
    static func isVip() -> Bool {
        if let info = UserDefaults.standard.string(forKey: "com.iap.info"),
           let model = SubscribeModel.deserialize(from: info) {
            return model.isVip
        }
        return false
    }
    
    static func expireTimestamp() -> Int {
        if let info = UserDefaults.standard.string(forKey: "com.iap.info"),
           let model = SubscribeModel.deserialize(from: info) {
            return Int(model.subscription_expires_timestamp)
        }
        return 0
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
        request(urlString: kAttribute, body: body) { (result) in
            switch result {
            case .NoError(let info):
                if let b1 = info["ok"] as? Bool, b1 {
                    let currentVersion = UIDevice.getLocalAppVersion()
                    UserDefaults.standard.setValue(currentVersion, forKey: "kSearchAdsLastVersion")
                    UserDefaults.standard.synchronize()
                }
            case .RequestError( _):
                print("")
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

struct APIError : LocalizedError {
    
    /// 描述
    var desc = ""
    
    /// 原因
    var reason = ""
    
    /// 建议
    var suggestion = ""
    
    /// 帮助
    var help = ""
    
    /// 必须实现，否则报The operation couldn’t be completed.
    var errorDescription: String? {
        return desc
    }
    
    var failureReason: String? {
        return reason
    }
    
    var recoverySuggestion: String? {
        return suggestion
    }
    
    var helpAnchor: String? {
        return help
    }
    
    init(_ desc: String) {
        self.desc = desc
    }
}

class ConfigResult: HandyJSON {
    var ok = false
    var msg = ""
    var upload_user_events_interval = 30
    
    required init() {
        
    }
}
