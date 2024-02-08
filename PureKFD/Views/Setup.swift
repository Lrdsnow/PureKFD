//
//  Setup.swift
//  PureKFD
//
//  Created by Lrdsnow on 12/17/23.
//

import Foundation
import SwiftUI

struct IssueView: View {
    // Setup:
    @Binding var lock: Bool
    
    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            VStack(alignment: .center, spacing: 8) {
                Image(systemName: "slash.circle")
                    .resizable()
                    .foregroundColor(Color.red)
                    .frame(width: 80, height: 80)
                    .shadow(color: Color.red.opacity(0.5), radius: 3, x: 1, y: 2)
                    .cornerRadius(20)
                    .padding()

                Text("Something Went Wrong")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.red)
                    .shadow(color: Color.red.opacity(0.5), radius: 3, x: 1, y: 2)
                
                Text("Things to try:\n- Manually setting your offsets\n- Try disabling some tweaks\n- Report the issue to the developer")
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.red)
                    .shadow(color: Color.red.opacity(0.5), radius: 3, x: 1, y: 2)
                
            }.padding(.bottom).padding(.horizontal)
            Spacer()
            VStack {
                Button(action: {
                    lock = false
                }, label: {
                    HStack {
                        Spacer()
                        Text("Close").padding(.vertical, 10)
                        Spacer()
                    }
                }).buttonStyle(.borderedProminent).buttonBorderShape(.roundedRectangle(radius: 13)).tint(.red).shadow(color: Color.red.opacity(0.5), radius: 3, x: 1, y: 2)
            }.padding()
        }.foregroundStyle(Color(uiColor: .label))
    }
}

struct SetupView: View {
    // Setup:
    @Binding var showSetup: Bool
    @Binding var showSetup_Design: Bool
    @Binding var downloadingRepos: Bool
    @Binding var downloadingRepos_Status: (Int, Int)
    
    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            VStack(alignment: .center, spacing: 8) {
                Image(uiImage: UIImage(named: "DisplayAppIcon") ?? UIImage())
                    .renderingMode(.original)
                    .resizable()
                    .frame(width: 120, height: 120)
                    .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                    .cornerRadius(20)
                    .padding()

                Text("Welcome to PureKFD")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("While we download the necessary files, let's walk through a few quick setup steps to ensure everything runs smoothly.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }.padding(.bottom).padding(.horizontal)
            Spacer()
            VStack {
                Button(action: {
                    showSetup = false
                    Task {
                        showSetup_Design = true
                    }
                }, label: {
                    HStack {
                        Spacer()
                        Text("Continue").padding(.vertical, 10)
                        Spacer()
                    }
                }).buttonStyle(.borderedProminent).buttonBorderShape(.roundedRectangle(radius: 13))
                HStack {
                    if downloadingRepos {
                        Text("Downloading Repos... (\(downloadingRepos_Status.0)/\(downloadingRepos_Status.1))")
                        Spacer()
                        ProgressView().tint(Color(uiColor: .secondaryLabel))
                    } else {
                        Text("Downloaded Repos! (\(downloadingRepos_Status.0)/\(downloadingRepos_Status.1))")
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                    }
                }.foregroundColor(Color(uiColor: .secondaryLabel))
            }.padding()
        }.foregroundStyle(Color(uiColor: .label))
    }
}

struct SetupView_Design: View {
    // Setup:
    @Binding var showSetup_Design: Bool
    @Binding var showSetup_Exploit: Bool
    @Binding var downloadingRepos: Bool
    @Binding var downloadingRepos_Status: (Int, Int)
    @Binding var showDownloadingRepos: Bool
    // Design Setup:
    @Binding var appColors: AppColors
    
    var body: some View {
        VStack(alignment: .center) {
            VStack(alignment: .center, spacing: 16) {
                List {
                    Section(content: {
                        List {
                            HStack {
                                Image(uiImage: UIImage(named: "DisplayAppIcon") ?? UIImage())
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 50, height: 50)
                                    .cornerRadius(10)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Example Row Name")
                                        .font(.headline)
                                        .foregroundColor(appColors.name)
                                    Text("Example Row Author")
                                        .font(.footnote)
                                        .foregroundColor(appColors.author)
                                    Text("Example Row Description")
                                        .font(.subheadline)
                                        .foregroundColor(appColors.description)
                                }
                            }
                            .listRowBackground(appColors.background).listRowSeparator(.hidden)
                        }.frame(height: 84)
                            .listStyle(.plain).listRowInsets(.init(top: 0,leading: 0,bottom: 0,trailing: 0)).listRowBackground(Color.clear)
                    }, header: {Text("Preview:").font(.subheadline).foregroundColor(Color(uiColor: .secondaryLabel))}).listRowBackground(Color.clear).background(Color.clear)
                    Section(header: Text("Color Settings:").font(.subheadline).foregroundColor(Color(uiColor: .secondaryLabel))) {
                        ColorPicker("Name", selection: $appColors.name)
                        ColorPicker("Author", selection: $appColors.author)
                        ColorPicker("Description", selection: $appColors.description)
                        ColorPicker("Accent", selection: $appColors.accent)
                        ColorPicker("Background", selection: $appColors.background)
                    }.listRowBackground(Color(uiColor: .systemFill).opacity(0.2))
                }.clearBG()
            }.background(Color.clear)
            //.padding(16)
            Spacer()
            VStack {
                Button(action: {
                    showSetup_Design = false
                    Task {
                        showSetup_Exploit = true
                    }
                }, label: {
                    HStack {
                        Spacer()
                        Text("Continue").padding(.vertical, 10)
                        Spacer()
                    }
                }).buttonStyle(.borderedProminent).buttonBorderShape(.roundedRectangle(radius: 13))
                if showDownloadingRepos {
                    HStack {
                        if downloadingRepos {
                            Text("Downloading Repos... (\(downloadingRepos_Status.0)/\(downloadingRepos_Status.1))")
                            Spacer()
                            ProgressView().tint(Color(uiColor: .secondaryLabel))
                        } else {
                            Text("Downloaded Repos! (\(downloadingRepos_Status.0)/\(downloadingRepos_Status.1))")
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }.foregroundColor(Color(uiColor: .secondaryLabel))
                }
            }.padding()
        }.navigationTitle("Design").navigationBarTitleDisplayMode(.large).foregroundStyle(Color(uiColor: .label)).blurredBG().background(Color.clear)
    }
}

struct SetupView_Exploit: View {
    // Setup:
    @Binding var showSetup_Exploit: Bool
    @Binding var showSetup_Finalize: Bool
    @Binding var downloadingRepos: Bool
    @Binding var downloadingRepos_Status: (Int, Int)
    @Binding var showDownloadingRepos: Bool
    //
    @State private var exploit = 0
    let settings: Bool
    @EnvironmentObject var appData: AppData
    @State private var exploitOptions = ["KFD", "MDC", "None (Rootful JB)"]
    @State private var exploitMethod = 0
    
    var body: some View {
        VStack(alignment: .center) {
            List {
                Section(content: {
                    if !appData.UserData.override_exploit_method {
                        HStack {
                            Text("Detected Exploit:")
                            Spacer()
                            Text(exploit == -1 ? "None" : exploit == 0 ? "KFD (16.2-16.6b1)" : exploit == 1 ? "MDC (14.0-16.1.2)" : "Jailbroken")
                        }
                    } else {
                        Picker("Exploit:", selection: $appData.UserData.exploit_method) {
                            ForEach(0..<exploitOptions.count, id: \.self) {
                                Text(exploitOptions[$0])
                            }
                        }
                        .tint(.accentColor)
                        .foregroundColor(.accentColor)
                        .onChange(of: appData.UserData.exploit_method) { _ in appData.save()}
                    }
                    Toggle(isOn: $appData.UserData.override_exploit_method, label: {
                        Text("Wrong exploit? Override Exploit Method")
                    })
                    if exploit == 0 {
                        Toggle(isOn: $appData.UserData.kfd.use_static_headroom, label: {
                            Text("Use Static Headroom?")
                        })
                    }
                }, header: {
                    Text("Exploit:").font(.subheadline).foregroundColor(Color(uiColor: .secondaryLabel))
                }, footer: {
                    if exploit == 0 {
                        Text("Static Headroom has a chance to either make your KFD experience more or less stable").foregroundStyle(Color(uiColor: .secondaryLabel))
                    }
                }).listRowBackground(Color(uiColor: .systemFill).opacity(0.2))
                Section(content: {
                    Toggle(isOn: $appData.UserData.betaRepos, label: {
                        Text("Use Beta Repos")
                    })
                    Toggle(isOn: $appData.UserData.dev, label: {
                        Text("Show Extras tab")
                    })
                }, header: {
                    Text("Extras:").font(.subheadline).foregroundColor(Color(uiColor: .secondaryLabel))
                }, footer: {
                    Text("These extras include things like a file brower, trollstore install, etc.").foregroundStyle(Color(uiColor: .secondaryLabel))
                }).listRowBackground(Color(uiColor: .systemFill).opacity(0.2))
            }.clearBG().onAppear() {
                exploit = getDeviceInfo(appData: appData).0
            }
            Spacer()
            VStack {
                Button(action: {
                    showSetup_Exploit = false
                    Task {
                        showSetup_Finalize = true
                    }
                }, label: {
                    HStack {
                        Spacer()
                        Text("Continue").padding(.vertical, 10)
                        Spacer()
                    }
                }).buttonStyle(.borderedProminent).buttonBorderShape(.roundedRectangle(radius: 13))
                if showDownloadingRepos {
                    HStack {
                        if downloadingRepos {
                            Text("Downloading Repos... (\(downloadingRepos_Status.0)/\(downloadingRepos_Status.1))")
                            Spacer()
                            ProgressView().tint(Color(uiColor: .secondaryLabel))
                        } else {
                            Text("Downloaded Repos! (\(downloadingRepos_Status.0)/\(downloadingRepos_Status.1))")
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }.foregroundColor(Color(uiColor: .secondaryLabel))
                }
            }.padding()
        }.navigationTitle("Others").foregroundStyle(Color(uiColor: .label)).blurredBG()
    }
}

struct SetupView_Finalize: View {
    // Setup:
    @Binding var showSetup_Finalize: Bool
    @Binding var downloadingRepos: Bool
    @Binding var downloadingRepos_Status: (Int, Int)
    // Design Setup:
    @Binding var appColors: AppColors
    //
    let mainView: MainView
    @State private var exploit = 0
    @EnvironmentObject var appData: AppData
    
    var body: some View {
        VStack(alignment: .center) {
            List {
                Section(content: {
                    List {
                        HStack {
                            Image(uiImage: UIImage(named: "DisplayAppIcon") ?? UIImage())
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 50, height: 50)
                                .cornerRadius(10)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Example Row Name")
                                    .font(.headline)
                                    .foregroundColor(appColors.name)
                                Text("Example Row Author")
                                    .font(.footnote)
                                    .foregroundColor(appColors.author)
                                Text("Example Row Description")
                                    .font(.subheadline)
                                    .foregroundColor(appColors.description)
                            }
                        }
                        .listRowBackground(appColors.background).listRowSeparator(.hidden)
                    }.frame(height: 84)
                        .listStyle(.plain).listRowInsets(.init(top: 0,leading: 0,bottom: 0,trailing: 0)).listRowBackground(Color.clear)
                }, header: {Text("Theme:").font(.subheadline).foregroundColor(Color(uiColor: .secondaryLabel))}).listRowBackground(Color(uiColor: .systemFill).opacity(0.2))
                Section(content: {
                    Text("Exploit: \(appData.UserData.exploit_method == 0 ? "KFD (16.2-16.6.1)" : appData.UserData.exploit_method == 1 ? "MDC (15.0-15.7.1 & 16.0-16.1.2)" : appData.UserData.exploit_method == 2 ? "None (Rootful JB)" : "None")")
                    if exploit == 0 {
                        HStack {
                            Text("Use Static Headroom")
                            Spacer()
                            Image(systemName: appData.UserData.kfd.use_static_headroom ? "checkmark.circle.fill" : "circle")
                        }
                    }
                }, header: {
                    Text("Exploit Config:").font(.subheadline).foregroundColor(Color(uiColor: .secondaryLabel))
                }).listRowBackground(Color(uiColor: .systemFill).opacity(0.2))
                Section(content: {
                    HStack {
                        Text("Use Beta Repos")
                        Spacer()
                        Image(systemName: appData.UserData.betaRepos ? "checkmark.circle.fill" : "circle")
                    }
                    HStack {
                        Text("Show Extras tab")
                        Spacer()
                        Image(systemName: appData.UserData.dev ? "checkmark.circle.fill" : "circle")
                    }
                }, header: {
                    Text("Extras:").font(.subheadline).foregroundColor(Color(uiColor: .secondaryLabel))
                }).listRowBackground(Color(uiColor: .systemFill).opacity(0.2))
                Section(header: Text("Tasks:").foregroundColor(Color(uiColor: .secondaryLabel))) {
                    HStack {
                        if downloadingRepos {
                            Text("Downloading \(appData.UserData.betaRepos ? "Beta " : "")Repos... (\(downloadingRepos_Status.0)/\(downloadingRepos_Status.1))")
                            Spacer()
                            ProgressView().tint(Color(uiColor: .secondaryLabel))
                        } else {
                            Text("Downloaded \(appData.UserData.betaRepos ? "Beta " : "")Repos! (\(downloadingRepos_Status.0)/\(downloadingRepos_Status.1))")
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }
                }.listRowBackground(Color(uiColor: .systemFill).opacity(0.2))
            }.clearBG()
            Spacer()
            VStack {
                Button(action: {
                    appData.UserData.savedAppColors = SavedAppColors(
                        name: appColors.name.toHex(includeAlpha: true),
                        author: appColors.author.toHex(includeAlpha: true),
                        description: appColors.description.toHex(includeAlpha: true),
                        background: appColors.background.toHex(includeAlpha: true),
                        accent: appColors.accent.toHex(includeAlpha: true)
                    )
                    appData.appColors = appColors
                    showSetup_Finalize = false
                    try? Data().write(to: URL.documents.appendingPathComponent("config/setup_done"))
                }, label: {
                    HStack {
                        Spacer()
                        Text(downloadingRepos ? "Please wait..." : "Finish").padding(.vertical, 10)
                        Spacer()
                    }
                }).buttonStyle(.borderedProminent).buttonBorderShape(.roundedRectangle(radius: 13)).disabled(downloadingRepos)
                HStack {
                    Text(" ‍ ")
                }
            }.padding()
        }.navigationTitle("Finalize Setup").foregroundStyle(Color(uiColor: .label)).blurredBG().task {
            Task {
                exploit = getDeviceInfo(appData: appData).0
            }
            Task {
                if appData.UserData.betaRepos {
                    mainView.updateRepos()
                }
            }
        }
    }
}

//
