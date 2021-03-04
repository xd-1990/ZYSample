//
// Created by 何思远 on 2020/7/2.
// Copyright (c) 2020 DP Intelligence LLC. All rights reserved.
//

import Foundation
import SQLite

extension Connection {
    public var userVersion: Int32 {
        get {
            return Int32(try! scalar("PRAGMA user_version") as! Int64)
        }
        set {
            try! run("PRAGMA user_version = \(newValue)")
        }
    }
}

private class VersionError: Error {
}

private let t_events = Table("events")
let c_id = Expression<Int64>("id")
let c_app_version = Expression<String>("app_version")
let c_page = Expression<String>("page")
let c_source = Expression<String>("source")
let c_name = Expression<String>("name")
let c_time = Expression<Date>("time")
let c_user_info = Expression<String?>("user_info")


class MetricsKit {
    static let shared = MetricsKit()
    private var databaseConnection: Connection? = nil
    private let queue = DispatchQueue.init(label: "metrics")
    private let appVersion: String
    private var syncEnabled = false
    private var syncTimer: Timer? = nil
    private var working = false


    private init() {
        var appVersion = ""
        if let info = Bundle.main.infoDictionary {
            appVersion = info["CFBundleShortVersionString"] as? String ?? ""
        }
        self.appVersion = appVersion
        self.connectDatabase()
    }

    func configure() {
    }

    func metrics(page: String, source: String, name: String, parameters: [String: Any]? = nil) {
        if let db = self.databaseConnection {
            let time = Date.init()
            self.queue.async {
                var userInfo: String? = nil
                if let parameters = parameters {
                    if let data = try? JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) {
                        userInfo = String.init(data: data, encoding: .utf8)
                    }
                }
                if let insertCount = try? db.run(t_events.insert(
                        c_app_version <- self.appVersion,
                        c_page <- page,
                        c_source <- source,
                        c_name <- name,
                        c_time <- time,
                        c_user_info <- userInfo
                )) {
                    print("1 event inserted into database")
                } else {
                    print("Failed to insert event")
                }
            }
        }
    }

    func syncStart() {
        self.syncEnabled = true
        self.sync()
        print("Sync started")
    }

    func syncAndPause() {
        DispatchQueue.main.async {
            self.syncTimer?.fire()
            self.syncTimer?.invalidate()
            self.syncTimer = nil
            print("Sync paused")
        }
    }

    func syncResume() {
        self.sync()
        print("Sync resumed")
    }
}

extension MetricsKit {
    private func connectDatabase() {
        guard let docPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            return
        }
        let docURL = URL.init(fileURLWithPath: docPath, isDirectory: true)
        let databaseURL = docURL.appendingPathComponent("metrics.db")
        let databasePath = databaseURL.path

        let fileManager = FileManager.default
        let fileExists = fileManager.fileExists(atPath: databasePath)
        do {
            let connection = try Connection(databasePath)
            #if DEBUG
            connection.trace {
                print($0)
            }
            #endif
            if fileExists && connection.userVersion != 1 {
                throw VersionError()
            }
            try connection.run(
                    t_events.create(ifNotExists: true) { t in
                        t.column(c_id, primaryKey: .autoincrement)
                        t.column(c_app_version)
                        t.column(c_page)
                        t.column(c_source)
                        t.column(c_name)
                        t.column(c_time)
                        t.column(c_user_info)
                    }
            )
            connection.userVersion = 1
            self.databaseConnection = connection
        } catch {
            if fileExists {
                // 删除了重新来
                try? fileManager.removeItem(atPath: databasePath)
                if !fileManager.fileExists(atPath: databasePath) {
                    self.connectDatabase()
                }
            }
        }
    }

    func uploadInterval() -> TimeInterval {
        let configInterval = UserDefaults.standard.integer(forKey: kEventsUploadIntervalKey)
        let value = configInterval > 0 ? configInterval : 30
        return TimeInterval(value)
    }
    
    private func sync() {
        DispatchQueue.main.async {
            if !self.syncEnabled {
                return
            }
            // 移除之前的同步定时器
            self.syncTimer?.invalidate()
            print("启动程序Timer")
            // 设置新的定时器
            self.syncTimer = Timer.scheduledTimer(timeInterval: self.uploadInterval(), target: self, selector: #selector(self.processSync), userInfo: nil, repeats: true)
            // 马上执行一次
            self.syncTimer?.fire()
        }
    }
    
    @objc private func processSync(){
        
        DispatchQueue.global().async {
            // 有时候任务会执行超过5秒, 避免同时执行
            var owned = false
            self.queue.sync {
                if (!self.working) {
                    self.working = true
                    owned = true
                }
            }
            if (!owned) {
                return
            }
            print("Sync events")
            // 获取数据库连接
            if let db = self.databaseConnection {
                while (true) {
                    var maxID: Int64 = 0
                    var eventsArray = [[String: Any]]()
                    // 查询数据库
                    self.queue.sync {
                        if let events = try? db.prepare(t_events.order(c_id.asc).limit(5, offset: 0)) {
                            for event in events {
                                let id = event[c_id]
                                let appVersion = event[c_app_version]
                                let page = event[c_page]
                                let source = event[c_source]
                                let name = event[c_name]
                                let time = event[c_time]
                                let userInfo = event[c_user_info]
                                var parameters = [String: Any]()
                                if let parametersData = userInfo?.data(using: .utf8) {
                                    if let json = (try? JSONSerialization.jsonObject(with: parametersData)) as? [String: Any] {
                                        parameters = json
                                    }
                                }
                                let eventItem: [String: Any] = [
                                    "id": id,
                                    "page": page,
                                    "name": name,
                                    "time": Int64(time.timeIntervalSince1970 * 1000),
                                    "source": source,
                                    "app_version": appVersion,
                                    "params": parameters
                                ]
                                maxID = id
                                eventsArray.append(eventItem)
                            }
                        }
                    }
                    // 发送时间至服务器
                    if !eventsArray.isEmpty {
                        let semaphore = DispatchSemaphore(value: 0)
                        print("Send events")
                        ServiceApi.postEvents(events: eventsArray) { result in
                            switch (result) {
                            case .NoError(let result):
                                if let ok = result["ok"] as? Bool {
                                    if (ok) {
                                        print("Send events successfully")
                                        break
                                    }
                                }
                                print("Send events failed. Server tell us send again.")
                                maxID = 0 // 不要修改数据库
                            case .RequestError(let error):
                                print("Send events failed. Error \(error)")
                                maxID = 0 // 不要修改数据库
                            }
                            semaphore.signal()
                        }
                        semaphore.wait()
                    }
                    // 如果发送成功, 则删除本地记录
                    if (maxID != 0) {
                        self.queue.sync {
                            print("Delete events")
                            if let db = self.databaseConnection {
                                try? db.run(t_events.where(c_id <= maxID).delete())
                            }
                        }
                    }
                    if (eventsArray.isEmpty) {
                        // 没有事件需要同步了, 休眠
                        print("No event. Wait for next sync event.")
                        break
                    } else if (self.syncTimer == nil) {
                        // 定时器被取消
                        print("Timer cancled")
                        break
                    }
                }
            }
            self.queue.sync {
                self.working = false
            }
        }
    }
}


