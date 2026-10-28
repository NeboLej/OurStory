//
//  WavyLine.swift
//  OurStory
//
//  Created by Nebo on 28.10.2026.
//

import Foundation
import SwiftUI

struct WavyLine: Shape {
    
    var amplitude: CGFloat
    var wavelength: CGFloat
    
    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(amplitude, wavelength) }
        set {
            amplitude = newValue.first
            wavelength = newValue.second
        }
    }
    
    init(amplitude: CGFloat = 6, wavelength: CGFloat = 20) {
        self.amplitude = amplitude
        self.wavelength = wavelength
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midX = rect.midX
        let halfWave = wavelength / 2
        let steps = Int(rect.height / halfWave)
        
        path.move(to: CGPoint(x: midX, y: 0))
        
        for i in 0..<steps {
            let startY = CGFloat(i) * halfWave
            let endY = startY + halfWave
            let direction: CGFloat = i.isMultiple(of: 2) ? amplitude : -amplitude
            
            path.addQuadCurve(
                to: CGPoint(x: midX, y: endY),
                control: CGPoint(x: midX + direction, y: startY + halfWave * 0.5)
            )
        }
        
        let coveredY = CGFloat(steps) * halfWave
        if coveredY < rect.height {
            let direction: CGFloat = steps.isMultiple(of: 2) ? amplitude : -amplitude
            let remaining = rect.height - coveredY
            let ratio = remaining / halfWave
            
            path.addQuadCurve(
                to: CGPoint(x: midX + direction * ratio * 0.5, y: rect.height),
                control: CGPoint(x: midX + direction * ratio, y: coveredY + remaining * 0.5)
            )
        }
        
        return path
    }
}

#Preview {
    WavyLine(amplitude: 10, wavelength: 120)
        .stroke(.red, lineWidth: 12)
        .frame(width: 100)
}
