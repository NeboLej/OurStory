//
//  CustomColorPicker.swift
//  OurStory
//
//  Created by Nebo on 21.09.2026.
//

import Foundation
import SwiftUI

struct CustomColorPicker: View {
    @Binding var selectedColor: Color
    
    @State var vintageColors: [Color] = [
        .red, .orange, .yellow, .green, .mint, .teal,
        .blue, .indigo, .purple, .pink, .gray
    ]
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 6)
    
    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
            ForEach(vintageColors, id: \.self) { color in
                ZStack {
                    Circle()
                        .stroke(Color.textMulticolor.opacity(0.85), lineWidth: selectedColor == color ? 1.5 : 0)
                        .frame(width: 36, height: 36)
                    
                    Circle()
                        .fill(color)
                        .frame(width: 26, height: 26)
                }
                .contentShape(Circle())
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        selectedColor = color
                    }
                }
            }
            
            ColorPicker("Другой цвет", selection: $selectedColor, supportsOpacity: false)
                .labelsHidden()
                .overlay {
                    Circle()
                        .stroke(Color.textMulticolor.opacity(0.85), lineWidth: !vintageColors.contains(selectedColor) ? 1.5 : 0)
                        .frame(width: 36, height: 36)
                }
                
        }
        .onAppear {
            if !vintageColors.contains(selectedColor) {
                vintageColors.insert(selectedColor, at: 0)
                if vintageColors.count > 11 {
                    vintageColors = vintageColors.dropLast()
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var selectedColor: Color = .red
    
    CustomColorPicker(selectedColor: $selectedColor)
}
