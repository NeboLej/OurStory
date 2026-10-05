//
//  OnboardingScreen.swift
//  OurStory
//

import SwiftUI

struct OnboardingScreen: View {
    
    @State private var store: OnboardingScreenStore
    @State private var name: String = ""
    @State private var selectedColor: Color = Color.pickerColors.randomElement()!
    @FocusState private var isNameFocused: Bool
    
    init(store: OnboardingScreenStore) {
        self.store = store
    }
    
    private var isSaveDisabled: Bool {
        name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        ZStack {
            Color(.backgroundFill)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("НАШИ\nИСТОРИИ")
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
                    Text("МОЕ ИМЯ")
                        .font(.myMedium(size: 12))
                        .tracking(3)
                        .foregroundColor(.textMulticolor)
                    
                    TextField("Введите ваше имя...", text: $name)
                        .font(.myItalic(size: 20))
                        .foregroundColor(.textMulticolor)
                        .tint(.textMulticolor)
                        .focused($isNameFocused)
                        .submitLabel(.done)
                        .onSubmit { isNameFocused = false }
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
                
                Spacer()
                
                Button {
                    store.send(.saveProfile(name: name.trimmingCharacters(in: .whitespaces),
                                            color: selectedColor.toHex()))
                } label: {
                    Text("ПРОДОЛЖИТЬ")
                        .font(.mySemiBold(size: 14))
                        .tracking(2)
                        .foregroundStyle(isSaveDisabled ? Color.textMulticolor.opacity(0.3) : Color.textMulticolor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .overlay {
                            Rectangle()
                                .stroke(isSaveDisabled ? Color.textMulticolor.opacity(0.2) : Color.textMulticolor.opacity(0.5), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .disabled(isSaveDisabled)
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .background(.backgroundFill)
        .onAppear { isNameFocused = true }
    }
}

#Preview {
    ScreenBuilder.previewBuilder.getScreen(type: .onboarding)
}
