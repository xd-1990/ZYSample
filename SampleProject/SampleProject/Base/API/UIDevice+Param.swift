//
//  UIDevice+QRExtension.swift
//  QRCodeReader
//
//  Created by sunguo on 2020/7/7.
//  Copyright © 2020 mac. All rights reserved.
//

import Foundation
import UIKit

extension UIDevice {
    
    //MARK: - 设备的具体型号
    static func modelName() -> String{
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") {identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        return identifier
    }
    
    static func getUUIDByKeyChain(bundleId:String) -> String {
        let key = "\(bundleId).uuid"
        var strUUID = KeychainManager.keyChainReadData(identifier: key) as? String
        if strUUID == "" || strUUID == nil  {
            strUUID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
            _ = KeychainManager.keyChainSaveData(data: strUUID!, withIdentifier: key)
        }
        
        return strUUID!
    }
    
    static func getLocaleCode() -> String {
        let identifier = NSLocale.current.identifier
        let locationId = NSLocale.init(localeIdentifier: identifier)
        return locationId.object(forKey: .countryCode) as! String
    }
    
    static func getLocaleLanguage() -> String{
        let language = NSLocale.preferredLanguages[0]
        let languageDic = NSLocale.components(fromLocaleIdentifier: language)
        let languageCode = languageDic["kCFLocaleLanguageCodeKey"]
        return languageCode ?? ""
    }
    
    static func getLocalAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }
    
    static func getBundleID() -> String {
        return Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String ?? ""
    }
    
    static func getLocalAppBundleVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    }
    
    static func getSystemVersion() -> String {
        return UIDevice.current.systemVersion
    }
    
    static func getAppName() -> String {
        return Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? ""
    }
    
    static func getRequestUUID() -> String {
        let formatter = DateFormatter.init();
        formatter.dateFormat = "yyyyMMddHHmmss";
        formatter.timeZone = TimeZone(abbreviation: "GMT")
        return "\(formatter.string(from: Date()))-\(NSUUID.init().uuidString)"
    }
}

