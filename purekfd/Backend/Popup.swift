//
//  Popup.swift
//  PurePKG
//
//  Created by Lrdsnow on 3/18/24.
//

import Foundation
#if os(watchOS)
import WatchKit

enum dummy_kbT {
    case URL
    case asciiCapable
}

func showPopup(_ title: String, _ message: String) {
    let action = WKAlertAction(title: "OK", style: .default) {}
    if let controller = WKApplication.shared().rootInterfaceController {
        controller.presentAlert(withTitle: title, message: message, preferredStyle: .alert, actions: [action])
    }
}

func showConfirmPopup(_ title: String, _ message: String, completion: @escaping (Bool) -> Void) {
    let cancelAction = WKAlertAction(title: "Cancel", style: .cancel) {
        completion(false)
    }
    
    let okAction = WKAlertAction(title: "OK", style: .default) {
        completion(true)
    }
    
    if let controller = WKExtension.shared().rootInterfaceController {
        controller.presentAlert(withTitle: title, message: message, preferredStyle: .alert, actions: [cancelAction, okAction])
    }
}

func showTextInputPopup(_ title: String, _ placeholderText: String, _ keyboardType: dummy_kbT, completion: @escaping (String?) -> Void) {
    if let controller = WKApplication.shared().rootInterfaceController {
        controller.presentTextInputController(withSuggestions: [], allowedInputMode: .plain) { (results) in
            if let result = results?.first as? String {
                completion(result)
            } else {
                completion(nil)
            }
        }
    }
}

func showDoubleTextInputPopup(_ title: String, _ placeholderText1: String, _ placeholderText2: String, _ keyboardType: dummy_kbT, completion: @escaping ((String?, String?)) -> Void) {
    if let controller = WKApplication.shared().rootInterfaceController {
        let okAction1 = WKAlertAction(title: "OK", style: .default) {
            controller.presentTextInputController(withSuggestions: nil, allowedInputMode: .plain) { result1 in
                if let text1 = result1?.first as? String {
                    let okAction2 = WKAlertAction(title: "OK", style: .default) {
                        controller.presentTextInputController(withSuggestions: nil, allowedInputMode: .plain) { result2 in
                            if let text2 = result2?.first as? String {
                                completion((text1, text2))
                            } else {
                                completion((text1, nil))
                            }
                        }
                    }
                    let cancelAction2 = WKAlertAction(title: "Cancel", style: .cancel) {
                        completion((text1, nil))
                    }
                    controller.presentAlert(withTitle: placeholderText2, message: nil, preferredStyle: .alert, actions: [okAction2, cancelAction2])
                } else {
                    completion((nil, nil))
                }
            }
        }
        let cancelAction1 = WKAlertAction(title: "Cancel", style: .cancel) {
            completion((nil, nil))
        }
        controller.presentAlert(withTitle: placeholderText1, message: nil, preferredStyle: .alert, actions: [okAction1, cancelAction1])
    }
}
#elseif !os(macOS)
import UIKit
import SwiftUI

func showPopup(_ title: String, _ message: String) {
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    
    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
    alertController.addAction(okAction)
    
    if let topViewController = UIApplication.shared.windows.first?.rootViewController {
        topViewController.present(alertController, animated: true, completion: nil)
    }
}

func showConfirmPopup(_ title: String, _ message: String, completion: @escaping (Bool) -> Void) {
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
        completion(false)
    }
    alertController.addAction(cancelAction)
    
    let okAction = UIAlertAction(title: "OK", style: .default) { (_) in
        completion(true)
    }
    alertController.addAction(okAction)
    
    if let topViewController = UIApplication.shared.windows.first?.rootViewController {
        topViewController.present(alertController, animated: true, completion: nil)
    }
}

func showTextInputPopup(_ title: String, _ placeholderText: String, _ keyboardType: UIKeyboardType, completion: @escaping (String?) -> Void) {
    let alertController = UIAlertController(title: title, message: nil, preferredStyle: .alert)
    
    alertController.addTextField { (textField) in
        textField.placeholder = placeholderText
        textField.keyboardType = keyboardType
    }
    
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
        completion(nil)
    }
    alertController.addAction(cancelAction)
    
    let okAction = UIAlertAction(title: "OK", style: .default) { (_) in
        if let text = alertController.textFields?.first?.text {
            completion(text)
        } else {
            completion(nil)
        }
    }
    alertController.addAction(okAction)
    
    if let topViewController = UIApplication.shared.windows.first?.rootViewController {
        topViewController.present(alertController, animated: true, completion: nil)
    }
}

func showDoubleTextInputPopup(_ title: String, _ placeholderText1: String, _ placeholderText2: String, _ keyboardType: UIKeyboardType, completion: @escaping ((String?, String?)) -> Void) {
    let alertController = UIAlertController(title: title, message: nil, preferredStyle: .alert)
    
    alertController.addTextField { (textField) in
        textField.placeholder = placeholderText1
        textField.keyboardType = keyboardType
    }
    
    alertController.addTextField { (textField) in
        textField.placeholder = placeholderText2
        textField.keyboardType = keyboardType
    }
    
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
        completion((nil, nil))
    }
    alertController.addAction(cancelAction)
    
    let okAction = UIAlertAction(title: "OK", style: .default) { (_) in
        if let text = alertController.textFields?[0].text,
           let text2 = alertController.textFields?[1].text {
            completion((text, text2))
        } else {
            completion((nil, nil))
        }
    }
    alertController.addAction(okAction)
    
    if let topViewController = UIApplication.shared.windows.first?.rootViewController {
        topViewController.present(alertController, animated: true, completion: nil)
    }
}

#if os(iOS)
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
#endif
#else
import AppKit

func showPopup(_ title: String, _ message: String) {
    let alertController = NSAlert()
    alertController.messageText = title
    alertController.informativeText = message
    alertController.alertStyle = .informational
    alertController.addButton(withTitle: "OK")
    alertController.runModal()
}

func showConfirmPopup(_ title: String, _ message: String, completion: @escaping (Bool) -> Void) {
    let alert = NSAlert()
    alert.messageText = title
    alert.informativeText = message
    alert.alertStyle = .informational
    
    alert.addButton(withTitle: "Cancel")
    alert.addButton(withTitle: "OK")
    
    let response = alert.runModal()
    
    if response == .alertFirstButtonReturn {
        completion(false)
    } else if response == .alertSecondButtonReturn {
        completion(true)
    }
}

enum dummy_kbT {
    case URL
    case asciiCapable
}

func showTextInputPopup(_ title: String, _ placeholderText: String, _ keyboardType: dummy_kbT, completion: @escaping (String?) -> Void) {
    let alertController = NSAlert()
    alertController.messageText = title
    
    let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
    textField.placeholderString = placeholderText
    textField.isEditable = true
    textField.stringValue = ""
    alertController.accessoryView = textField
    
    alertController.addButton(withTitle: "Cancel")
    alertController.addButton(withTitle: "OK")
    
    let response = alertController.runModal()
    
    if response == .alertFirstButtonReturn {
        completion(nil)
    } else if response == .alertSecondButtonReturn {
        completion(textField.stringValue)
    }
}

func showDoubleTextInputPopup(_ title: String, _ placeholderText1: String, _ placeholderText2: String, _ keyboardType: dummy_kbT, completion: @escaping ((String?, String?)) -> Void) {
    let alertController = NSAlert()
    alertController.messageText = title
    
    let textField1 = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
    textField1.placeholderString = placeholderText1
    textField1.isEditable = true
    textField1.stringValue = ""
    
    let textField2 = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
    textField2.placeholderString = placeholderText2
    textField2.isEditable = true
    textField2.stringValue = ""
    
    let stackView = NSStackView(frame: NSRect(x: 0, y: 0, width: 200, height: 90))
    stackView.orientation = .vertical
    stackView.addView(textField1, in: .center)
    stackView.addView(textField2, in: .center)
    
    alertController.accessoryView = stackView
    
    alertController.addButton(withTitle: "Cancel")
    alertController.addButton(withTitle: "OK")
    
    let response = alertController.runModal()
    
    if response == .alertFirstButtonReturn {
        completion((nil, nil))
    } else if response == .alertSecondButtonReturn {
        completion((textField1.stringValue, textField2.stringValue))
    }
}
#endif
