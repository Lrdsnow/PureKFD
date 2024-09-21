//
//  SaveEnv.swift
//  PureKFD
//
//  Created by Lrdsnow on 9/21/24.
//

import Foundation
import SwiftUI

public class SaveEnv: ObservableObject {
    
    @AppStorage("saveEnv") var env: [String:String] = [:]
    
    public init() {
        if env.isEmpty {
            reset()
        }
    }
    
    public func reset() {
        var save: [String:String] = [:]
        save["EnvModelName"] = DeviceInfo.prettyModel
        save["EnvModelID"] = DeviceInfo.modelName
        save["EnvCPU"] = DeviceInfo.cpu
        save["EnvOSString"] = DeviceInfo.osString
        save["EnvOSVersion"] = DeviceInfo.version
        save["EnvOSBuild"] = DeviceInfo.build
        if let data = try? Data(contentsOf: URL(fileURLWithPath: "/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/com.apple.MobileGestalt.plist")),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String:Any],
           let cacheExtra = json["CacheExtra"] as? [String:Any] {
            if let cpuID = cacheExtra["5pYKlGnYYBzGvAlIU8RjEQ"] as? String {
                save["EnvCPUID"] = cpuID
            }
            if let boardID = cacheExtra["/YYygAofPDbhrwToVsXdeA"] as? String ?? cacheExtra["oYicEKzVTz4/CxxE05pEgQ"] as? String {
                save["EnvBoardID"] = boardID
            }
        }
        self.env = save
    }
    
}
