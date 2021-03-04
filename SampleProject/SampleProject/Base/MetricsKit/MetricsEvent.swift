//
//  MetricsEvent.swift
//  BatterySaver
//
//  Created by sunguo on 2020/8/14.
//  Copyright © 2020 mac. All rights reserved.
//

import UIKit
import StoreKit

@objc public enum MetricsPage: Int{
    case loadingPage
    case scannerPage
    case createPage
    case historyPage
    case settingsPage
    case IAPPage
    case createCodePage
    case resultPage
    case stylePage
    case emptyPage
    case dirListPage
    case allDirPage
}

private extension MetricsPage {
    var description: String {
        get {
            switch (self) {
            case .loadingPage:
                return "启动页"
            case .scannerPage:
                return "Scanner页"
            case .createPage:
                return "Create页"
            case .historyPage:
                return "History页"
            case .settingsPage:
                return "Settings页"
            case .IAPPage:
                return "订阅页"
            case .createCodePage:
                return "创建二维码页"
            case .resultPage:
                return "Result页"
            case .stylePage:
                return "Style页"
            case .emptyPage:
                return "空文件夹详情页"
            case .dirListPage:
                return "文件夹详情页"
            case .allDirPage:
                return "全部文件夹页"
            }
        }
    }
}

public enum MetricsModule {
    case app
    case page(_ page: MetricsPage)
    case dialog(_ page: MetricsPage, _ name: String)
}

private extension MetricsModule {
    var description: String {
        get {
            switch (self) {
            case .app:
                return "应用程序"
            case .dialog(let module, let name):
                return "\(module.description)-\(name)"
            case .page(let page):
                return "\(page.description)"
            }
        }
    }
}

@objc public enum MetricsSource: Int {
    case user
    case auto
}

private extension MetricsSource {
    var description: String {
        get {
            switch (self) {
            case .user:
                return "用户"
            case .auto:
                return "程序"
            }
        }
    }
}

public enum SelectActionType {
    case SmilarPhoto
    case Screenshots
    case LivePhotos
    case Videos
}

public enum MetricsAction {
    case state(_ parameters: [String: Any]) // 状态
    
    case showDialog(_ parameters: [String: Any]) // 显示
    case hideDialog(_ parameters: [String: Any]) // 隐藏
    
    case willEnter // 准备进入
    case didEnter // 已经进入
    case leave // 离开
    
    //文本编辑/退出编辑
    //    case beginEdit(_ field: String, _ parameters: [String: Any])
    //    case endEdit(_ field: String, _ parameters: [String: Any])
    
    case willRequest(_ what: String, _ parameters: [String: Any]) // 准备请求某一个内容
    case didRequest(_ what: String, _ success: Bool, _ parameters: [String: Any]) // 请求内容
    
    case willRestore
    case didRestore(_ suc: Bool, _ parameters: [String: Any]) // 还原某一个内容成功
    
    case willPurchase(_  what: String, _ parameters: [String: Any])
    case didPurchase(_  what: String, _ success: Bool, _ parameters: [String: Any])
    
    case willVerify
    case didVerify(_ success: Bool, _ parameters: [String: Any])
    
    case click(_ what: String, _ parameters: [String: Any])  // 点击
    case delete(_ what: String, _ parameters: [String: Any])
    
    case select(_ what: String, _ parameters: [String: Any])//选择
    case scan(_ what: String, _ parameters: [String: Any])//选择
}

private extension MetricsAction {
    var description: String {
        get {
            switch (self) {
            case .state(let state):
                return "当前状态 : \(state)"
            case .showDialog(let content):
                return "显示对话框 : \(content)"
            case .hideDialog(let what):
                return "隐藏对话框 : \(what)"
            case .willEnter:
                return "即将进入"
            case .didEnter:
                return "已进入"
            case .leave:
                return "已离开"
            case .willRequest(let what, _):
                return "准备请求内容 : \(what)"
            case .didRequest(let what, _, _):
                return "获得请求内容 : \(what)"
            case .willRestore:
                return "开始恢复购买"
            case .didRestore(let suc, let info):
                if !suc {
                    return "恢复购买失败: \(info)"
                }
                return "恢复购买成功 \(info)"
            case .click(let target, _):
                return "点击 : \(target)"
            case .delete(let deleteWhat, _):
                return "已删除 : \(deleteWhat)"
            case .willPurchase(let productId, _):
                return "开始付款: \(productId)"
            case .didPurchase(let productId, let suc, let reason):
                if !suc {
                    return "付款失败：\(productId) 原因：\(reason)"
                }
                return "付款成功：\(productId)"
            case .willVerify:
                return "开始校验"
            case .didVerify(let suc, let reason):
                if !suc {
                    return "校验失败 原因：\(reason)"
                }
                return "校验成功 \(reason)"
            case .select(let what, _):
                return "勾选 : \(what)"
            case .scan(let what, _):
                return "扫描 : \(what)"
            }
        }
    }
}

@objcMembers class MetricsEvent: NSObject {
    
    @objc static func setup(umengAppID: String) {
        // Firebase
        //        FirebaseApp.configure()
        // 友盟
        #if DEBUG
        UMConfigure.setLogEnabled(true)
        #endif
        UMConfigure.initWithAppkey(umengAppID, channel: "App Store")
        MobClick.setCrashReportEnabled(true)
        MobClick.setAutoPageEnabled(true)
        // MetricsKit
        MetricsKit.shared.configure()
    }
    
    public static func app(state: String) {
        MetricsEvent.event(module: .app, source: .user, action: .state(["应用状态": state]))
    }
    
    public static func permission(of permission: String, state: String) {
        MetricsEvent.event(module: .app, source: .auto, action: .state(["权限": permission, "权限状态": state]))
    }
    
    // 订阅
    public static func subscriptionWillLoadProducts() {
        MetricsEvent.event(module: .app, source: .auto, action: .willRequest("所有购买项", [:]))
    }
    
    public static func subscriptionDidLoadProducts(products: [SKProduct]) {
        let identifiers = products.map {
            $0.productIdentifier
        }
        MetricsEvent.event(module: .app, source: .auto, action: .didRequest("所有购买项", true, ["所有购买项": identifiers]))
    }
    
    public static func subscriptionDidLoadFailedProducts() {
        MetricsEvent.event(module: .app, source: .auto, action: .didRequest("所有购买项", false, [:]))
    }
    
    public static func subscriptionWillRestore() {
        MetricsEvent.event(module: .app, source: .auto, action: .willRestore)
    }
    
    public static func subscriptionDidRestore(validate: Bool, error: NSError?, restoreCount: Int) {
        if validate {
            if restoreCount > 0 {
                MetricsEvent.event(module: .app, source: .auto, action: .didRestore(validate, [:]))
            } else {
                MetricsEvent.event(module: .app, source: .auto, action: .didRestore(validate, ["结果" : "没有需要恢复的购买项目"]))
            }
        } else {
            if let error = error {
                MetricsEvent.event(module: .app, source: .auto, action: .didRestore(validate, ["错误原因": error.localizedDescription, "code": error.code]))
            } else {
                MetricsEvent.event(module: .app, source: .auto, action: .didRestore(validate, [:]))
            }
        }
    }
    
    public static func subscription(subscribed: Bool) {
        MetricsEvent.event(module: .app, source: .auto, action: .state(["购买状态": subscribed ? "已购买" : "未购买"]))
    }
    
    public static func subscriptionStartPurchase(identifier: String) {
        MetricsEvent.event(module: .app, source: .user, action: .willPurchase(identifier, [:]))
    }
    
    public static func subscriptionEndPurchase(identifier: String, success: Bool, error: NSError?) {
        if let error = error {
            MetricsEvent.event(module: .app, source: .user, action: .didPurchase(identifier, success, ["错误原因": error.localizedDescription, "code": error.code]))
        } else {
            MetricsEvent.event(module: .app, source: .user, action: .didPurchase(identifier, success, [:]))
        }
    }
    
    public static func subscriptionStartVerify() {
        MetricsEvent.event(module: .app, source: .user, action: .willVerify)
    }
    
    public static func subscriptionEndVerify(success: Bool, error: String?, model: SubscribeModel?) {
        if !success  {
            MetricsEvent.event(module: .app, source: .user, action: .didVerify(success, ["错误原因": error ?? "请求校验收据接口错误"]))
        } else {
            if let m = model {
                MetricsEvent.event(module: .app, source: .user, action: .didVerify(success, ["当前VIP状态": m.checkVip(), "VIP过期时间": m.subscription_expires_date, "服务器时间": m.server_time]))
            } else {
                MetricsEvent.event(module: .app, source: .user, action: .didVerify(success, [:]))
            }
        }
    }
    
    public static func pageWillEnter(_ page: MetricsPage) {
        MetricsEvent.event(module: .page(page), source: .user, action: .willEnter)
    }
    
    public static func pageDidEnter(_ page: MetricsPage) {
        MetricsEvent.event(module: .page(page), source: .user, action: .didEnter)
    }
    
    public static func pageDidLeave(_ page: MetricsPage) {
        MetricsEvent.event(module: .page(page), source: .user, action: .leave)
    }
    
    public static func page(page: MetricsPage, willRequest what: String, source: MetricsSource = .user) {
        MetricsEvent.event(module: .page(page), source: source, action: .willRequest(what, [:]))
    }
    
    public static func page(page: MetricsPage, didRequest what: String, content: Any? = nil, source: MetricsSource = .user) {
        if let content = content {
            MetricsEvent.event(module: .page(page), source: source, action: .didRequest(what, true, ["内容": content]))
        } else {
            MetricsEvent.event(module: .page(page), source: source, action: .didRequest(what, true, [:]))
        }
    }
    
    public static func didRequest(item: String, success: Bool, content:String){
        MetricsEvent.event(module: .app, source: .auto, action: .didRequest(item, success, success ? ["内容": content] : [:]))
    }
    
    public static func willRequest(item: String){
        MetricsEvent.event(module: .app, source: .auto, action: .willRequest(item, [:]))
    }
    
    public static func page(page: MetricsPage, didFailRequest what: String, source: MetricsSource = .user) {
        MetricsEvent.event(module: .page(page), source: source, action: .didRequest(what, false, [:]))
    }
    
    public static func dialog(withName name: String, showIn page: MetricsPage) {
        MetricsEvent.event(module: .dialog(page, name), source: .user, action: .showDialog([:]))
    }
    
    public static func dialog(withName name: String, hideIn page: MetricsPage) {
        MetricsEvent.event(module: .dialog(page, name), source: .user, action: .hideDialog([:]))
    }
    
    public static func dialog(_ dialog: UIAlertController, showIn page: MetricsPage) {
        MetricsEvent.event(module: .dialog(page, dialog.title ?? dialog.message ?? "对话框"), source: .user, action: .showDialog([:]))
    }
    
    public static func dialog(_ dialog: UIAlertController, hideIn page: MetricsPage) {
        MetricsEvent.event(module: .dialog(page, dialog.title ?? dialog.message ?? "对话框"), source: .user, action: .hideDialog([:]))
    }
    
    public static func action(_ action: UIAlertAction, in dialog: UIAlertController, clickIn page: MetricsPage) {
        MetricsEvent.event(module: .dialog(page, dialog.title ?? dialog.message ?? "对话框"), source: .user, action: .click(action.title ?? action.description, [:]))
    }
    
    //    public static func textField(_ field: UITextField, withName name: String, didBeginEditIn page: MetricsPage) {
    //        MetricsEvent.event(module: .page(page), source: .user, action: .beginEdit(name, ["当前字符": field.text ?? ""]))
    //    }
    //
    //    public static func textField(_ field: UITextField, withName name: String, didEndEditIn page: MetricsPage) {
    //        MetricsEvent.event(module: .page(page), source: .user, action: .endEdit(name, ["当前字符": field.text ?? ""]))
    //    }
    
    public static func click(item: String, in dialog: String, in page: MetricsPage, extra: [String: Any] = [:]) {
        MetricsEvent.event(module: .dialog(page, dialog), source: .user, action: .click(item, extra))
    }
    
    public static func click(item: String, in page: MetricsPage, extra: [String: Any] = [:]) {
        MetricsEvent.event(module: .page(page), source: .user, action: .click(item, extra))
    }
    
    public static func delete(item: String, in page: MetricsPage, extra: [String: Any] = [:]) {
        MetricsEvent.event(module: .page(page), source: .user, action: .delete(item, extra))
    }
    
    public static func select(item: String, in page: MetricsPage, extra: [String: Any] = [:]) {
        MetricsEvent.event(module: .page(page), source: .user, action: .select(item, extra))
    }
    
    public static func scan(item: String, in page: MetricsPage, extra: [String: Any] = [:]) {
        MetricsEvent.event(module: .page(page), source: .user, action: .scan(item, extra))
    }
    
    public static func viewState(in page: MetricsPage, changeTo state: [String: Any]) {
        MetricsEvent.event(module: .page(page), source: .user, action: .state(state))
    }
    
    static func eventExt(module: MetricsModule, source: MetricsSource, name: String, parameters: [String: Any]) {
        var ext = parameters
        ext["module"] = module.description
        ext["source"] = source.description
        //        Analytics.logEvent(name, parameters: ext)
        MobClick.event(name, attributes: ext)
        //if (source == .user) {
        MetricsKit.shared.metrics(page: module.description, source: source.description, name: name, parameters: parameters)
        //}
    }
    
    private static func event(module: MetricsModule, source: MetricsSource, action: MetricsAction) {
        switch (action) {
        case .state(let state):
            eventExt(module: module, source: source, name: "状态", parameters: state)
        case .showDialog(let extra):
            switch (module) {
            case .app:
                fallthrough
            case .page(_):
                eventExt(module: module, source: source, name: "弹出对话框", parameters: extra)
            case .dialog(let page, let name):
                var parameters = extra
                parameters["名称"] = name
                eventExt(module: .page(page), source: source, name: "弹出对话框", parameters: parameters)
            }
        case .hideDialog(let extra):
            switch (module) {
            case .app:
                fallthrough
            case .page(_):
                eventExt(module: module, source: source, name: "收起对话框", parameters: extra)
            case .dialog(let page, let name):
                var parameters = extra
                parameters["名称"] = name
                eventExt(module: .page(page), source: source, name: "收起对话框", parameters: parameters)
            }
        case .willEnter:
            break
        case .didEnter:
            eventExt(module: module, source: source, name: "进入页面", parameters: [:])
        case .leave:
            eventExt(module: module, source: source, name: "离开页面", parameters: [:])
        case .willRequest(let what, let extra):
            var parameters = extra
            parameters["名称"] = what
            eventExt(module: module, source: source, name: "请求内容", parameters: parameters)
        case .didRequest(let what, let success, let extra):
            var parameters = extra
            parameters["名称"] = what
            eventExt(module: module, source: source, name: success ? "请求成功" : "请求失败", parameters: parameters)
        case .willRestore:
            eventExt(module: module, source: source, name: "准备恢复购买", parameters: [:])
        case .didRestore(let what, let extra):
            var parameters = extra
            parameters["恢复购买项"] = what
            eventExt(module: module, source: source, name: "恢复购买结束", parameters: parameters)
        case .click(let what, let extra):
            var parameters = extra
            parameters["目标"] = what
            eventExt(module: module, source: source, name: "点击", parameters: parameters)
        case .delete(let what, let extra):
            var parameters = extra
            parameters["目标"] = what
            eventExt(module: module, source: source, name: "删除", parameters: parameters)
        case .willPurchase(let what, let extra):
            var parameters = extra
            parameters["购买项"] = what
            eventExt(module: module, source: source, name: "即将购买", parameters: parameters)
        case .didPurchase(let what, let success, let extra):
            var parameters = extra
            parameters["购买项"] = what
            eventExt(module: module, source: source, name: success ? "购买成功" : "购买失败", parameters: parameters)
        case .willVerify:
            eventExt(module: module, source: source, name: "即将校验购买项", parameters: [:])
        case .didVerify(let success, let extra):
            eventExt(module: module, source: source, name: success ? "校验成功" : "校验失败", parameters: extra)
        case .select(let what, let extra):
            var parameters = extra
            parameters["目标"] = what
            eventExt(module: module, source: source, name: "选中", parameters: parameters)
        case .scan(let what, let extra):
            var parameters = extra
            parameters["目标"] = what
            eventExt(module: module, source: source, name: "扫描", parameters: parameters)
        }
        
        print("Event : module = \(module.description), source = \(source.description), action = \(action.description)")
    }
}
