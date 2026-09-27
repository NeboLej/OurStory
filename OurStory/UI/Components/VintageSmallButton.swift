//
//  VintageSmallButton.swift
//  OurStory
//
//  Created by Nebo on 27.09.2026.
//

import SwiftUI

struct VintageSmallButton: View {
    
    var title: String
    var onTap: () -> Void
    
    var body: some View {
        Button {
            withAnimation {
                onTap()
            }
        } label: {
            Text(title)
                .font(.mySemiBold(size: 12))
                .tracking(1.5)
                .foregroundStyle(Color.textMulticolor.opacity(0.85))
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                
                .overlay {
                    Rectangle()
                        .stroke(Color.textMulticolor.opacity(0.35), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VintageSmallButton(title: "sdadsa") {
        
    }
}
