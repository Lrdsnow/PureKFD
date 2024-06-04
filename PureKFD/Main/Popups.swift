//
//  Popup.swift
//  PurePKG
//
//  Created by Lrdsnow on 3/18/24.
//

import Foundation
#if os(watchOS)
import WatchKit

func showPopup(_ title: String, _ message: String) {
    let action = WKAlertAction(title: "OK", style: .default) {}
    if let controller = WKApplication.shared().rootInterfaceController {
        controller.presentAlert(withTitle: title, message: message, preferredStyle: .alert, actions: [action])
    }
}

func showTextInputPopup(_ title: String, _ placeholderText: String, completion: @escaping (String?) -> Void) {
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

func showTextInputPopup(_ title: String, _ placeholderText: String, _ keyboardType: NSAlert.Style, completion: @escaping (String?) -> Void) {
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
#endif
