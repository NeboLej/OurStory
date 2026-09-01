//
//  NewNoteScreen.swift
//  OurStory
//
//  Created by Nebo on 01.09.2026.
//

import SwiftUI

import SwiftUI

struct NewNoteScreen: View {
    @State private var title = ""
    @State private var story = ""
    @FocusState private var focusedField: Field?
    
    enum Field {
        case title
        case story
    }
    
    private var canSave: Bool {
        !story.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    
    @ViewBuilder
    private func header() -> some View {
        HStack {
            Text("НОВАЯ ИСТОРИЯ")
                .font(.mySemiBold(size: 14))
                .tracking(2)
                .foregroundStyle(.titleDark)
            
            Spacer()
            
            Button {
                saveStory()
            } label: {
                Text("СОХРАНИТЬ")
                    .font(.mySemiBold(size: 11))
                    .tracking(1.5)
                    .foregroundStyle(canSave ? Color.titleDark.opacity(0.85) : Color.titleDark.opacity(0.25))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .overlay {
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(canSave ? Color.titleDark.opacity(0.35) : Color.titleDark.opacity(0.12), lineWidth: 1)
                    }
            }
            .disabled(!canSave)
        }
        .padding(.top, 18)
        .padding(.bottom, 20)
    }
    
    @ViewBuilder
    private func titleTextField() -> some View {
        HStack {
            TextField("", text: $title,
                      prompt: Text("Название итории")
                .font(.myRegular(size: 17))
                .foregroundStyle(.titleDark.opacity(0.32)), axis: .vertical)
            .lineLimit(1...4)
            .foregroundStyle(.titleDark.opacity(0.88))
            .focused($focusedField, equals: .title)
            .font(.myMedium(size: 20))
            .submitLabel(.next)
            .onSubmit {
                focusedField = .story
            }
            .padding(.top, 28)
            .padding(.bottom, 18)
            
            if title.isEmpty {
                Image(systemName: "pencil.and.scribble")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.titleDark.opacity(0.32))
                    .padding(.top, 8)
            }
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private func storyTextEditor() -> some View {
        HStack {
            Text("ТЕКСТ")
                .font(.mySemiBold(size: 11))
                .tracking(2)
                .foregroundStyle(.titleDark)
            
            Spacer()
            
            if !story.isEmpty {
                Text("\(story.count) знаков")
                    .font(.myRegular(size: 14))
                    .foregroundStyle(.titleDark)
            }
        }
        .padding(.top, 18)
        .padding(.bottom, 8)
        
        TextEditor(text: $story)
            .font(.myMedium(size: 16))
            .scrollContentBackground(.hidden)
            .foregroundStyle(.titleDark.opacity(0.7))
            .focused($focusedField, equals: .story)
            .overlay(alignment: .topLeading) {
                if story.isEmpty {
                    Text("Начните писать свою историю...")
                        .font(.myRegular(size: 17))
                        .foregroundStyle(.titleDark.opacity(0.32))
                        .padding(.top, 8)
                        .padding(.leading, 5)
                        .allowsHitTesting(false)
                }
            }
            .padding(.leading, -5)
    }
    
    var body: some View {
        ZStack {
            Color(Color.backgroundFill)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                header()
                
                Divider()
                    .overlay(Color.titleDark.opacity(0.15))
                
                titleTextField()
                storyTextEditor()
                
                Spacer(minLength: 0)
            }.padding(.horizontal, 24)
        }
        //        .toolbar {
        //            ToolbarItemGroup(placement: .keyboard) {
        //                Spacer()
        //
        //                Button {
        //                    focusedField = nil
        //                } label: {
        //                    Text("Готово")
        //                        .font(.system(size: 15, weight: .medium, design: .serif))
        //                }
        //            }
        //        }
        .onAppear {
            focusedField = .story
        }
    }
    
    private func saveStory() {
        guard canSave else { return }
        
        print("Saving story")
        print("Title: \(title)")
        print("Story: \(story)")
        
        focusedField = nil
    }
}

#Preview {
    NewNoteScreen()
}
