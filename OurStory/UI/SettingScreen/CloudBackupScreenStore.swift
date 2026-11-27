import SwiftUI

@Observable
final class CloudBackupScreenStore: BaseStore {
    private var backups: [DatabaseBackup] = []
    private var isCreating = false
    private var isImporting = false
    private var showImporter = false
    private var importSucceeded = false
    private var errorMessage: String?
    private var expandedBackupID: URL?
    private var details: BackupDetails?
    private var isLoadingDetails = false
    private var isRestoring = false
    private var pendingRestore: DatabaseBackup?
    private var restoreSucceeded = false

    @ObservationIgnored
    private let backupService = BackupService.shared

    var state: CloudBackupScreenState {
        CloudBackupScreenState(
            syncState: appStore.cloudSyncState,
            lastSuccessDate: appStore.cloudLastSuccessDate,
            hasAttempt: appStore.cloudHasAttempt,
            lastAttemptSucceeded: appStore.cloudLastAttemptSucceeded,
            backups: backups,
            isCreating: isCreating,
            isImporting: isImporting,
            showImporter: showImporter,
            importSucceeded: importSucceeded,
            expandedBackupID: expandedBackupID,
            details: details,
            isLoadingDetails: isLoadingDetails,
            isRestoring: isRestoring,
            hasRestoreConflict: pendingRestore != nil,
            restoreSucceeded: restoreSucceeded,
            errorMessage: errorMessage
        )
    }

    func send(_ action: CloudBackupScreenAction, animation: Animation? = .default) {
        withAnimation(animation) {
            switch action {
            case .load:
                Task { await loadBackups() }
                if let url = appStore.takePendingBackupImport() {
                    send(.importFile(url), animation: nil)
                }
            case .retrySync:
                appStore.syncDownloadAndUpload(force: true)
            case .createBackup:
                guard !isCreating else { return }
                isCreating = true
                Task { await createBackup() }
            case .showImporter:
                guard !isCreating, !isImporting, !isRestoring else { return }
                showImporter = true
            case .dismissImporter:
                showImporter = false
            case .importFile(let url):
                guard !isCreating, !isImporting, !isRestoring else { return }
                showImporter = false
                isImporting = true
                Task { await importBackup(from: url) }
            case .importFailed(let message):
                showImporter = false
                errorMessage = message
            case .dismissImportSuccess:
                importSucceeded = false
            case .toggleBackup(let backup):
                if expandedBackupID == backup.id {
                    expandedBackupID = nil
                    details = nil
                } else {
                    expandedBackupID = backup.id
                    details = nil
                    isLoadingDetails = true
                    Task { await loadDetails(backup) }
                }
            case .restore(let backup):
                guard !isRestoring else { return }
                isRestoring = true
                Task { await restore(backup, policy: nil) }
            case .resolveConflict(let policy):
                guard let backup = pendingRestore, !isRestoring else { return }
                pendingRestore = nil
                isRestoring = true
                Task { await restore(backup, policy: policy) }
            case .cancelRestore:
                pendingRestore = nil
            case .dismissRestoreSuccess:
                restoreSucceeded = false
            case .dismissError:
                errorMessage = nil
            }
        }
    }

    private func loadBackups() async {
        do {
            backups = try await backupService.list()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadDetails(_ backup: DatabaseBackup) async {
        do {
            let loaded = try await backupService.details(for: backup)
            guard expandedBackupID == backup.id else { return }
            details = loaded
            isLoadingDetails = false
        } catch {
            guard expandedBackupID == backup.id else { return }
            isLoadingDetails = false
            errorMessage = error.localizedDescription
        }
    }

    private func restore(_ backup: DatabaseBackup, policy: BackupConflictPolicy?) async {
        defer { isRestoring = false }
        do {
            try await appStore.restoreBackup(backup, policy: policy)
            restoreSucceeded = true
        } catch BackupRestoreError.conflicts {
            pendingRestore = backup
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func importBackup(from url: URL) async {
        defer { isImporting = false }
        do {
            try await backupService.importBackup(from: url)
            backups = try await backupService.list()
            importSucceeded = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func createBackup() async {
        defer { isCreating = false }
        do {
            try await backupService.create()
            await loadBackups()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
