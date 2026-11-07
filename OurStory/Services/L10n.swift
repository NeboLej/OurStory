//
//  L10n.swift
//  OurStory
//

import Foundation

enum L10n {
    
    static var language: AppLanguage = {
        let saved = UserDefaults.standard.string(forKey: "appLanguage") ?? AppLanguage.russian.rawValue
        return AppLanguage(rawValue: saved) ?? .russian
    }() {
        didSet { reloadStrings() }
    }
    
    private static var strings: [String: String] = loadStrings(for: language)
    // MARK: - Loading
    
    private static func loadStrings(for lang: AppLanguage) -> [String: String] {
        guard let url = Bundle.main.url(forResource: lang.rawValue, withExtension: "strings"),
              let dict = NSDictionary(contentsOf: url) as? [String: String]
        else { return [:] }
        return dict
    }
    
    private static func reloadStrings() {
        strings = loadStrings(for: language)
    }
    
    // MARK: - Helpers
    
    private static func str(_ key: String) -> String { strings[key] ?? key }
    
    private static func str(_ key: String, _ args: any CVarArg...) -> String {
        String(format: str(key), arguments: args)
    }
    
    private static func arr(_ key: String) -> [String] {
        str(key).components(separatedBy: "|")
    }
    
    private static func plural(_ base: String, count: Int) -> String {
        String(format: str("\(base).\(count == 1 ? "one" : "other")"), count)
    }
    
    // MARK: - Common
    
    static var save: String { str("save") }
    static var cancel: String { str("cancel") }
    static var edit: String { str("edit") }
    static var delete: String { str("delete") }
    static var close: String { str("close") }
    static var continueAction: String { str("continueAction") }
    
    // MARK: - Names / Labels
    
    static var nameLabel: String { str("nameLabel") }
    static var usernameLabel: String { str("usernameLabel") }
    static var enterNamePlaceholder: String { str("enterNamePlaceholder") }
    static var enterNameShortPlaceholder: String { str("enterNameShortPlaceholder") }
    static var colorLabel: String { str("colorLabel") }
    static var otherColor: String { str("otherColor") }
    
    // MARK: - Settings Screen
    
    static var settings: String { str("settings") }
    static var languageLabel: String { str("languageLabel") }
    static var notifications: String { str("notifications") }
    static var icloudSync: String { str("icloudSync") }
    static var help: String { str("help") }
    static var logs: String { str("logs") }
    static var theme: String { str("theme") }
    static var editProfileTitle: String { str("editProfileTitle") }
    
    // MARK: - Theme
    
    static var themeDark: String { str("themeDark") }
    static var themeLight: String { str("themeLight") }
    static var themeSystem: String { str("themeSystem") }
    
    // MARK: - Toolbar
    
    static var friends: String { str("friends") }
    static var calendar: String { str("calendar") }
    static var search: String { str("search") }
    
    // MARK: - Notes
    
    static var newStory: String { str("newStory") }
    static var editStory: String { str("editStory") }
    static var storyTitlePlaceholder: String { str("storyTitlePlaceholder") }
    static var textLabel: String { str("textLabel") }
    static func charCount(_ count: Int) -> String { str("charCount", count) }
    static var storyPlaceholder: String { str("storyPlaceholder") }
    static var draftRestoredClear: String { str("draftRestoredClear") }
    static func tagFriend(_ name: String) -> String { str("tagFriend", name) }
    static var stories: String { str("stories") }
    static var editAction: String { str("editAction") }
    static var tagFriendAction: String { str("tagFriendAction") }
    static var deleteAction: String { str("deleteAction") }
    
    // MARK: - Search
    
    static var searchStories: String { str("searchStories") }
    
    // MARK: - Friends
    
    static var friendsTitle: String { str("friendsTitle") }
    static func friendsCount(_ selected: Int, _ total: Int) -> String { str("friendsCount", selected, total) }
    static var noFriendsYet: String { str("noFriendsYet") }
    static var newFriend: String { str("newFriend") }
    static var addFriend: String { str("addFriend") }
    static var addFriendShort: String { str("addFriendShort") }
    static var addFriendHint1: String { str("addFriendHint1") }
    static var addFriendHint2: String { str("addFriendHint2") }
    
    // MARK: - Friend Screen
    
    static var deleteFriendAlertTitle: String { str("deleteFriendAlertTitle") }
    static var deleteFriendAndStories: String { str("deleteFriendAndStories") }
    static var deleteFriendOnly: String { str("deleteFriendOnly") }
    static func searchingFriend(_ name: String) -> String { str("searchingFriend", name) }
    static func friendNearby(_ name: String) -> String { str("friendNearby", name) }
    static var wantsToExchange: String { str("wantsToExchange") }
    static var notFound: String { str("notFound") }
    static func findFriend(_ name: String) -> String { str("findFriend", name) }
    static var sharedStories: String { str("sharedStories") }
    static var untoldStories: String { str("untoldStories") }
    static var lastSync: String { str("lastSync") }
    static var tellStories: String { str("tellStories") }
    static func friendIsWaiting(_ name: String) -> String { str("friendIsWaiting", name) }
    static var startExchange: String { str("startExchange") }
    static var deleteFriend: String { str("deleteFriend") }
    static var suggestion: String { str("suggestion") }
    static var friendProfileDiffHint: String { str("friendProfileDiffHint") }
    static var apply: String { str("apply") }
    static var binding: String { str("binding") }
    static func friendLinkedTo(_ friendName: String, _ userName: String) -> String { str("friendLinkedTo", friendName, userName) }
    static var unlink: String { str("unlink") }
    static func ourStoriesWith(_ name: String) -> String { str("ourStoriesWith", name) }
    static var myUntoldStories: String { str("myUntoldStories") }
    
    // MARK: - New Friend Screen
    
    static var createFriendProfile: String { str("createFriendProfile") }
    static var friendNotNearby: String { str("friendNotNearby") }
    static var getFriendProfile: String { str("getFriendProfile") }
    static var friendNearbyStartSync: String { str("friendNearbyStartSync") }
    
    // MARK: - Calendar
    
    static func daysAndStories(_ days: Int, _ notes: Int) -> String { str("daysAndStories", days, notes) }
    static func entriesCount(_ count: Int) -> String { plural("entriesCount", count: count) }
    
    // MARK: - Sync
    
    static var syncSearching: String { str("syncSearching") }
    static var syncConnecting: String { str("syncConnecting") }
    static var syncExchangingInfo: String { str("syncExchangingInfo") }
    static var syncFriendNearby: String { str("syncFriendNearby") }
    static var syncWaitingApproval: String { str("syncWaitingApproval") }
    static var syncTellingStories: String { str("syncTellingStories") }
    static var syncCompleted: String { str("syncCompleted") }
    static func syncError(_ description: String) -> String { str("syncError", description) }
    static var syncErrorNotConnected: String { str("syncErrorNotConnected") }
    static var syncErrorUserRejected: String { str("syncErrorUserRejected") }
    static var syncErrorCancelled: String { str("syncErrorCancelled") }
    static var syncErrorDisconnected: String { str("syncErrorDisconnected") }
    
    // MARK: - Sync Progress Screen
    
    static func syncSearchingName(_ name: String) -> String { str("syncSearchingName", name) }
    static var syncTelling: String { str("syncTelling") }
    static var syncStoriesMet: String { str("syncStoriesMet") }
    static var syncGreatSharing: String { str("syncGreatSharing") }
    static var syncFailed: String { str("syncFailed") }
    static var syncWaitingConfirmation: String { str("syncWaitingConfirmation") }
    static func syncExchangeWith(_ name: String) -> String { str("syncExchangeWith", name) }
    static var syncCancel: String { str("syncCancel") }
    static var syncExchange: String { str("syncExchange") }
    static func syncReceivedStories(_ count: Int) -> String { str("syncReceivedStories", count) }
    static var syncViewStories: String { str("syncViewStories") }
    static func storiesFrom(_ name: String) -> String { str("storiesFrom", name) }
    
    // MARK: - Welcome
    
    static var welcomeTitle: String { str("welcomeTitle") }
    static func welcomeText(_ name: String) -> String { str("welcomeText", name) }
    
    // MARK: - TextFactory
    
    static var currentDayTexts: [String] { arr("currentDayTexts") }
    static var oldDayTexts: [String] { arr("oldDayTexts") }
    static var futureDayTexts: [String] { arr("futureDayTexts") }
    
    // MARK: - Help
    
    static var helpExchangeTitle: String { str("helpExchangeTitle") }
    static var helpAddFriendTitle: String { str("helpAddFriendTitle") }
    static var helpExchangeBlock1: String { str("helpExchangeBlock1") }
    static var helpExchangeNote1: String { str("helpExchangeNote1") }
    static var helpExchangeWarning1: String { str("helpExchangeWarning1") }
    static var helpExchangeBlock2: String { str("helpExchangeBlock2") }
    static var helpExchangeNote2: String { str("helpExchangeNote2") }
    static var helpExchangeBlock3: String { str("helpExchangeBlock3") }
    static var helpExchangeNote3: String { str("helpExchangeNote3") }
    static var helpAddBlock1: String { str("helpAddBlock1") }
    static var helpAddNote1: String { str("helpAddNote1") }
    static var helpAddBlock2: String { str("helpAddBlock2") }
    static var helpAddNote2: String { str("helpAddNote2") }
    static var helpAddBlock3: String { str("helpAddBlock3") }
    static var helpAddWarning: String { str("helpAddWarning") }
}
