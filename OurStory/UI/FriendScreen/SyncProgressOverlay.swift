//
//  SyncProgressOverlay.swift
//  OurStory
//

import SwiftUI

struct SyncProgressOverlay: View {
    
    let syncPhase: SyncPhase
    let friendName: String
    let friendColor: String
    let userColor: String
    
    var onConfirmSync: (Bool) -> Void
    var onToNewNotes: () -> Void
    var onExitSync: () -> Void
    
    // Анимация — позиции точек
    @State private var leftDotOffset: CGFloat = -120
    @State private var rightDotOffset: CGFloat = 120
    @State private var dotsOpacity: Double = 1.0
    @State private var showMergedCircle: Bool = false
    @State private var mergedScale: CGFloat = 0.5
    @State private var mergedPulse: CGFloat = 1.0
    
    // Плавающая анимация точки пользователя во время поиска
    @State private var leftDotFloatY: CGFloat = 0
    @State private var leftDotFloatX: CGFloat = 0
    @State private var rightDotFloatY: CGFloat = 0
    @State private var rightDotFloatX: CGFloat = 0
    
    private var isWaitingForConfirmation: Bool {
        if case .waitingForConfirmation = syncPhase { return true }
        return false
    }
    
    var body: some View {
        ZStack {
            Color.backgroundFill
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                dotsAnimation()
                    .frame(height: 160)
                
                statusText()
                    .padding(.top, 40)
                
                Spacer()
                
                bottomArea()
                    .padding(.bottom, 32)
                    .padding(.horizontal, 20)
            }
            .frame(maxWidth: .infinity)
            .overlay(alignment: .topTrailing) {
                switch syncPhase {
                case .completed: EmptyView()
                default :
                    Button {
                        onExitSync()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.textMulticolor.opacity(0.6))
                            .padding(.trailing, 24)
                            .padding(.top, 8)
                    }
                }
            }
        }
        .onAppear {
            animateToPhase(syncPhase)
        }
        .onChange(of: syncPhase) { _, newPhase in
            animateToPhase(newPhase)
        }
    }
    
    private func animateToPhase(_ phase: SyncPhase) {
        switch phase {
        case .searching:
            withAnimation(.easeOut(duration: 1.2)) {
                leftDotOffset = -100
                rightDotOffset = 100
                dotsOpacity = 1.0
                showMergedCircle = false
                mergedScale = 0.5
            }
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                leftDotFloatY = -12
                leftDotFloatX = 8
            }
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true).delay(0.5)) {
                rightDotFloatY = 10
                rightDotFloatX = -6
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            
        case .approaching:
            withAnimation(.easeOut(duration: 0.8)) {
                leftDotFloatY = 0
                leftDotFloatX = 0
                rightDotFloatY = 0
                rightDotFloatX = 0
            }
            withAnimation(.easeInOut(duration: 4.5)) {
                leftDotOffset = -22
                rightDotOffset = 22
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            
        case .merging:
            withAnimation(.spring(response: 1.2, dampingFraction: 0.6)) {
                leftDotOffset = 0
                rightDotOffset = 0
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.6)) {
                dotsOpacity = 0
            }
            withAnimation(.spring(response: 0.8, dampingFraction: 0.55).delay(1.0)) {
                showMergedCircle = true
                mergedScale = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }
            
        case .completed:
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                mergedPulse = 1.06
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            
        case .failed:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            
        case .waitingForConfirmation:
            withAnimation(.spring(response: 1.4, dampingFraction: 0.8)) {
                leftDotOffset = -40
                rightDotOffset = 40
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            
        case .idle:
            withAnimation(.easeOut(duration: 0.5)) {
                leftDotOffset = -120
                rightDotOffset = 120
                dotsOpacity = 1.0
                showMergedCircle = false
                mergedScale = 0.5
                mergedPulse = 1.0
                leftDotFloatY = 0
                leftDotFloatX = 0
                rightDotFloatY = 0
                rightDotFloatX = 0
            }
        }
    }
    
    // MARK: - Анимация двух точек
    
    @ViewBuilder
    private func dotsAnimation() -> some View {
        let fColor = Color(hex: friendColor)
        let uColor = Color(hex: userColor)
        let dotSize: CGFloat = 36
        
        ZStack {
            // Левая точка (пользователь)
            Circle()
                .fill(uColor)
                .frame(width: dotSize, height: dotSize)
                .overlay {
                    Circle()
                        .stroke(Color.backgroundFill, lineWidth: 2)
                        .frame(width: dotSize - 4, height: dotSize - 4)
                }
                .offset(x: leftDotOffset + leftDotFloatX, y: leftDotFloatY)
                .opacity(dotsOpacity)
            
            // Правая точка (друг)
            Circle()
                .fill(fColor)
                .frame(width: dotSize, height: dotSize)
                .overlay {
                    Circle()
                        .stroke(Color.backgroundFill, lineWidth: 2)
                        .frame(width: dotSize - 4, height: dotSize - 4)
                }
                .offset(x: rightDotOffset + rightDotFloatX, y: rightDotFloatY)
                .opacity(dotsOpacity)
            
            // Тонкая линия между точками (когда сближаются)
            if syncPhase == .approaching || isWaitingForConfirmation || abs(leftDotOffset) < 80 {
                let lineApproaching = syncPhase == .approaching
                Rectangle()
                    .fill(Color.textMulticolor.opacity(lineApproaching ? 0.1 : 0.05))
                    .frame(width: max(0, rightDotOffset - leftDotOffset - dotSize), height: 1)
            }
            
            // Объединённый круг (появляется при слиянии)
            if showMergedCircle {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [uColor, fColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 52, height: 52)
                    .overlay {
                        Circle()
                            .stroke(Color.backgroundFill, lineWidth: 2)
                            .frame(width: 48, height: 48)
                    }
                    .scaleEffect(mergedScale * mergedPulse)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    // MARK: - Текст статуса
    
    @ViewBuilder
    private func statusText() -> some View {
        let name = friendName.lowercased()
        
        VStack(spacing: 6) {
            switch syncPhase {
            case .searching:
                Text("ищу \(name)...")
                    .font(.myItalic(size: 16))
                    .foregroundStyle(.textMulticolor.opacity(0.5))
                    .transition(.opacity)
            case .approaching:
                Text("рассказываю истории")
                    .font(.myItalic(size: 16))
                    .foregroundStyle(.textMulticolor.opacity(0.7))
                    .transition(.opacity)
            case .merging:
                Text("истории встретились")
                    .font(.myMedium(size: 17))
                    .foregroundStyle(.textMulticolor.opacity(0.85))
                    .transition(.opacity)
            case .completed:
                Text("здорово, что поделились")
                    .font(.myMedium(size: 17))
                    .foregroundStyle(.textMulticolor)
                    .transition(.opacity)
            case .failed(let message):
                VStack(spacing: 4) {
                    Text("не получилось")
                        .font(.myMedium(size: 16))
                        .foregroundStyle(.textMulticolor.opacity(0.7))
                    Text(message)
                        .font(.myRegular(size: 12))
                        .foregroundStyle(.textMulticolor.opacity(0.4))
                        .multilineTextAlignment(.center)
                }
                .transition(.opacity)
            case .waitingForConfirmation:
                Text("ожидаю подтверждения")
                    .font(.myItalic(size: 15))
                    .foregroundStyle(.textMulticolor.opacity(0.6))
                    .transition(.opacity)
            case .idle:
                EmptyView()
            }
        }
        .animation(.easeInOut(duration: 1.0), value: syncPhase)
    }
    
    @ViewBuilder
    private func bottomArea() -> some View {
        switch syncPhase {
        case .waitingForConfirmation(let user):
            VStack(spacing: 16) {
                Text("обменяться историями с \(user.name)?")
                    .font(.myRegular(size: 14))
                    .foregroundStyle(.textMulticolor.opacity(0.7))
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: user.color))
                            .frame(width: 32, height: 32)
                        Circle()
                            .stroke(Color.backgroundFill, lineWidth: 1.5)
                            .frame(width: 28, height: 28)
                    }
                    Text(user.name)
                        .font(.myMedium(size: 16))
                        .foregroundStyle(.textMulticolor)
                }
                
                HStack(spacing: 20) {
                    Button {
                        onConfirmSync(false)
                    } label: {
                        Text("ОТМЕНИТЬ")
                            .font(.mySemiBold(size: 12))
                            .tracking(1.5)
                            .foregroundStyle(.textMulticolor.opacity(0.5))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .overlay {
                                Rectangle()
                                    .stroke(Color.textMulticolor.opacity(0.2), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        onConfirmSync(true)
                    } label: {
                        Text("ОБМЕНЯТЬСЯ")
                            .font(.mySemiBold(size: 12))
                            .tracking(1.5)
                            .foregroundStyle(.textMulticolor.opacity(0.85))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .overlay {
                                Rectangle()
                                    .stroke(Color.textMulticolor.opacity(0.35), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .transition(.opacity.combined(with: .move(edge: .bottom)))
            
        case .completed(let newCount):
            VStack(spacing: 16) {
                if newCount > 0 {
                    Text("получено историй: \(newCount)")
                        .font(.myRegular(size: 13))
                        .foregroundStyle(.textMulticolor.opacity(0.6))

                    VintageSmallButton(title: "ПОСМОТРЕТЬ ИСТОРИИ") {
                        onToNewNotes()
                    }
                }
                
                exitButton()
            }
            .transition(.opacity.combined(with: .move(edge: .bottom)))
            
        case .failed:
            exitButton()
                .transition(.opacity)
            
        default:
            EmptyView()
        }
    }
    
    @ViewBuilder
    private func exitButton() -> some View {
        Button {
            onExitSync()
        } label: {
            Text("ЗАКРЫТЬ")
                .font(.mySemiBold(size: 14))
                .tracking(2)
                .foregroundStyle(.titleDark)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.myPrimary)
                .overlay {
                    Rectangle()
                        .stroke(Color.textMulticolor.opacity(0.15), lineWidth: 1)
                        .padding(3)
                }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SyncProgressOverlay(syncPhase: .completed(newCount: 3), friendName: "sdf", friendColor: "44ff32", userColor: "33eedd") { isBool in
        
    } onToNewNotes: {
        
    } onExitSync: {
        
    }
    
}
