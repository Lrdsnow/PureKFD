//
//  pipHandler.swift
//  PureKFD
//
//  Created by Lrdsnow on 11/8/23.
//

import Foundation
import UIKit
import SwiftUI
import WebKit

struct PiPView: UIViewRepresentable {
    let htmlString: String
    let canvasWidth: CGFloat
    let canvasHeight: CGFloat

    class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
        var parent: PiPView?
        var webView: WKWebView?

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            NSLog("%@", "\(message)")
        }
        
        func triggerUpdate() {
            let script = "anim();"
            webView?.evaluateJavaScript(script, completionHandler: nil)
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Check if the PiP button was clicked
            if navigationAction.targetFrame == nil {
                parent?.openApp() // Handle opening the app
                decisionHandler(.cancel) // Prevent full-screen playback
                return
            }
            decisionHandler(.allow)
        }


        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            NSLog("WebView navigation failed with error: %@", error.localizedDescription)
        }

        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            webView.reload()
        }
        
    }

    init(htmlString: String, canvasWidth: CGFloat, canvasHeight: CGFloat) {
        self.htmlString = htmlString
        self.canvasWidth = canvasWidth
        self.canvasHeight = canvasHeight
    }

    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator()
        coordinator.parent = self
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            coordinator.triggerUpdate()
        }
        return coordinator
    }

    func makeUIView(context: Context) -> WKWebView {
        let webViewConfiguration = WKWebViewConfiguration()
        webViewConfiguration.allowsInlineMediaPlayback = true // Ensure video plays inline
        webViewConfiguration.mediaTypesRequiringUserActionForPlayback = [] // Disable user action requirement for video playback

        let webView = WKWebView(frame: .zero, configuration: webViewConfiguration)
        webView.configuration.userContentController.add(context.coordinator, name: "pipHandler")
        webView.navigationDelegate = context.coordinator
        context.coordinator.webView = webView
        
        let script = """
            var style = document.createElement('style');
            style.innerHTML = '#pipButton { display: none !important; } video::-webkit-media-controls { display: none !important; }';
            document.head.appendChild(style);
            
            document.getElementById('target').requestPictureInPicture().then(() => {
                console.log('Entered Picture in Picture mode on load');
                document.querySelector('video').setAttribute('playsinline', 'true'); // Enable inline playback
            }).catch((error) => {
                console.error('Error entering Picture in Picture mode:', error);
            });
        """
        
        webView.evaluateJavaScript(script, completionHandler: nil)
        
        webView.loadHTMLString(htmlString, baseURL: nil)
        
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {

    }

    func openApp() {
        // Implement code to open the app
        NSLog("Opening the app...")
    }
}

//        """
//                <video id="target" controls=false muted autoplay></video>
//                        <button id="btn">request PiP</button>
//                <script src="https://html2canvas.hertzen.com/dist/html2canvas.js"></script>
//                        <script>
//                            const target = document.getElementById('target');
//                            const source = document.createElement('canvas');
//                            const ctx = source.getContext('2d');
//                            source.width = 300;
//                            source.height = 15;
//                            ctx.font = "15px Arial";
//                            ctx.textAlign = "left";
//                            ctx.textBaseline = "middle";
//                            ctx.imageSmoothingEnabled = true;
//                            anim();
//                            
//                            const stream = source.captureStream();
//                            target.srcObject = stream;
//                            
//                            // Attempt to request Picture in Picture immediately on load
//                            target.requestPictureInPicture();
//                            
//                            if(typeof target.webkitSupportsPresentationMode === 'function' &&
//                                target.webkitSupportsPresentationMode('picture-in-picture') ) {
//                                target.controls = false;
//                                buildCustomControls(vidElem);
//                            }
//
//                            const btn = document.getElementById('btn');
//                            if (target.requestPictureInPicture) {
//                                target.controls = false
//                                btn.onclick = e => target.requestPictureInPicture();
//                            } else {
//                                btn.disabled = true;
//                            }
//                            
//                            function anim() {
//                               ctx.fillStyle = "black";
//                               ctx.fillRect(0, 0, source.width, source.height);
//
//                               html2canvas(document.body).then(function(canvas) {
//                                  ctx.drawImage(canvas, 0, 0);
//                               });
//
//                               requestAnimationFrame(anim);
//                            }
//                        </script>
//        """

struct devPipView: View {
    var body: some View {
        PiPView(htmlString: """
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
                
                
                """, canvasWidth: 300, canvasHeight: 20)
    }
}
