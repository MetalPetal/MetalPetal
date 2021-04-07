//
//  NoteView.swift
//  MetalPetalDemo
//
//  Created by YuAo on 2021/4/5.
//

import Foundation
import SwiftUI

struct NoteView<T>: View where T: View{
    private let text: T
    
    init(@ViewBuilder _ content: () -> T) {
        text = content()
    }
    
    init<S>(text: S) where S: StringProtocol, T == Text {
        self.text = Text(text)
    }
    
    var body: some View {
        text.font(Font.caption)
            .frame(maxWidth: 180)
            .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
            .background(RoundedRectangle(cornerRadius: 10)
                            .foregroundColor(Color.secondarySystemBackground))
    }
}

extension View {
    func noteOverlay<T>(_ note: NoteView<T>, isHidden: Bool = false) -> some View {
        Group {
            if isHidden {
                self
            } else {
                ZStack {
                    self
                    VStack {
                        HStack {
                            note
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding()
                }
            }
        }
    }
}
