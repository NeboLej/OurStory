//
//  LogScreen.swift
//  OurStory
//
//  Created by Nebo on 02.10.2026.
//

import SwiftUI

struct LogScreen: View {
    
    @State var logs = Logger.allLogs
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                ForEach(logs, id: \.self) {
                    Text($0)
                        .foregroundStyle(.textMulticolor)
                        .padding(.horizontal)
                }
            }
        }.navigationTitle("Логи")
            .frame(maxWidth: .infinity)
            .background(.backgroundFill)
    }
}

#Preview {
    LogScreen()
}

#Preview {
    LogScreen()
}
