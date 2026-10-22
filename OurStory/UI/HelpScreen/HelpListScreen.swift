//
//  HelpListScreen.swift
//  OurStory
//
//  Created by Nebo on 22.10.2026.
//

import SwiftUI

struct HelpListScreen: View {
    var body: some View {
        List {
            Section("") {
                ForEach(HelpType.helps) { help in
                    NavigationLink(value: help.id) {
                        HStack(alignment: .top, spacing: 12) {
                
                            Text("\(help.id)")
                                .font(.mySemiBold(size: 16))
                                .frame(width: 26, height: 26)
                                .background(Color.myPrimary.opacity(0.7), in: Circle())
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(help.title).font(.mySemiBold(size: 16))
                                    .padding(.top, 2)
                                
                                if !help.subtitle.isEmpty {
                                    Text(help.subtitle)
                                        .font(.myMedium(size: 14))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.backgroundFill)
        .navigationTitle("Помощь")
        .navigationDestination(for: Int.self) { id in
            if let help = HelpType.helps.first(where: { $0.id == id }) {
                HelpScreen(help: help)
            }
        }
    }
}

#Preview {
    NavigationStack {
        HelpListScreen()
    }
}
