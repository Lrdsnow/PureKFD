//
//  Compat.swift
//  purekfd
//
//  Created by Lrdsnow on 6/28/24.
//

import SwiftUI

#if os(iOS)
extension View {
    @ViewBuilder
    func ios16padding() -> some View {
        if #available(iOS 16.0, *) {
            self.padding(.top, 25)
        } else {
            self
        }
    }
}
#endif

struct ColorDivider: View {
    let color: Color
    let height: CGFloat
    
    init(color: Color, height: CGFloat = 0.5) {
        self.color = color
        self.height = height
    }
    
    var body: some View {
        color
            .frame(height: height)
    }
}

extension Dictionary: RawRepresentable where Key == String, Value == String {
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
            let result = try? JSONDecoder().decode([String:String].self, from: data)
        else {
            return nil
        }
        self = result
    }

    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8)
        else {
            return "{}"  // empty Dictionary resprenseted as String
        }
        return result
    }

}

struct NavigationViewC<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
#if os(macOS)
        NavigationStack {
            content
        }
#else
        NavigationView {
            content
        }.navigationViewStyle(.stack)
#endif
    }
}
