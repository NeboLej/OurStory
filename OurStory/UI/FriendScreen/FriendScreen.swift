//
//  FriendScreen.swift
//  OurStory
//
//  Created by Nebo on 18.09.2026.
//

import SwiftUI

struct FriendScreen: View {
    
    @State var store: FriendScreenStore
    @State var isEditMode: Bool = false
    @State var name: String = ""
    @State var selectedColor: Color = .red
    
    @State private var showUserSuggestion: Bool = false
    
    // Анимация поиска (пульс вокруг аватара)
    @State private var searchPulse: CGFloat = 1.0
    
    // Анимация ритуала — позиции точек
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
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        if isEditMode {
                            editMode()
                        } else {
                            showMode()
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                if isEditMode {
                    deleteButton()
                } else {
                    syncButton()
                }
            }
            
            if store.state.isInRitualSync {
                ritualSyncOverlay()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: store.state.isInRitualSync)
        .frame(maxWidth: .infinity)
        .background(.backgroundFill)
        .navigationBarBackButtonHidden(isEditMode || store.state.isInRitualSync)
        .toolbar {
            if isEditMode {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation {
                            isEditMode = false
                            name = store.state.friend.name
                            selectedColor = Color(hex: store.state.friend.color)
                        }
                    } label: {
                        Text("ОТМЕНА")
                            .font(.mySemiBold(size: 11))
                            .tracking(1.5)
                            .foregroundStyle(Color.textMulticolor.opacity(0.6))
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .overlay {
                                Rectangle()
                                    .stroke(Color.textMulticolor.opacity(0.2), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .fixedSize()
                }.sharedBackgroundVisibility(.hidden)
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation {
                        if isEditMode {
                            store.send(.editFriend(name: name, color: selectedColor.toHex()))
                        }
                        isEditMode.toggle()
                    }
                } label: {
                    Text(isEditMode ? "СОХРАНИТЬ" : "ИЗМЕНИТЬ")
                        .font(.mySemiBold(size: 11))
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
                .opacity(store.state.isInRitualSync ? 0 : 1)
            }
            .sharedBackgroundVisibility(.hidden)
            
        }
        .onAppear {
            name = store.state.friend.name
            selectedColor = Color(hex: store.state.friend.color)
            showUserSuggestion = false
            store.send(.startSearching, animation: nil)
        }
        .onDisappear {
            store.send(.stopSearching, animation: nil)
        }
        .onChange(of: store.state.ritualPhase) { _, newPhase in
            animateToPhase(newPhase)
        }
        .onChange(of: store.syncPgogressStates) {
            if store.syncPgogressStates.last == .completed && store.hasUserProfileDifference {
                showUserSuggestion = true
            }
        }
    }
    
    // MARK: - Анимация фаз ритуала
    
    private func animateToPhase(_ phase: SyncRitualPhase) {
        switch phase {
        case .searching:
            withAnimation(.easeOut(duration: 1.2)) {
                leftDotOffset = -100
                rightDotOffset = 100
                dotsOpacity = 1.0
                showMergedCircle = false
                mergedScale = 0.5
            }
            // Запускаем плавающую анимацию для обеих точек
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
            // Останавливаем плавание — возвращаем в центральную линию
            withAnimation(.easeOut(duration: 0.8)) {
                leftDotFloatY = 0
                leftDotFloatX = 0
                rightDotFloatY = 0
                rightDotFloatX = 0
            }
            withAnimation(.easeInOut(duration: 5.0)) {
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
    
    // MARK: - Статус поиска
    
    @ViewBuilder
    private func searchStatusView() -> some View {
        Group {
            switch store.state.searchStatus {
            case .idle:
                EmptyView()
            case .searching:
                Text("ищу \(store.state.friend.name.lowercased())...")
                    .font(.myItalic(size: 13))
                    .foregroundStyle(.textMulticolor.opacity(0.45))
            case .found:
                VStack(spacing: 2) {
                    Text("\(store.state.friend.name) рядом")
                        .font(.myItalic(size: 14))
                        .foregroundStyle(.textMulticolor.opacity(0.7))
                    Text("и готова слушать")
                        .font(.myItalic(size: 12))
                        .foregroundStyle(.textMulticolor.opacity(0.4))
                }
            case .notFound:
                VStack(spacing: 10) {
                    Text("не удалось найти")
                        .font(.myItalic(size: 12))
                        .foregroundStyle(.textMulticolor.opacity(0.35))
                    
                    Button {
                        store.send(.retrySearching)
                    } label: {
                        Text("НАЙТИ \(store.state.friend.name.uppercased())")
                            .font(.mySemiBold(size: 11))
                            .tracking(1.5)
                            .foregroundStyle(.textMulticolor.opacity(0.7))
                            .padding(.vertical, 7)
                            .padding(.horizontal, 14)
                            .overlay {
                                Rectangle()
                                    .stroke(Color.textMulticolor.opacity(0.25), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .animation(.easeInOut(duration: 0.5), value: store.state.searchStatus)
    }
    
    @ViewBuilder
    private func statisticElement(title: String, value: String, onClick: (() -> Void)?) -> some View {
        Button {
            onClick?()
        } label: {
            HStack(alignment: .center, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title.uppercased())
                        .font(.mySemiBold(size: 10))
                        .tracking(1.5)
                        .foregroundStyle(.textMulticolor.opacity(0.75))
                    
                    if onClick == nil {
                        Text(value)
                            .font(.myMedium(size: 14))
                            .foregroundStyle(.textMulticolor.opacity(0.5))
                    }
                }
                
                Spacer()
                
                if onClick != nil {
                    Text(value)
                        .font(.mySemiBold(size: 20))
                        .foregroundStyle(.textMulticolor)
                        .padding(.trailing, 8)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.textMulticolor.opacity(0.4))
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 4)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .frame(height: 0.5)
                .foregroundStyle(.textMulticolor.opacity(0.2))
        }
        .disabled(onClick == nil)
    }
    
    // MARK: - Предложение обновить профиль
    @ViewBuilder
    private func userSuggestionBanner(showCloseButton: Bool = true) -> some View {
        if let user = store.state.friend.user, store.hasUserProfileDifference {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 0) {
                    Text("ПРЕДЛОЖЕНИЕ")
                        .font(.mySemiBold(size: 10))
                        .tracking(1.5)
                        .foregroundStyle(.textMulticolor.opacity(0.5))
                    Spacer()
                    if showCloseButton {
                        Button {
                            withAnimation {
                                showUserSuggestion = false
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.textMulticolor.opacity(0.4))
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Text("Ваш друг указал другое имя и цвет для своего профиля")
                    .font(.myRegular(size: 13))
                    .foregroundStyle(.textMulticolor.opacity(0.7))
                
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: user.color))
                            .frame(width: 32, height: 32)
                        Circle()
                            .stroke(Color.backgroundFill, lineWidth: 1.5)
                            .frame(width: 28, height: 28)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        if user.name != store.state.friend.name {
                            HStack(spacing: 4) {
                                Text(store.state.friend.name)
                                    .font(.myRegular(size: 13))
                                    .foregroundStyle(.textMulticolor.opacity(0.4))
                                    .strikethrough()
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.textMulticolor.opacity(0.4))
                                Text(user.name)
                                    .font(.myMedium(size: 14))
                                    .foregroundStyle(.textMulticolor)
                            }
                        }
                        if user.color != store.state.friend.color {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color(hex: store.state.friend.color))
                                    .frame(width: 12, height: 12)
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.textMulticolor.opacity(0.4))
                                Circle()
                                    .fill(Color(hex: user.color))
                                    .frame(width: 12, height: 12)
                            }
                        }
                    }
                }
                
                HStack(spacing: 12) {
                    Button {
                        withAnimation {
                            store.send(.applyUserProfile)
                            name = user.name
                            selectedColor = Color(hex: user.color)
                            showUserSuggestion = false
                        }
                    } label: {
                        Text("ПРИМЕНИТЬ")
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
            .padding(14)
            .overlay {
                Rectangle()
                    .stroke(Color.textMulticolor.opacity(0.15), lineWidth: 1)
            }
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }
    
    // MARK: - Режим Просмотра
    @ViewBuilder
    private func showMode() -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                // Аватар друга с пульсирующим кольцом при поиске
                ZStack {
                    if store.state.searchStatus == .searching {
                        Circle()
                            .fill(Color(hex: store.state.friend.color).opacity(0.12))
                            .frame(width: 68, height: 68)
                            .scaleEffect(searchPulse)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                    searchPulse = 1.3
                                }
                            }
                            .onDisappear {
                                searchPulse = 1.0
                            }
                    }
                    
                    ZStack {
                        Circle()
                            .fill(Color(hex: store.state.friend.color))
                            .frame(width: 48, height: 48)
                        Circle()
                            .stroke(Color.backgroundFill, lineWidth: 2)
                            .frame(width: 44, height: 44)
                    }
                }
                .animation(.easeInOut(duration: 0.4), value: store.state.searchStatus)
                
                let displayName: String = {
                    guard let user = store.state.friend.user, user.name != store.state.friend.name else {
                        return store.state.friend.name.uppercased()
                    }
                    return store.state.friend.name.uppercased() + "/" + user.name.uppercased()
                }()
                Text(displayName)
                    .font(.myMedium(size: 22))
                    .tracking(1)
                    .foregroundColor(.textMulticolor)
                
                // Статус поиска
                searchStatusView()
            }
            .padding(.top, 32)
            .padding(.bottom, 40)
            
            if showUserSuggestion {
                userSuggestionBanner()
                    .padding(.bottom, 16)
            }
            
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(.textMulticolor.opacity(0.35))
            
            statisticElement(title: "Общих историй", value: "\(store.state.allStoriesCount)") {
                // Действие
            }
            
            statisticElement(title: "Историй не рассказано", value: "\(store.state.notSeenStoriesCount)") {
                // Действие
            }
            
            statisticElement(title: "Последняя синхронизация", value: store.state.lastSyncDate?.toReadableDate() ?? "—", onClick: nil)
        }
    }
    
    // MARK: - Ритуальный оверлей синхронизации
    
    @ViewBuilder
    private func ritualSyncOverlay() -> some View {
        ZStack {
            Color.backgroundFill
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                ritualDotsAnimation()
                    .frame(height: 160)
                
                ritualStatusText()
                    .padding(.top, 40)
                
                Spacer()
                
                ritualBottomArea()
                    .padding(.bottom, 32)
                    .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Анимация двух точек
    
    @ViewBuilder
    private func ritualDotsAnimation() -> some View {
        let friendColor = Color(hex: store.state.friend.color)
        let userColor = Color(hex: store.appStore.user.color)
        let dotSize: CGFloat = 36
        
        ZStack {
            // Левая точка (пользователь)
            Circle()
                .fill(userColor)
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
                .fill(friendColor)
                .frame(width: dotSize, height: dotSize)
                .overlay {
                    Circle()
                        .stroke(Color.backgroundFill, lineWidth: 2)
                        .frame(width: dotSize - 4, height: dotSize - 4)
                }
                .offset(x: rightDotOffset + rightDotFloatX, y: rightDotFloatY)
                .opacity(dotsOpacity)
            
            // Тонкая линия между точками (когда сближаются)
            if store.state.ritualPhase == .approaching || store.state.ritualPhase == .waitingForConfirmation(User(name: "", color: "")) || abs(leftDotOffset) < 80 {
                let lineApproaching = store.state.ritualPhase == .approaching
                Rectangle()
                    .fill(Color.textMulticolor.opacity(lineApproaching ? 0.1 : 0.05))
                    .frame(width: max(0, rightDotOffset - leftDotOffset - dotSize), height: 1)
            }
            
            // Объединённый круг (появляется при слиянии)
            if showMergedCircle {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [userColor, friendColor],
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
    
    // MARK: - Текст статуса ритуала
    
    @ViewBuilder
    private func ritualStatusText() -> some View {
        let friendName = store.state.friend.name.lowercased()
        
        VStack(spacing: 6) {
            switch store.state.ritualPhase {
            case .searching:
                Text("ищу \(friendName)...")
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
                Text("спасибо, что поделились")
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
        .animation(.easeInOut(duration: 1.0), value: store.state.ritualPhase)
    }
    
    // MARK: - Нижняя область ритуала
    
    @ViewBuilder
    private func ritualBottomArea() -> some View {
        switch store.state.ritualPhase {
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
                        store.send(.confirmSyncFriend(false))
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
                        store.send(.confirmSyncFriend(true))
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
                    
                    Button {
                        store.send(.toNewNotes)
                    } label: {
                        Text("ПОСМОТРЕТЬ ИСТОРИИ")
                            .font(.mySemiBold(size: 12))
                            .tracking(1.5)
                            .foregroundStyle(.textMulticolor.opacity(0.85))
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                            .overlay {
                                Rectangle()
                                    .stroke(Color.textMulticolor.opacity(0.35), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                }
                
                Button {
                    store.send(.exitSync)
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
            .transition(.opacity.combined(with: .move(edge: .bottom)))
            
        case .failed:
            Button {
                store.send(.exitSync)
            } label: {
                Text("ЗАКРЫТЬ")
                    .font(.mySemiBold(size: 14))
                    .tracking(2)
                    .foregroundStyle(.textMulticolor)
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
            .transition(.opacity)
            
        default:
            EmptyView()
        }
    }
    
    // MARK: - Режим Редактирования
    @ViewBuilder
    private func editMode() -> some View {
        VStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("РЕДАКТИРОВАТЬ\nПРОФИЛЬ")
                    .font(.mySemiBold(size: 25))
                    .tracking(2)
                    .foregroundColor(.textMulticolor)
                
                VStack(spacing: 4) {
                    Divider().frame(height: 3).background(.textMulticolor)
                    Divider().frame(height: 0.5).background(.textMulticolor)
                }
                .padding(.top, 4)
            }
            .padding(.bottom, 40)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("ИМЯ ПОЛЬЗОВАТЕЛЯ")
                    .font(.myMedium(size: 12))
                    .tracking(3)
                    .foregroundColor(.textMulticolor)
                
                TextField("Введите имя...", text: $name)
                    .font(.myItalic(size: 20))
                    .foregroundColor(.textMulticolor)
                    .tint(.textMulticolor)
                    .padding(.vertical, 8)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Color(hex: "#A39E93"))
                    }
            }
            .padding(.bottom, 40)
            
            VStack(alignment: .leading, spacing: 16) {
                Text("ЦВЕТОВАЯ МЕТКА")
                    .font(.myMedium(size: 12))
                    .tracking(3)
                    .foregroundColor(.textMulticolor)
                
                CustomColorPicker(selectedColor: $selectedColor)
            }
            
            if store.hasUserProfileDifference {
                userSuggestionBanner(showCloseButton: false)
                    .padding(.top, 24)
            }
        }
    }
    
    // MARK: - Нижние кнопки
    @ViewBuilder
    private func syncButton() -> some View {
        let isEnabled = store.state.isSyncButtonEnabled
        
        Button {
            store.send(.syncFriend)
        } label: {
            VStack(spacing: 2) {
                Text("РАССКАЗАТЬ ИСТОРИИ")
                    .font(.mySemiBold(size: 14))
                    .tracking(2)
                    .foregroundStyle(.black.opacity(isEnabled ? 1 : 0.3))
                
                if store.state.searchStatus == .found {
                    Text("начать обмен историями")
                        .font(.myRegular(size: 10))
                        .opacity(0.5)
                        .foregroundStyle(.black)
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.myPrimary.opacity(isEnabled ? 1 : 0.35))
            .overlay {
                Rectangle()
                    .stroke(Color.black.opacity(0.15), lineWidth: 1)
                    .padding(3)
            }
        }
        .disabled(!isEnabled)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.4), value: isEnabled)
    }
    
    @ViewBuilder
    private func deleteButton() -> some View {
        Button {
            store.send(.deleteFriend)
            dismiss()
        } label: {
            VStack(spacing: 2) {
                Text("УДАЛИТЬ ДРУГА")
                    .font(.mySemiBold(size: 14))
                    .tracking(2)
                    .foregroundStyle(.black)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.red.opacity(0.7))
            .overlay {
                Rectangle()
                    .stroke(Color.black.opacity(0.15), lineWidth: 1)
                    .padding(3)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .buttonStyle(.plain)
    }
}


#Preview {
    NavigationStack {
        ScreenBuilder.previewBuilder.getScreen(type: .friend(Friend(name: "София", color: "F16C6C")))
    }
}
