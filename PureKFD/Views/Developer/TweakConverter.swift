//
//  TweakTranslator.swift
//  PureKFD
//
//  Created by Lrdsnow on 10/7/23.
//

import Foundation
import SwiftUI
import Zip

@available(iOS 15.0, *)
struct TweakConverterView: View {
    @EnvironmentObject var appData: AppData
    @State var pickedFilePath = ""
    @State var pickedFileFullPath = ""
    @State var true_pkgtypes = ["cowlock", "PureKFD"]
    @State var pkgtypes = ["Cowabunga (Lock)", "PureKFD (Misaka Format)"]
    @State var true_outpkgtypes = ["PureKFD"]
    @State var outpkgtypes = ["PureKFD (Misaka Format)"]
    @State var inpkgtype = 0
    @State var outpkgtype = 0
    @State var tweakpath: String? = nil
    var body: some View {
        List {
            Section("In") {
                AutoFilePickerView(appData: _appData, pickedFilePath: $pickedFilePath, pickedFileFullPath: $pickedFileFullPath, type: [.data], label: "Input Tweak/Package", bundleID: "temp")
                Picker("Input Tweak/Package Type:", selection: $inpkgtype) {
                    ForEach(0..<pkgtypes.count, id: \.self) {
                        Text(pkgtypes[$0])
                    }
                }
                .tint(.accentColor)
                .foregroundColor(.accentColor)
                .clearListRowBackground()
            }
            Section("Out") {
                Picker("Output Tweak Type:", selection: $outpkgtype) {
                    ForEach(0..<outpkgtypes.count, id: \.self) {
                        Text(outpkgtypes[$0])
                    }
                }
                .tint(.accentColor)
                .foregroundColor(.accentColor)
                .clearListRowBackground()
                Button(action: {
                    Task {
                        tweakpath = convertTweak(intype: true_pkgtypes[inpkgtype], outtype: true_outpkgtypes[outpkgtype], pkgpath: URL(fileURLWithPath: pickedFileFullPath))
                        if tweakpath != nil {
                            let av = UIActivityViewController(activityItems: [URL(fileURLWithPath: tweakpath ?? "none")], applicationActivities: nil)
                            UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true, completion: nil)
                        } else {
                            UIApplication.shared.alert(title: "Error", body: "Unknown Error Occured", withButton: true)
                        }
                    }
                }, label: {Text("Convert")})
            }
        }.navigationBarTitle("Tweak Converter", displayMode: .large)
    }
}

func convertTweak(intype: String, outtype: String, pkgpath: URL) -> String? {
    switch intype {
    case "cowlock":
        let temppath = FileManager.default.temporaryDirectory.appendingPathComponent("temp_extract")
        do {
            do {
                try FileManager.default.removeItem(at: temppath)
            } catch {}
            try FileManager.default.createDirectory(at: temppath, withIntermediateDirectories: true)
        } catch {}
        let tempzippath = FileManager.default.temporaryDirectory.appendingPathComponent("temp_pkg.zip")
        do {
            do {
                try FileManager.default.removeItem(at: tempzippath)
            } catch {}
            try FileManager.default.copyItem(at: pkgpath, to: tempzippath)
        } catch {}
        unzip(Data_zip: tempzippath, Extract: temppath)
        let work = generateLock("CowabungaLock", lockfiles: temppath)
        let pkgid = "\(UUID())"
        let pkgfolderpath = FileManager.default.temporaryDirectory.appendingPathComponent("CowabungaLock")
        do {
            let jsonData = try JSONEncoder().encode(Package(name: "CowabungaLock", bundleID: pkgid, author: "Unknown", desc: "Lock Ported From Cowabunga", longdesc: nil, accent: nil, screenshots: nil, banner: nil, previewbg: nil, install_actions: [], uninstall_actions: [], url: nil, pkgtype: "PureKFD"))
            try jsonData.write(to: work.appendingPathComponent("info.json"))
        } catch {}
        let pkgtemppath = FileManager.default.temporaryDirectory.appendingPathComponent("CowabungaLock.PureKFD.zip")
        let pkgfilepath = FileManager.default.temporaryDirectory.appendingPathComponent("CowabungaLock.PureKFD")
        do {
            do {
                try FileManager.default.removeItem(at: pkgtemppath)
            } catch {}
            do {
                try FileManager.default.createDirectory(at: pkgfolderpath, withIntermediateDirectories: true)
            } catch {}
            do {
                try FileManager.default.moveItem(at: work.appendingPathComponent("info.json"), to: pkgfolderpath.appendingPathComponent("info.json"))
                try FileManager.default.moveItem(at: work.appendingPathComponent("Overwrite"), to: pkgfolderpath.appendingPathComponent("Overwrite"))
            } catch {}
            try Zip.zipFiles(paths: [pkgfolderpath], zipFilePath: pkgtemppath, password: nil, compression: .BestSpeed, progress: nil)
            do {
                try FileManager.default.removeItem(at: pkgfilepath)
            } catch {}
            try FileManager.default.moveItem(at: pkgtemppath, to: pkgfilepath)
        } catch {}
        if FileManager.default.fileExists(atPath: pkgfilepath.path) {
            return pkgfilepath.path
        } else {
            return nil
        }
    default:
        return nil
    }
}

func get_main_caml(_ type: String, pkgname: String = "") -> String {
    if type == "lock" {
        var caml = ""
        do {
            try caml = String(contentsOf: Bundle.main.url(forResource: "lock", withExtension: "caml")!).replacingOccurrences(of: "_pkgname_", with: pkgname)
        } catch {}
        return caml
    }
    return ""
}

func generateLock(_ lockname: String, lockfiles: URL) -> URL {
    let workpath = FileManager.default.temporaryDirectory.appendingPathComponent("work")
    do {
        do {
            try FileManager.default.removeItem(at: workpath)
        } catch {}
        try FileManager.default.createDirectory(at: workpath, withIntermediateDirectories: true)
    } catch {}
    let maincaml = get_main_caml("lock", pkgname: lockname)
    for lock in ["lock@2x-812h.ca", "lock@2x-896h.ca", "lock@3x-812h.ca", "lock@3x-896h.ca", "lock@3x-d73.ca"] {
        do {
            let lockpath = workpath.appendingPathComponent("Overwrite/System/Library/PrivateFrameworks/SpringBoardUIServices.framework/\(lock)")
            try FileManager.default.createDirectory(at: lockpath, withIntermediateDirectories: true)
            try maincaml.write(to: lockpath.appendingPathComponent("main.caml"), atomically: true, encoding: .utf8)
        } catch {}
    }
    do {
        try FileManager.default.createDirectory(at: workpath.appendingPathComponent("Overwrite/var/mobile/Documents/\(lockname)"), withIntermediateDirectories: true)
    } catch {}
    do {
        for filename in try FileManager.default.contentsOfDirectory(atPath: lockfiles.path) {
            try FileManager.default.copyItem(at: lockfiles.appendingPathComponent(filename), to: workpath.appendingPathComponent("Overwrite/var/mobile/Documents/\(lockname)/\(filename)"))
        }
    } catch {}
    return workpath
}
