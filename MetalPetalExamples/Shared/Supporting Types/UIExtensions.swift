//
//  UIExtensions.swift
//  MetalPetalDemo
//
//  Created by YuAo on 2021/4/4.
//

import Foundation
import SwiftUI

extension Color {
    static var secondarySystemBackground: Color {
        #if os(iOS)
        return Color(UIColor.secondarySystemBackground)
        #elseif os(macOS)
        return Color(NSColor.controlBackgroundColor)
        #else
        #error("Unsupported Platform")
        #endif
    }
}

extension Image {
    init(cgImage: CGImage) {
        #if os(iOS)
        self.init(uiImage: UIImage(cgImage: cgImage))
        #elseif os(macOS)
        self.init(nsImage: NSImage(cgImage: cgImage, size: CGSize(width: cgImage.width, height: cgImage.height)))
        #else
        #error("Unsupported Platform")
        #endif
    }
}

extension Button {
    func linkButtonStyle() -> some View {
        #if os(macOS)
        return self.buttonStyle(LinkButtonStyle()).onHover(perform: { isHover in
            if isHover {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        })
        #else
        return self
        #endif
    }
}

extension View {
    func roundedRectangleButtonStyle() -> some View {
        #if os(iOS)
        return self.padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
            .background(RoundedRectangle(cornerRadius: 10)
                            .foregroundColor(Color.secondarySystemBackground))
        #else
        return self
        #endif
    }
    
    func stackNavigationViewStyle() -> some View {
        #if os(iOS)
        return self.navigationViewStyle(StackNavigationViewStyle())
        #else
        return self
        #endif
    }
    
    func groupedListStyle() -> some View {
        #if os(iOS)
        return self.listStyle(GroupedListStyle())
        #else
        return self
        #endif
    }
    
    func inlineNavigationBarTitle<T>(_ title: T) -> some View where T: StringProtocol {
        #if os(iOS)
        return self.navigationBarTitle(title, displayMode: .inline)
        #else
        return self.navigationTitle(title)
        #endif
    }
    
    func largeControlSize() -> some View {
        #if os(macOS)
        return self.controlSize(.large)
        #else
        return self
        #endif
    }
    
    func smallControlSize() -> some View {
        #if os(macOS)
        return self.controlSize(.small)
        #else
        return self
        #endif
    }
    
    func toolbarMenu<T>(_ menu: T) -> some View where T: View {
        #if os(iOS)
        return self.navigationBarItems(trailing: menu)
        #else
        return self.toolbar(content: {
            menu
        })
        #endif
    }
    
    func pickerWidthLimit(_ width: CGFloat) -> some View {
        #if os(macOS)
        return self.frame(maxWidth: width)
        #else
        return self
        #endif
    }
    
    func blurBackgroundEffect(cornerRadius: CGFloat) -> some View {
        #if os(macOS)
        return self.background(VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow, state: .followsWindowActiveState).clipShape(RoundedRectangle(cornerRadius: cornerRadius)))
        #elseif os(iOS)
        return self.background(VisualEffectBlur(blurStyle: .systemThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: cornerRadius)))
        #endif
    }
}

#if os(iOS)

extension UIApplication {
    var topMostViewController: UIViewController? {
        let rootWindow = self.windows.first(where: { $0.isHidden == false })
        var topMostViewController: UIViewController? = rootWindow?.rootViewController
        while topMostViewController?.presentedViewController != nil {
            topMostViewController = topMostViewController?.presentedViewController
        }
        return topMostViewController
    }
}

#endif
