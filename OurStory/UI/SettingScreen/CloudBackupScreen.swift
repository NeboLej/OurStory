import SwiftUI
import UniformTypeIdentifiers

struct CloudBackupScreen: View {
    @State private var store: CloudBackupScreenStore

    init(store: CloudBackupScreenStore) {
        self.store = store
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                CloudStatusSection(
                    state: store.state.syncState,
                    lastSuccess: store.state.lastSuccessDate,
                    hasAttempt: store.state.hasAttempt,
                    succeeded: store.state.lastAttemptSucceeded,
                    retry: { store.send(.retrySync) }
                )
                BackupListSection(
                    state: store.state,
                    create: { store.send(.createBackup) },
                    importBackup: { store.send(.showImporter) },
                    toggle: { store.send(.toggleBackup($0)) },
                    restore: { store.send(.restore($0)) }
                )
            }
            .padding(20)
        }
        .background(Color(.backgroundFill).ignoresSafeArea())
        .navigationTitle(L10n.cloudAndBackups)
        .navigationBarTitleDisplayMode(.large)
        .onAppear { store.send(.load, animation: nil) }
        .fileImporter(isPresented: Binding(
            get: { store.state.showImporter },
            set: { if !$0 { store.send(.dismissImporter) } }
        ), allowedContentTypes: [.ourStoryBackup]) { result in
            switch result {
            case .success(let url): store.send(.importFile(url))
            case .failure(let error): store.send(.importFailed(error.localizedDescription))
            }
        }
        .alert(L10n.backupImportSuccessTitle, isPresented: Binding(
            get: { store.state.importSucceeded },
            set: { if !$0 { store.send(.dismissImportSuccess) } }
        )) {
            Button("OK") { store.send(.dismissImportSuccess) }
        } message: {
            Text(L10n.backupImportSuccessMessage)
        }
        .alert(L10n.backupError, isPresented: Binding(
            get: { store.state.errorMessage != nil },
            set: { if !$0 { store.send(.dismissError) } }
        )) {
            Button("OK") { store.send(.dismissError) }
        } message: {
            Text(store.state.errorMessage ?? "")
        }
        .alert(L10n.restoreConflicts, isPresented: Binding(
            get: { store.state.hasRestoreConflict },
            set: { if !$0 { store.send(.cancelRestore) } }
        )) {
            Button(L10n.restoreReplace) { store.send(.resolveConflict(.replace)) }
            Button(L10n.restoreSkip) { store.send(.resolveConflict(.skip)) }
            Button(L10n.cancel, role: .cancel) { store.send(.cancelRestore) }
        } message: {
            Text(L10n.restoreConflictDescription)
        }
        .alert(L10n.restoreComplete, isPresented: Binding(
            get: { store.state.restoreSucceeded },
            set: { if !$0 { store.send(.dismissRestoreSuccess) } }
        )) {
            Button("OK") { store.send(.dismissRestoreSuccess) }
        }
    }
}

private struct BackupButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.mySemiBold(size: 12))
            .tracking(1.5)
            .foregroundStyle(Color.textMulticolor.opacity(0.85))
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .overlay {
                Rectangle()
                    .stroke(Color.textMulticolor.opacity(0.35), lineWidth: 1)
            }
            .opacity(isEnabled ? (configuration.isPressed ? 0.6 : 1) : 0.4)
    }
}

private struct CloudStatusSection: View {
    let state: CloudSyncState
    let lastSuccess: Date?
    let hasAttempt: Bool
    let succeeded: Bool
    let retry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("iCloud").font(.mySemiBold(size: 20))
            HStack {
                Image(systemName: statusIcon)
                Text(status)
                Spacer()
            }
            .font(.myMedium(size: 15))
            if let lastSuccess {
                Text(L10n.backupLastSync)
                    .font(.myRegular(size: 13))
                    .foregroundStyle(.textMulticolor.opacity(0.6))
                Text(lastSuccess, format: .dateTime.day().month().year().hour().minute())
                    .font(.myMedium(size: 15))
            } else {
                Text(L10n.backupNoSync)
                    .font(.myRegular(size: 14))
                    .foregroundStyle(.textMulticolor.opacity(0.6))
            }
            Button(L10n.backupRetrySync, action: retry)
                .buttonStyle(BackupButtonStyle())
                .disabled(state == .uploading || state == .downloading)
        }
        .foregroundStyle(.textMulticolor)
    }

    private var status: String {
        switch state {
        case .uploading, .downloading: L10n.backupSyncing
        case .error: L10n.backupSyncFailed
        case .completed: L10n.backupSyncSucceeded
        case .idle:
            hasAttempt ? (succeeded ? L10n.backupSyncSucceeded : L10n.backupSyncFailed) : L10n.backupNoStatus
        }
    }

    private var statusIcon: String {
        switch state {
        case .uploading, .downloading: "arrow.triangle.2.circlepath"
        case .error: "exclamationmark.icloud"
        case .completed: "checkmark.icloud"
        case .idle: hasAttempt ? (succeeded ? "checkmark.icloud" : "exclamationmark.icloud") : "icloud"
        }
    }
}

private struct BackupListSection: View {
    let state: CloudBackupScreenState
    let create: () -> Void
    let importBackup: () -> Void
    let toggle: (DatabaseBackup) -> Void
    let restore: (DatabaseBackup) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.backupsTitle)
                .font(.mySemiBold(size: 20))
            Text(L10n.backupDescription)
                .font(.myRegular(size: 13))
                .foregroundStyle(.textMulticolor.opacity(0.6))
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    Button(L10n.backupCreate, action: create)
                    Button(L10n.backupImport, action: importBackup)
                }
                VStack(alignment: .leading, spacing: 12) {
                    Button(L10n.backupCreate, action: create)
                    Button(L10n.backupImport, action: importBackup)
                }
            }
            .buttonStyle(BackupButtonStyle())
            .disabled(state.isCreating || state.isImporting || state.isRestoring)
            if state.backups.isEmpty {
                Text(L10n.backupEmpty)
                    .font(.myRegular(size: 14))
                    .foregroundStyle(.textMulticolor.opacity(0.6))
            }
            ForEach(state.backups) { backup in
                VStack(alignment: .leading, spacing: 12) {
                    Button {
                        toggle(backup)
                    } label: {
                        HStack {
                            Image(systemName: "externaldrive")
                            Text(backup.date, format: .dateTime.day().month().year().hour().minute())
                            Spacer()
                            Image(systemName: state.expandedBackupID == backup.id ? "chevron.up" : "chevron.down")
                        }
                        .font(.myMedium(size: 15))
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if state.expandedBackupID == backup.id {
                        if state.isLoadingDetails {
                            ProgressView()
                        } else if let details = state.details {
                            VStack(spacing: 8) {
                                HStack {
                                    Text(L10n.backupStories)
                                    Spacer()
                                    Text(details.noteCount.formatted())
                                }
                                HStack {
                                    Text(L10n.backupFriends)
                                    Spacer()
                                    Text(details.friendCount.formatted())
                                }
                            }
                            .font(.myRegular(size: 13))
                            .foregroundStyle(.textMulticolor.opacity(0.7))
                            .padding(.bottom, 4)

                            HStack(spacing: 12) {
                                ShareLink(item: backup.url) {
                                    Text(L10n.backupDownload)
                                }
                                .buttonStyle(BackupButtonStyle())

                                Button(L10n.backupRestore) {
                                    restore(backup)
                                }
                                .buttonStyle(BackupButtonStyle())
                                .disabled(state.isRestoring)
                            }
                            .padding(.bottom, 12)
                        }
                    }
                    Rectangle().frame(height: 0.5).foregroundStyle(.textMulticolor.opacity(0.2))
                }
            }
        }
        .foregroundStyle(.textMulticolor)
    }
}
