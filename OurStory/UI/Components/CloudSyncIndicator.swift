//
//  CloudSyncIndicator.swift
//  OurStory
//

import SwiftUI

struct CloudSyncIndicator: View {
    
    @State private var opacity: Double = 0.3
    
    var body: some View {
        Image(systemName: "icloud")
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(.textMulticolor.opacity(opacity))
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    opacity = 0.9
                }
            }
    }
}

#Preview {
    CloudSyncIndicator()
}
