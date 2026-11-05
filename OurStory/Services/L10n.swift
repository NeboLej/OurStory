//
//  L10n.swift
//  OurStory
//

import Foundation

enum L10n {
    
    static var language: AppLanguage = {
        let saved = UserDefaults.standard.string(forKey: "appLanguage") ?? AppLanguage.russian.rawValue
        return AppLanguage(rawValue: saved) ?? .russian
    }()
    
    private static func loc(_ translations: [AppLanguage: String]) -> String {
        translations[language] ?? translations[.russian] ?? ""
    }
    
    // MARK: - Common
    
    static var save: String { loc([.russian: "СОХРАНИТЬ", .english: "SAVE"]) }
    static var cancel: String { loc([.russian: "ОТМЕНА", .english: "CANCEL"]) }
    static var edit: String { loc([.russian: "ИЗМЕНИТЬ", .english: "EDIT"]) }
    static var delete: String { loc([.russian: "Удалить", .english: "Delete"]) }
    static var close: String { loc([.russian: "ЗАКРЫТЬ", .english: "CLOSE"]) }
    static var continueAction: String { loc([.russian: "ПРОДОЛЖИТЬ", .english: "CONTINUE"]) }
    
    // MARK: - Names / Labels
    
    static var nameLabel: String { loc([.russian: "ИМЯ", .english: "NAME"]) }
    static var usernameLabel: String { loc([.russian: "ИМЯ ПОЛЬЗОВАТЕЛЯ", .english: "USERNAME"]) }
    static var enterNamePlaceholder: String { loc([.russian: "Введите ваше имя...", .english: "Enter your name..."]) }
    static var enterNameShortPlaceholder: String { loc([.russian: "Введите имя...", .english: "Enter name..."]) }
    static var colorLabel: String { loc([.russian: "ЦВЕТОВАЯ МЕТКА", .english: "COLOR TAG"]) }
    static var otherColor: String { loc([.russian: "Другой цвет", .english: "Other color"]) }
    
    // MARK: - Settings Screen
    
    static var settings: String { loc([.russian: "Настройки", .english: "Settings"]) }
    static var languageLabel: String { loc([.russian: "Язык", .english: "Language"]) }
    static var notifications: String { loc([.russian: "Уведомления", .english: "Notifications"]) }
    static var icloudSync: String { loc([.russian: "Синхронизация iCloud", .english: "iCloud Sync"]) }
    static var help: String { loc([.russian: "Помощь", .english: "Help"]) }
    static var logs: String { loc([.russian: "Логи", .english: "Logs"]) }
    static var theme: String { loc([.russian: "Тема", .english: "Theme"]) }
    static var editProfileTitle: String { loc([.russian: "РЕДАКТИРОВАТЬ\nПРОФИЛЬ", .english: "EDIT\nPROFILE"]) }
    
    // MARK: - Theme
    
    static var themeDark: String { loc([.russian: "Тёмная", .english: "Dark"]) }
    static var themeLight: String { loc([.russian: "Светлая", .english: "Light"]) }
    static var themeSystem: String { loc([.russian: "Системная", .english: "System"]) }
    
    // MARK: - Toolbar
    
    static var friends: String { loc([.russian: "Друзья", .english: "Friends"]) }
    static var calendar: String { loc([.russian: "Календарь", .english: "Calendar"]) }
    static var search: String { loc([.russian: "Поиск", .english: "Search"]) }
    
    // MARK: - Notes
    
    static var newStory: String { loc([.russian: "НОВАЯ ИСТОРИЯ", .english: "NEW STORY"]) }
    static var editStory: String { loc([.russian: "ИСПРАВИТЬ ИСТОРИЮ", .english: "EDIT STORY"]) }
    static var storyTitlePlaceholder: String { loc([.russian: "Название истории", .english: "Story title"]) }
    static var textLabel: String { loc([.russian: "ТЕКСТ", .english: "TEXT"]) }
    static func charCount(_ count: Int) -> String { loc([.russian: "\(count) знаков", .english: "\(count) chars"]) }
    static var storyPlaceholder: String { loc([.russian: "Начните писать свою историю...", .english: "Start writing your story..."]) }
    static var draftRestoredClear: String { loc([.russian: "Восстановлен черновик. Очистить?", .english: "Draft restored. Clear?"]) }
    static func tagFriend(_ name: String) -> String { loc([.russian: "Отметить \(name)?", .english: "Tag \(name)?"]) }
    static var stories: String { loc([.russian: "Истории", .english: "Stories"]) }
    static var editAction: String { loc([.russian: "Редактировать", .english: "Edit"]) }
    static var tagFriendAction: String { loc([.russian: "Отметить друга", .english: "Tag friend"]) }
    static var deleteAction: String { loc([.russian: "Удалить", .english: "Delete"]) }
    
    // MARK: - Search
    
    static var searchStories: String { loc([.russian: "Поиск историй", .english: "Search stories"]) }
    
    // MARK: - Friends
    
    static var friendsTitle: String { loc([.russian: "ДРУЗЬЯ", .english: "FRIENDS"]) }
    static func friendsCount(_ selected: Int, _ total: Int) -> String { loc([.russian: "\(selected) из \(total)", .english: "\(selected) of \(total)"]) }
    static var noFriendsYet: String { loc([.russian: "Вы пока не добавили друзей", .english: "You haven't added any friends yet"]) }
    static var newFriend: String { loc([.russian: "НОВЫЙ ДРУГ", .english: "NEW FRIEND"]) }
    static var addFriend: String { loc([.russian: "ДОБАВИТЬ ДРУГА", .english: "ADD FRIEND"]) }
    static var addFriendShort: String { loc([.russian: "Добавь друга", .english: "Add a friend"]) }
    static var addFriendHint1: String { loc([.russian: "Упоминай его в своих историях, даже если он ещё не установил приложение", .english: "Tag them in your stories, even if they haven't installed the app yet"]) }
    static var addFriendHint2: String { loc([.russian: "Вы сможете обменяться воспоминаниями позже, когда будете рядом", .english: "You can exchange memories later when you're nearby"]) }
    
    // MARK: - Friend Screen
    
    static var deleteFriendAlertTitle: String { loc([.russian: "Вы хотите удалить друга и все полученные от него истории?", .english: "Do you want to delete this friend and all received stories?"]) }
    static var deleteFriendAndStories: String { loc([.russian: "Удалить друга и все истории", .english: "Delete friend and all stories"]) }
    static var deleteFriendOnly: String { loc([.russian: "Удалить друга", .english: "Delete friend"]) }
    static func searchingFriend(_ name: String) -> String { loc([.russian: "ищу \(name)...", .english: "searching for \(name)..."]) }
    static func friendNearby(_ name: String) -> String { loc([.russian: "\(name) рядом", .english: "\(name) nearby"]) }
    static var wantsToExchange: String { loc([.russian: "и хочет обменяться историями", .english: "and wants to exchange stories"]) }
    static var notFound: String { loc([.russian: "не удалось найти", .english: "not found"]) }
    static func findFriend(_ name: String) -> String { loc([.russian: "НАЙТИ \(name)", .english: "FIND \(name)"]) }
    static var sharedStories: String { loc([.russian: "Общих историй", .english: "Shared stories"]) }
    static var untoldStories: String { loc([.russian: "Историй не рассказано", .english: "Unsent stories"]) }
    static var lastSync: String { loc([.russian: "Последняя синхронизация", .english: "Last sync"]) }
    static var tellStories: String { loc([.russian: "РАССКАЗАТЬ ИСТОРИИ", .english: "SHARE STORIES"]) }
    static func friendIsWaiting(_ name: String) -> String { loc([.russian: "\(name) ждёт", .english: "\(name) is waiting"]) }
    static var startExchange: String { loc([.russian: "начать обмен историями", .english: "start story exchange"]) }
    static var deleteFriend: String { loc([.russian: "УДАЛИТЬ ДРУГА", .english: "DELETE FRIEND"]) }
    static var suggestion: String { loc([.russian: "ПРЕДЛОЖЕНИЕ", .english: "SUGGESTION"]) }
    static var friendProfileDiffHint: String { loc([.russian: "Ваш друг указал другое имя и цвет для своего профиля", .english: "Your friend set a different name and color for their profile"]) }
    static var apply: String { loc([.russian: "ПРИМЕНИТЬ", .english: "APPLY"]) }
    static var binding: String { loc([.russian: "ПРИВЯЗКА", .english: "LINKED"]) }
    static func friendLinkedTo(_ friendName: String, _ userName: String) -> String { loc([.russian: "\(friendName) привязан к аккаунту \(userName)", .english: "\(friendName) is linked to \(userName)'s account"]) }
    static var unlink: String { loc([.russian: "ОТВЯЗАТЬ", .english: "UNLINK"]) }
    static func ourStoriesWith(_ name: String) -> String { loc([.russian: "Наши с \(name) истории", .english: "Our stories with \(name)"]) }
    static var myUntoldStories: String { loc([.russian: "Мои нерасказанные истории", .english: "My unsent stories"]) }
    
    // MARK: - New Friend Screen
    
    static var createFriendProfile: String { loc([.russian: "СОЗДАТЬ ПРОФИЛЬ ДРУГА", .english: "CREATE FRIEND PROFILE"]) }
    static var friendNotNearby: String { loc([.russian: "Друг сейчас не рядом", .english: "Friend is not nearby"]) }
    static var getFriendProfile: String { loc([.russian: "ПОЛУЧИТЬ ПРОФИЛЬ ДРУГА", .english: "GET FRIEND PROFILE"]) }
    static var friendNearbyStartSync: String { loc([.russian: "Друг рядом — начать синхронизацию", .english: "Friend is nearby — start sync"]) }
    
    // MARK: - Calendar
    
    static func daysAndStories(_ days: Int, _ notes: Int) -> String { loc([.russian: "\(days) дня · \(notes) истории", .english: "\(days) days · \(notes) stories"]) }
    static func entriesCount(_ count: Int) -> String {
        switch language {
        case .russian: return "\(count) \(count == 1 ? "запись" : "записей")"
        case .english: return "\(count) \(count == 1 ? "entry" : "entries")"
        }
    }
    
    // MARK: - Sync
    
    static var syncSearching: String { loc([.russian: "Ищу других пользователей рядом...", .english: "Searching for nearby users..."]) }
    static var syncConnecting: String { loc([.russian: "Соединяю пользователей...", .english: "Connecting users..."]) }
    static var syncExchangingInfo: String { loc([.russian: "Обмениваю информацию...", .english: "Exchanging information..."]) }
    static var syncFriendNearby: String { loc([.russian: "Друг рядом и готов слушать", .english: "Friend is nearby and ready"]) }
    static var syncWaitingApproval: String { loc([.russian: "Получение разрешения на обмен историями...", .english: "Waiting for story exchange approval..."]) }
    static var syncTellingStories: String { loc([.russian: "Рассказываю истории...", .english: "Sharing stories..."]) }
    static var syncCompleted: String { loc([.russian: "Обмен историями завершен!", .english: "Story exchange completed!"]) }
    static func syncError(_ description: String) -> String { loc([.russian: "Ошибка обмена: \(description)", .english: "Exchange error: \(description)"]) }
    
    static var syncErrorNotConnected: String { loc([.russian: "Нет подключения к пользователю.", .english: "Not connected to user."]) }
    static var syncErrorUserRejected: String { loc([.russian: "Пользователь отклонил обмен.", .english: "User rejected the exchange."]) }
    static var syncErrorCancelled: String { loc([.russian: "Обмен отменен.", .english: "Exchange cancelled."]) }
    static var syncErrorDisconnected: String { loc([.russian: "Соединение с пользователем потеряно.", .english: "Connection to user lost."]) }
    
    // MARK: - Sync Progress Screen
    
    static func syncSearchingName(_ name: String) -> String { loc([.russian: "ищу \(name)...", .english: "searching for \(name)..."]) }
    static var syncTelling: String { loc([.russian: "рассказываю истории", .english: "sharing stories"]) }
    static var syncStoriesMet: String { loc([.russian: "истории встретились", .english: "stories have met"]) }
    static var syncGreatSharing: String { loc([.russian: "здорово, что поделились", .english: "great that you shared"]) }
    static var syncFailed: String { loc([.russian: "не получилось", .english: "something went wrong"]) }
    static var syncWaitingConfirmation: String { loc([.russian: "ожидаю подтверждения", .english: "waiting for confirmation"]) }
    static func syncExchangeWith(_ name: String) -> String { loc([.russian: "обменяться историями с \(name)?", .english: "exchange stories with \(name)?"]) }
    static var syncCancel: String { loc([.russian: "ОТМЕНИТЬ", .english: "CANCEL"]) }
    static var syncExchange: String { loc([.russian: "ОБМЕНЯТЬСЯ", .english: "EXCHANGE"]) }
    static func syncReceivedStories(_ count: Int) -> String { loc([.russian: "получено историй: \(count)", .english: "received stories: \(count)"]) }
    static var syncViewStories: String { loc([.russian: "ПОСМОТРЕТЬ ИСТОРИИ", .english: "VIEW STORIES"]) }
    static func storiesFrom(_ name: String) -> String { loc([.russian: "Истории от \(name)", .english: "Stories from \(name)"]) }
    
    // MARK: - Welcome
    
    static var welcomeTitle: String { loc([.russian: "Ура! Теперь ты с нами! 🎉", .english: "Welcome aboard! 🎉"]) }
    static func welcomeText(_ name: String) -> String {
        switch language {
        case .russian:
            return "\(name), это твоё пространство для историй. Сохраняй яркие моменты, отмечай друзей и делись воспоминаниями при встрече.\n\nЗнакомо чувство, когда листаешь галерею на телефоне и вдруг натыкаешься на фото, которое возвращает тебя в давно забытый момент? Воспоминания, которые, казалось бы, затерялись где-то в глубинах памяти, снова оживают!\n\nЭто приложение создано именно для этого. Cохраняй больше счастливых моментов, собирай их в истории и возвращайся к ним вместе с друзьями."
        case .english:
            return "\(name), this is your space for stories. Save bright moments, tag friends, and share memories when you meet.\n\nYou know that feeling when you're scrolling through your phone gallery and suddenly stumble upon a photo that takes you back to a long-forgotten moment? Memories that seemed lost somewhere deep in your mind suddenly come alive!\n\nThis app was made exactly for that. Save more happy moments, collect them as stories, and revisit them together with friends."
        }
    }
    
    // MARK: - TextFactory
    
    static var currentDayTexts: [String] {
        switch language {
        case .russian:
            return ["Как прошёл твой день?", "Ну что, как оно было?", "У этого дня есть своя история",
                    "Что хочется запомнить сегодня?", "Давай сохраним этот день", "Пара слов это уже история",
                    "Уже вижу как ты вспомнишь об этой истории через пару лет", "Запиши, пока свежо в памяти"]
        case .english:
            return ["How was your day?", "So, how did it go?", "This day has its own story",
                    "What do you want to remember today?", "Let's save this day", "A few words is already a story",
                    "I can already see you remembering this story in a couple of years", "Write it down while it's fresh"]
        }
    }
    
    static var oldDayTexts: [String] {
        switch language {
        case .russian:
            return ["Помнишь этот день?", "Кажется, здесь есть что вспомнить", "Что осталось в памяти?",
                    "У этого дня ещё есть шанс попасть в историю", "О, а что было в этот день?", "Время вспомнить кое-что хорошее",
                    "Никогда не поздно записать что-то важное", "Что-то интересное наверняка было", "Попробуй вернуться в тот день"]
        case .english:
            return ["Remember this day?", "Seems like there's something to recall", "What stayed in your memory?",
                    "This day still has a chance to become a story", "Oh, what happened on this day?", "Time to remember something good",
                    "It's never too late to write down something important", "Something interesting must have happened", "Try to go back to that day"]
        }
    }
    
    static var futureDayTexts: [String] {
        switch language {
        case .russian:
            return ["Есть планы на этот день?", "Каким будет этот день?", "Запланируешь что-нибудь хорошее?", "История ещё впереди ✨",
                    "Пусть у будущего будет маленькая подсказка."]
        case .english:
            return ["Any plans for this day?", "What will this day be like?", "Planning something nice?", "The story is yet to come ✨",
                    "Let the future have a little hint."]
        }
    }
    
    // MARK: - Help
    
    static var helpExchangeTitle: String { loc([.russian: "Обмен историями", .english: "Story Exchange"]) }
    static var helpAddFriendTitle: String { loc([.russian: "Добавление друга", .english: "Adding a Friend"]) }
    
    static var helpExchangeBlock1: String {
        loc([.russian: """
            **Встретьтесь с другом**
            Чтобы рассказать истории нужно *физически* быть рядом с вашим другом.
            
            Не переживайте, что не смогли передать историю сразу как только написали ее. Истории любят когда их вспоминают немного позже
            """,
             .english: """
            **Meet your friend**
            To share stories you need to *physically* be near your friend.
            
            Don't worry if you couldn't share a story right after writing it. Stories love being remembered a bit later
            """])
    }
    
    static var helpExchangeNote1: String {
        loc([.russian: "Не обязательно приближать телефоны друг к другу вплутную, достаточно быть в радиусе 10-15 метров",
             .english: "You don't need to bring phones close together, being within 10-15 meters is enough"])
    }
    
    static var helpExchangeWarning1: String {
        loc([.russian: "Если приблизить телефоны в упор - сработает *Apple AirDrop* и вы обменяетесь своими контактами, это не то, что там нужно",
             .english: "If you bring phones too close — *Apple AirDrop* will activate and you'll exchange contacts, that's not what we need"])
    }
    
    static var helpExchangeBlock2: String {
        loc([.russian: """
            Нажмите кнопки передачи данных **одновременно**
            """,
             .english: """
            Press the data transfer buttons **simultaneously**
            """])
    }
    
    static var helpExchangeNote2: String {
        loc([.russian: "Не обязательно нажимать прямо в одну секунду, достаточно это сделать с разницей до 8-10 секунд",
             .english: "You don't need to press at the exact same second, a gap of 8-10 seconds is fine"])
    }
    
    static var helpExchangeBlock3: String {
        loc([.russian: """
            **Дождитесь обмена историями**
            """,
             .english: """
            **Wait for the story exchange**
            """])
    }
    
    static var helpExchangeNote3: String {
        loc([.russian: "Если связь оборвалась попробуйте вернуться на экран друга и обменяться историями заново",
             .english: "If the connection was lost, go back to the friend screen and try exchanging stories again"])
    }
    
    static var helpAddBlock1: String {
        loc([.russian: "Чтобы упомянать друга в историх нужно добавить его в список вашех друзей",
             .english: "To tag a friend in stories you need to add them to your friends list"])
    }
    
    static var helpAddNote1: String {
        loc([.russian: "Не переживайте, чтобы начать записывать общие истории друг не обязательно должен быть рядом. И даже не обязательно должен скачивать приложение",
             .english: "Don't worry, to start writing shared stories your friend doesn't need to be nearby. They don't even need to download the app"])
    }
    
    static var helpAddBlock2: String {
        loc([.russian: """
            **Если друга сейчас нет рядом** 
            
             1.  Нажмите кнопку «Добавить друга» и пункт «Создать профиль друга»
             2.  Укажите имя и выберите цвет
             3.  **Отлично!** С этого момента друга можно упомнянать в ваших историях
            
             4.  Когда вы встретитесь просто одновременно нажмите на кнопку «Рассказать истории» в созданном профиле
             5.  Дождитесь окончания обмена данными
            """,
             .english: """
            **If your friend is not nearby** 
            
             1.  Press "Add Friend" and select "Create Friend Profile"
             2.  Enter name and choose a color
             3.  **Great!** From now on you can tag this friend in your stories
            
             4.  When you meet, simultaneously press "Share Stories" in the created profile
             5.  Wait for the data exchange to complete
            """])
    }
    
    static var helpAddNote2: String {
        loc([.russian: "После этого профиль друга, который создали вы, будет связан с профилем, созданным вашим другом",
             .english: "After this, the friend profile you created will be linked to the profile created by your friend"])
    }
    
    static var helpAddBlock3: String {
        loc([.russian: """
            **Если друг сейчас рядом** 
            
             1.  Нажмите кнопку «Добавить друга» и пункт «Получить профиль друга»
             2.  Ваш друг должен нажать тоже «Получить профиль друга» или «Рассказать истории», если он уже создавал ваш профиль ранее 
             3.  Дождитесь синхронизации
             4.  **Отлично!** С этого момента друга можно упомнянать в ваших историях
            
            """,
             .english: """
            **If your friend is nearby** 
            
             1.  Press "Add Friend" and select "Get Friend Profile"
             2.  Your friend should also press "Get Friend Profile" or "Share Stories" if they already created your profile
             3.  Wait for synchronization
             4.  **Great!** From now on you can tag this friend in your stories
            
            """])
    }
    
    static var helpAddWarning: String {
        loc([.russian: "Если во время поиска друга не удалось найти, вы можете вернуться и нажать на кнопку «Получить профиль друга» еще раз",
             .english: "If the friend wasn't found during search, you can go back and press \"Get Friend Profile\" again"])
    }
}
