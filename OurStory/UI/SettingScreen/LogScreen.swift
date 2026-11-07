//
//  LogScreen.swift
//  OurStory
//
//  Created by Nebo on 02.10.2026.
//

import SwiftUI

struct LogScreen: View {
    
    @State var logs = Logger.allLogs
    @State private var shareFileURL: ShareableURL?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                ForEach(logs, id: \.self) {
                    Text($0)
                        .foregroundStyle(.textMulticolor)
                        .padding(.horizontal)
                }
            }
        }
        .navigationTitle(L10n.logs)
        .frame(maxWidth: .infinity)
        .background(.backgroundFill)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    exportLogs()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(item: $shareFileURL) { item in
            ShareSheet(activityItems: [item.url])
                .presentationDetents([.medium, .large])
        }
    }
    
    private func exportLogs() {
        let content = logs.joined(separator: "\n")
        let fileName = "OurStory_logs_\(Date().ISO8601Format()).txt"
            .replacingOccurrences(of: ":", with: "-")
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try content.write(to: tempURL, atomically: true, encoding: .utf8)
            shareFileURL = ShareableURL(url: tempURL)
        } catch {
            Logger.log("Failed to export logs: \(error.localizedDescription)", event: .error(error))
        }
    }
}

private struct ShareableURL: Identifiable {
    let id = UUID()
    let url: URL
}

private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    LogScreen()
}

#Preview {
    LogScreen()
}
