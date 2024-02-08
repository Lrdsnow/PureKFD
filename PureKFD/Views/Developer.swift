//
//  Developer.swift
//  PureKFD
//
//  Created by Lrdsnow on 9/24/23.
//

import Foundation
import SwiftUI
import WebKit
import AVKit
import SwiftKFD
import SwiftKFD_objc

@available(iOS 15.0, *)
struct DeveloperView: View {
    @State private var popup = false
    @EnvironmentObject var appData: AppData
    var body: some View {
        List {
            Section("TS") {
                if appData.UserData.exploit_method == 0 {
                    Text("""
                        Installation Instructions:
                        1. Click on "Install Trollstore Helper"
                        2. Once it finishes, forcefully shut down your device by pressing the volume up button followed by the volume down button and the power button.
                        3. Open the Tips app and install Trollstore.
                        
                        Note: If Tips crashes or you encounter error 1, reinstall Tips and try the installation process again.
                        """)
                } else {
                    Text("Your device was not detected as an KFD device, TS install is currently not compatible with anything other then KFD Devices.")
                }
                Button(action: {
                    UIApplication.shared.alert(title: "Installing...", body: "Please wait...", withButton: false)
                    sleep(1)
                    if smart_kopen(appData: appData) == 0 {
                        sleep(1)
                        try? getApps(exploit_method: 0)
                        do_kclose()
                        UIApplication.shared.dismissAlert(animated: false)
                        UIApplication.shared.alert(title: "Installed!", body: "Installed TSHelper!", withButton: true)
                    } else {
                        UIApplication.shared.dismissAlert(animated: false)
                        UIApplication.shared.alert(title: "Failed!", body: "This operation is KFD only for now.", withButton: true)
                    }
                }, label: {
                    HStack {
                        Image("dev_icon").iconImg()
                        Text("Install Trollstore Helper")
                    }
                }).disabled(appData.UserData.exploit_method != 0).opacity(appData.UserData.exploit_method != 0 ? 0.7 : 1)
            }.listBG()
            
            Section("Files") {
                NavigationLink(destination: FileBrowserView(root: true), label: {Image("folder_icon").iconImg(); Text("File Browser")})
                NavigationLink(destination: FileBrowserView(root: false), label: {Image("folder_icon").iconImg(); Text("File Browser (Sandboxed)")})
                if (hasEntitlement("com.apple.private.security.no-sandbox" as CFString)) {
                    Button(action: {
                        let (status, out, error) = spawnRootHelper(args: [ "remount-preboot" ])
                        if (status != 0) {
                            if (status == -1) {
                                UIApplication.shared.alert(title: "Failed", body: "\(out) \(error)", withButton: true)
                            } else {
                                let desc_cstring: UnsafeMutablePointer<CChar> = waitpid_decode(Int32(status));
                                let desc = String(cString: desc_cstring);
                                free(desc_cstring);
                                UIApplication.shared.alert(title: "Failed", body: "RootHelper \(desc)", withButton: true)
                            }
                        } else {
                            UIApplication.shared.alert(title: "Complete", body: "/private/preboot is now writable", withButton: true)
                        }
                    }, label: {
                        HStack {
                            Image("disk_icon").resizable().renderingMode(.template).frame(maxWidth: 32, maxHeight: 32);
                            Text("Remount /private/preboot");
                        }
                    })
                }
            }.listBG()
            Section("Creator") {
                NavigationLink(destination: TweakCreatorView(), label: {Image("gear_icon").iconImg(); Text("Tweak Creator")})
                NavigationLink(destination: TweakConverterView(), label: {Image("gear_icon").iconImg(); Text("Tweak Converter")})
            }.listBG()
            Section("Tests") {
                if appData.UserData.exploit_method == 0 {
                    NavigationLink(destination: AppManagerView(), label: {Image("dev_icon").iconImg(); Text("App Manager (KFD)")})
                }
                if (hasEntitlement("com.apple.private.security.no-sandbox" as CFString)) {
                    Button(action: {
                        userspaceReboot()
                        UIApplication.shared.alert(title: "Complete", body: "Device should userspace reboot in a moment", withButton: true)
                    }, label: {
                        HStack {
                            Image("dev_icon").iconImg()
                            Text("Userspace Reboot")
                        }
                    })
                }
                Button(action: {
                    clearIconCache()
                    UIApplication.shared.alert(title: "Complete", body: "Cleared Icon Cache", withButton: true)
                }, label: {
                    HStack {
                        Image("dev_icon").iconImg()
                        Text("Clear Icon Cache")
                    }
                })
                if appData.UserData.exploit_method == 0 {
                    Button(action: {
                        rebuildIconCache(appData: appData)
                        UIApplication.shared.alert(title: "Complete", body: "Rebuilt Icon Cache", withButton: true)
                    }, label: {
                        HStack {
                            Image("dev_icon").iconImg()
                            Text("Rebuild Icon Cache (KFD)")
                        }
                    })
                    Button(action: {
                        rebuildIconCache2(appData: appData)
                        UIApplication.shared.alert(title: "Complete", body: "Rebuilt Icon Cache", withButton: true)
                    }, label: {
                        HStack {
                            Image("dev_icon").iconImg()
                            Text("Rebuild Icon Cache 2 (KFD)")
                        }
                    })
                }
                Button(action: {
                    cleanTemp()
                    UIApplication.shared.alert(title: "Complete", body: "Cleared PureKFD's temp files", withButton: true)
                }, label: {
                    HStack {
                        Image("dev_icon").iconImg()
                        Text("Clear PureKFD temp")
                    }
                })
            }.listBG()
        }.navigationBarTitle("Developer", displayMode: .large).task {haptic()}.bgImage(appData).listStyle(.insetGrouped).clearBG()
    }
}

var connection: NSXPCConnection?

func clearIconCache() {

}

func rebuildIconCache(appData: AppData) {
    let sysvFilePath: String = "/System/Library/CoreServices/SystemVersion.plist"
    let exploit_method = smart_kopen(appData: appData)
    if exploit_method == 0 {
        do {
            var plist = try PropertyListSerialization.propertyList(from: try Data(contentsOf: URL(fileURLWithPath: sysvFilePath)), format: nil) as? [String:Any] ?? [:]
            let ogplist = plist
            if !plist.isEmpty {
                let lengthOfOldVersion = (plist["ProductBuildVersion"] as? String ?? "1234567").count
                let oldVersion = plist["ProductBuildVersion"] as? String ?? "1234567"
                
                var vdata = createFolderAndRedirectTemp("/var/tmp")
                plist["ProductBuildVersion"] = "\(Int.random(in: (10^^(lengthOfOldVersion - 1))...(10^^lengthOfOldVersion - 1)))"
                try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0).write(to: URL.documents.appendingPathComponent("temp/temp.plist"))
                try PropertyListSerialization.data(fromPropertyList: ogplist, format: .xml, options: 0).write(to: URL.documents.appendingPathComponent("temp/og_temp.plist"))
                UnRedirectAndRemoveFolderTemp(vdata)
                
                overwriteFile2("/var/tmp/temp.plist", sysvFilePath)
                
                xpc_crash("com.apple.iconservices")
                
                overwriteFile2("/var/tmp/og_temp.plist", sysvFilePath)
            }
        } catch {}
        do_kclose()
        appData.kopened = false
    }
}

func rebuildIconCache2(appData: AppData) {
    let exploit_method = smart_kopen(appData: appData)
    if exploit_method == 0 {
        let icFilePath: String = "/var/containers/Shared/SystemGroup/systemgroup.com.apple.lsd.iconscache/Library/Caches/com.apple.IconsCache/"
        let mount = URL.documents.appendingPathComponent("mounted")
        let temp = URL.documents.appendingPathComponent("temp")
        let fm = FileManager.default
        do {
            let vdata = createFolderAndRedirect2(icFilePath)
            if vdata != UInt64.max {
                for url in try fm.contentsOfDirectory(at: mount, includingPropertiesForKeys: nil) {
                    let path = url.path
                    let fd = open(path, O_RDONLY | O_CLOEXEC)
                    let originalFileSize = lseek(fd, 0, SEEK_END)
                    let temp_vdata = createFolderAndRedirectTemp("/var/tmp")
                    try Data(repeating: 11, count: Int(originalFileSize)).write(to: temp.appendingPathComponent("temp_folder_data"))
                    UnRedirectAndRemoveFolderTemp(temp_vdata)
                    overwriteFile2("/var/tmp/temp_folder_data", path)
                }
                UnRedirectAndRemoveFolderTemp(vdata)
            }
        } catch {}
        do_kclose()
        appData.kopened = false
    }
}

func exitGracefully() {
    UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
    Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
        exit(0)
    }
}

// pow from lemin
precedencegroup PowerPrecedence { higherThan: MultiplicationPrecedence }
infix operator ^^ : PowerPrecedence
func ^^ (radix: Int, power: Int) -> Int {
    return Int(pow(Double(radix), Double(power)))
}
