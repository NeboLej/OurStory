import Foundation

enum CloudBackupScreenAction {
    case load
    case retrySync
    case createBackup
    case showImporter
    case dismissImporter
    case importFile(URL)
    case importFailed(String)
    case dismissImportSuccess
    case toggleBackup(DatabaseBackup)
    case restore(DatabaseBackup)
    case resolveConflict(BackupConflictPolicy)
    case cancelRestore
    case dismissRestoreSuccess
    case dismissError
}
