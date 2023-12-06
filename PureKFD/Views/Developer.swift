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
import Dynamic


@available(iOS 15.0, *)
struct DeveloperView: View {
    @State private var popup = false
    @EnvironmentObject var appData: AppData
    var body: some View {
        NavigationView {
            List {
                Section("TS") {
                    Text("Recommended Install Instructions:\n1. Hit Install Trollstore\n2. Immediately Force Shutdown When it finsihes (vol down+power)\n3. Open Tips And Install Trollstore\nNote: If tips crashes or you get error 1, reinstall tips and try again")
                    Button(action: {
                        UIApplication.shared.alert(title: "Installing...", body: "Please wait...", withButton: false)
                        if smart_kopen(appData: appData) == 0 {
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
                            Image("dev_icon").renderingMode(.template)
                            Text("Install Trollstore Helper (KFD)")
                        }
                    })
                }
                
                Section("Files") {
                    NavigationLink(destination: FileBrowserView(root: true), label: {Image("folder_icon").renderingMode(.template); Text("File Browser")})
                    NavigationLink(destination: FileBrowserView(root: false), label: {Image("folder_icon").renderingMode(.template); Text("File Browser (Sandboxed)")})
                }
                Section("Tweak Creation") {
                    NavigationLink(destination: TweakCreatorView(), label: {Image("gear_icon").renderingMode(.template); Text("Tweak Creator")})
                    NavigationLink(destination: TweakConverterView(), label: {Image("gear_icon").renderingMode(.template); Text("Tweak Converter")})
                }
                Section("Tests") {
                    NavigationLink(destination: AppManagerView(), label: {Image("dev_icon").renderingMode(.template); Text("App Manager")})
                    NavigationLink(destination: PiPView(htmlString: """
                                <!DOCTYPE html>
                                <html>
                                    <body>
                                        <video id="target" controls=false muted autoplay></video>
                                        <button id="btn">request PiP</button>
                                        <canvas id="canvas"></canvas>
                                        <script>
                                            const target = document.getElementById('target');
                                            const source = document.createElement('canvas');
                                            const ctx = source.getContext('2d');
                                            source.width = 300;
                                            source.height = 20;
                                            ctx.font = "15px Arial";
                                            ctx.textAlign = "left";
                                            ctx.textBaseline = "middle";
                                            ctx.imageSmoothingEnabled = true;
                                            
                                            const stream = source.captureStream();
                                            target.srcObject = stream;
                                            
                                            // Attempt to request Picture in Picture immediately on load
                                            target.requestPictureInPicture();
                                            
                                            if (typeof target.webkitSupportsPresentationMode === 'function' &&
                                                target.webkitSupportsPresentationMode('picture-in-picture')) {
                                                target.controls = false;
                                                buildCustomControls(target);
                                            }
                                            
                                            const btn = document.getElementById('btn');
                                            if (target.requestPictureInPicture) {
                                                target.controls = false
                                                btn.onclick = e => target.requestPictureInPicture();
                                            } else {
                                                btn.disabled = true;
                                            }
                                            
                                            function anim() {
                                                ctx.fillStyle = "black";
                                                ctx.fillRect(0, 0, source.width, source.height);
                                                ctx.fillStyle = "purple";
                                
                                                var time = new Date();
                                                var sec = time.getSeconds();
                                                var min = time.getMinutes();
                                                var hr = time.getHours();
                                                var day = 'AM';
                                                if (hr > 12) {
                                                    day = 'PM';
                                                    hr = hr - 12;
                                                }
                                                if (hr == 0) {
                                                    hr = 12;
                                                }
                                                if (sec < 10) {
                                                    sec = '0' + sec;
                                                }
                                                if (min < 10) {
                                                    min = '0' + min;
                                                }
                                                if (hr < 10) {
                                                    hr = '0' + hr;
                                                }
                                
                                                ctx.fillText(new Date().toTimeString().split(' ')[0], 10, source.height / 2);
                                                ctx.fillText(":3", source.width - 20, source.height / 2);
                                                
                                                requestAnimationFrame(anim);
                                            }
                                        </script>
                                    </body>
                                </html>
                                
                                
                                """, canvasWidth: 300, canvasHeight: 20), label: {Image("dev_icon").renderingMode(.template); Text("pip test")})
                }
                Button(action: {
                    clearIconCache()
                    UIApplication.shared.alert(title: "Complete", body: "Cleared Icon Cache", withButton: true)
                }, label: {
                    HStack {
                        Image("dev_icon").renderingMode(.template)
                        Text("Clear Icon Cache")
                    }
                })
                Button(action: {
                    rebuildIconCache(appData: appData)
                    UIApplication.shared.alert(title: "Complete", body: "Rebuilt Icon Cache", withButton: true)
                }, label: {
                    HStack {
                        Image("dev_icon").renderingMode(.template)
                        Text("Rebuild Icon Cache (KFD)")
                    }
                })
                Button(action: {
                    rebuildIconCache2(appData: appData)
                    UIApplication.shared.alert(title: "Complete", body: "Rebuilt Icon Cache", withButton: true)
                }, label: {
                    HStack {
                        Image("dev_icon").renderingMode(.template)
                        Text("Rebuild Icon Cache 2 (KFD)")
                    }
                })
                Button(action: {
                    cleanTemp()
                    UIApplication.shared.alert(title: "Complete", body: "Cleared PureKFD's temp files", withButton: true)
                }, label: {
                    HStack {
                        Image("dev_icon").renderingMode(.template)
                        Text("Clear PureKFD temp")
                    }
                })
            }.navigationBarTitle("Developer", displayMode: .large).task {haptic()}
        }
    }
}

var connection: NSXPCConnection?

func clearIconCache() {
    for _ in 1...10000 {
        print("removing icon cache")
        if connection == nil {
            let myCookieInterface = NSXPCInterface(with: ISIconCacheServiceProtocol.self)
            connection = Dynamic.NSXPCConnection(machServiceName: "com.apple.iconservices", options: []).asObject as? NSXPCConnection
            connection!.remoteObjectInterface = myCookieInterface
            connection!.resume()
            print("Connection: \(connection!)")
        }
        
        (connection!.remoteObjectProxy as AnyObject).clearCachedItems(forBundeID: nil) { (a, b) in // passing nil to remove all icon cache
            print("Successfully responded (\(a), \(b ?? "(null)"))")
        }
    }
}

func smart_kopen(appData: AppData) -> Int {
    // Get Exploit
    let exploit_method = getDeviceInfo(appData: appData).0
    let kfddata = getDeviceInfo(appData: appData).1
    
    // KFD Stuff
    if exploit_method == 0 && !appData.kopened {
        let exploit_result = do_kopen(UInt64(kfddata.puaf_pages), UInt64(kfddata.puaf_method), UInt64(kfddata.kread_method), UInt64(kfddata.kwrite_method))
        if exploit_result == 0 {
            return -1
        }
        fix_exploit()
        appData.kopened = true
    }
    
    return exploit_method
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
