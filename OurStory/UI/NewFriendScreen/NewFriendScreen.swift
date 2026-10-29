//
//  NewFriendScreen.swift
//  OurStory
//
//  Created by Nebo on 21.09.2026.
//

import SwiftUI

struct NewFriendScreen: View {
    @State private var store: NewFriendScreenStore
    @State private var name: String = ""
    @State private var selectedColor: Color = Color.pickerColors.randomElement()!
    @State private var selectedScenario: Scenario? = nil
    @Environment(\.dismiss) var dismiss
    
    private enum Scenario {
        case manual
        case sync
    }
    
    private var isSaveDisabled: Bool {
        name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    init(store: NewFriendScreenStore) {
        self.store = store
    }
    
    var body: some View {
        ZStack {
            Color(.backgroundFill)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("НОВЫЙ ДРУГ")
                        .font(.mySemiBold(size: 22))
                        .tracking(2)
                        .foregroundColor(.textMulticolor)
                    
                    VStack(spacing: 4) {
                        Divider().frame(height: 3).background(.textMulticolor)
                        Divider().frame(height: 0.5).background(.textMulticolor)
                    }
                    .padding(.top, 4)
                }
                .padding(.bottom, 32)
                
                if selectedScenario == .manual {
                    manualFormView
                }
                
                Spacer()
                
                if selectedScenario == nil {
                    scenarioSelectionView
                } else if selectedScenario == .manual {
                    Button {
                        store.send(.saveNewFriend(name: name, color: selectedColor.toHex()))
                        dismiss()
                    } label: {
                        Text("СОХРАНИТЬ")
                            .font(.mySemiBold(size: 14))
                            .tracking(2)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.myPrimary)
                            .overlay {
                                Rectangle()
                                    .stroke(Color.black.opacity(0.15), lineWidth: 1)
                                    .padding(3)
                            }
                    }
                    .buttonStyle(.plain)
                    .disabled(isSaveDisabled)
                }
            }
            .padding(12)
        }
        .animation(.easeInOut(duration: 0.25), value: selectedScenario)
    }
    
    // MARK: - Scenario Selection
    
    private var scenarioSelectionView: some View {
        VStack(spacing: 16) {
            Button {
                selectedScenario = .manual
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "pencil.line")
                        .font(.system(size: 14, weight: .medium))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("СОЗДАТЬ ПРОФИЛЬ ДРУГА")
                            .font(.mySemiBold(size: 13))
                            .tracking(1.5)
                        
                        Text("Друг сейчас не рядом")
                            .font(.myRegular(size: 12))
                            .opacity(0.6)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .opacity(0.4)
                }
                .foregroundStyle(.textMulticolor)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.textMulticolor.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.textMulticolor.opacity(0.15), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
            
            Button {
                store.send(.startSyncNewFriend)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 14, weight: .medium))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ПОЛУЧИТЬ ПРОФИЛЬ ДРУГА")
                            .font(.mySemiBold(size: 13))
                            .tracking(1.5)
                        
                        Text("Друг рядом — начать синхронизацию")
                            .font(.myRegular(size: 12))
                            .opacity(0.6)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .opacity(0.4)
                }
                .foregroundStyle(.black)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.myPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.black.opacity(0.15), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Manual Form
    
    private var manualFormView: some View {
        VStack(alignment: .leading, spacing: 0) {
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
        }
    }
}

#Preview {
    ScreenBuilder.previewBuilder.getScreen(type: .newFriend)
//    @Previewable @State var selectedColor: Color = .red
    
//    CustomColorPicker(selectedColor: $selectedColor)
}
