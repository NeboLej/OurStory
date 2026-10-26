//
//  LaunchScreen.swift
//  OurStory
//

import SwiftUI
import Lottie

struct LaunchScreen: View {

    var onFinished: () -> Void

    var body: some View {
        ZStack {
            Color.backgroundFill
                .ignoresSafeArea()

            LottieView(animation: Bool.random() ? .named("our_story_launch") : .named("our_story_launch_v2"))
                .playing(loopMode: .playOnce)
                .animationDidFinish { completed in
                    guard completed else { return }
                    Task {
                        try await Task.sleep(for: .seconds(0.5))
                        onFinished()
                    }
                }
                .frame(width: 230)
                .padding(.bottom, 40)
        }
    }
}

#Preview {
    LaunchScreen {
        
    }
}
