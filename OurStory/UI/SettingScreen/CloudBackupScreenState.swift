import Foundation

struct CloudBackupScreenState {
    var syncState: CloudSyncState
    var lastSuccessDate: Date?
    var hasAttempt: Bool
    var lastAttemptSucceeded: Bool
    var backups: [DatabaseBackup]
    var isCreating: Bool
    var isImporting: Bool
    var showImporter: Bool
    var importSucceeded: Bool
    var expandedBackupID: URL?
    var details: BackupDetails?
    var isLoadingDetails: Bool
    var isRestoring: Bool
    var hasRestoreConflict: Bool
    var restoreSucceeded: Bool
    var errorMessage: String?
}
