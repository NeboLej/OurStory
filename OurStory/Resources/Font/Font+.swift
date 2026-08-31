//
//  Font+.swift
//  OurStory
//
//  Created by Nebo on 31.08.2026.
//

import SwiftUI

extension Font {
    
    static func myMedium(size: CGFloat) -> Font {
        Font.custom("Lora-Medium", size: size)
    }
    
    static func myRegular(size: CGFloat) -> Font {
        Font.custom("Lora-Regular", size: size)
    }
    
    static func myItalic(size: CGFloat) -> Font {
        Font.custom("Lora-Italic", size: size)
    }
    
    static func mySemiBold(size: CGFloat) -> Font {
        Font.custom("Lora-SemiBold", size: size)
    }
    
    static func mySemiBoldItalic(size: CGFloat) -> Font {
        Font.custom("Lora-SemiBoldItalic", size: size)
    }
}
