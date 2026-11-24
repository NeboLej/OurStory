//
//  PromoDataSeeder.swift
//  OurStory
//
//  TEMPORARY: seeds demo data for App Store screenshots. Remove after use.
//

#if DEBUG
import Foundation
import GRDB

enum PromoDataSeeder {

    static let launchArgument = "-seedPromoData"

    static let englishArgument = "-promoEnglish"

    private static let isEnglish = ProcessInfo.processInfo.arguments.contains(englishArgument)

    private static let ownerName = isEnglish ? "Ethan" : "Макс"
    private static let ownerColor = "#3563FF"

    private static let anyaUser = User(id: UUID(uuidString: "A0000000-0000-0000-0000-000000000001") ?? UUID(), name: isEnglish ? "Emma" : "Аня", color: "#FF69B4")
    private static let dimaUser = User(id: UUID(uuidString: "A0000000-0000-0000-0000-000000000002") ?? UUID(), name: isEnglish ? "Leo" : "Дима", color: "#FF7A00")
    private static let katyaUser = User(id: UUID(uuidString: "A0000000-0000-0000-0000-000000000003") ?? UUID(), name: isEnglish ? "Chloe" : "Катя", color: "#FFB800")
    private static let papaUser = User(id: UUID(uuidString: "A0000000-0000-0000-0000-000000000004") ?? UUID(), name: isEnglish ? "Dad" : "Папа", color: "#00D084")
    private static let olegUser = User(id: UUID(uuidString: "A0000000-0000-0000-0000-000000000005") ?? UUID(), name: isEnglish ? "Ollie" : "Олежка", color: "#B44AFF")

    private struct Story {
        let daysAgo: Int
        let hour: Int
        let title: String?
        let text: String
        var tagged: [Friend] = []
        var owner: Friend? = nil
        var isSent: Bool = true
    }

    static func seedIfRequested() {
        guard ProcessInfo.processInfo.arguments.contains(launchArgument) else { return }

        let defaults = UserDefaultsManager()
        _ = defaults.restoreUser(id: defaults.getCurrentUser().id, name: ownerName, color: ownerColor)
        defaults.setShowSupportEvent(.welcomeMessage)
        defaults.setShowSupportEvent(.addFriend)
        defaults.setShowSupportEvent(.exchangeStory)
        defaults.isNotificationPromptShown = true
        defaults.clearNoteDraft()
        UserDefaults.standard.set((isEnglish ? AppLanguage.english : AppLanguage.russian).rawValue, forKey: "appLanguage")

        let now = Date()
        let anya = Friend(id: UUID(uuidString: "B0000000-0000-0000-0000-000000000001") ?? UUID(), name: anyaUser.name, color: anyaUser.color, user: anyaUser, lastSyncDate: now.addingTimeInterval(-2 * 86_400))
        let dima = Friend(id: UUID(uuidString: "B0000000-0000-0000-0000-000000000002") ?? UUID(), name: dimaUser.name, color: dimaUser.color, user: dimaUser, lastSyncDate: now.addingTimeInterval(-1 * 86_400))
        let katya = Friend(id: UUID(uuidString: "B0000000-0000-0000-0000-000000000003") ?? UUID(), name: katyaUser.name, color: katyaUser.color, user: katyaUser, lastSyncDate: now.addingTimeInterval(-12 * 86_400))
        let papa = Friend(id: UUID(uuidString: "B0000000-0000-0000-0000-000000000004") ?? UUID(), name: papaUser.name, color: papaUser.color, user: papaUser, lastSyncDate: now.addingTimeInterval(-20 * 86_400))
        let oleg = Friend(id: UUID(uuidString: "B0000000-0000-0000-0000-000000000005") ?? UUID(), name: olegUser.name, color: olegUser.color, user: olegUser, lastSyncDate: now.addingTimeInterval(-9 * 86_400))

        let stories = isEnglish
            ? makeEnglishStories(emma: anya, leo: dima, chloe: katya, dad: papa, ollie: oleg)
            : makeStories(anya: anya, dima: dima, katya: katya, papa: papa, oleg: oleg)

        do {
            try DatabaseManager.shared.dbPool.write { db in
                try db.execute(sql: "DELETE FROM noteFriend")
                try db.execute(sql: "DELETE FROM note")
                try db.execute(sql: "DELETE FROM friend")
                try db.execute(sql: "DELETE FROM user")
                try db.execute(sql: "DELETE FROM deletedRecord")

                for user in [anyaUser, dimaUser, katyaUser, papaUser, olegUser] {
                    var model = UserModelGRDB(from: user)
                    try model.insert(db)
                }
                for friend in [anya, dima, katya, papa, oleg] {
                    var model = FriendModelGRDB(from: friend, userID: friend.user?.id)
                    try model.insert(db)
                }

                for story in stories {
                    let note = Note(
                        title: story.title,
                        date: date(daysAgo: story.daysAgo, hour: story.hour, from: now),
                        text: story.text,
                        friends: story.tagged,
                        owner: story.owner
                    )
                    var model = NoteModelGRDB(from: note)
                    try model.insert(db)
                    for friend in story.tagged {
                        var link = NoteFriend(noteId: note.id, friendId: friend.id, isSent: story.isSent, updatedDate: now)
                        try link.insert(db)
                    }
                }
            }
            Logger.log("Promo data seeded: \(stories.count) stories", location: .GRDB, event: .success)
        } catch {
            Logger.log("Promo data seed failed", location: .GRDB, event: .error(error))
        }
    }

    private static func date(daysAgo: Int, hour: Int, from now: Date) -> Date {
        let calendar = Calendar.current
        let day = calendar.date(byAdding: .day, value: -daysAgo, to: now) ?? now
        return calendar.date(bySettingHour: hour, minute: (daysAgo * 7 + hour * 3) % 60, second: 0, of: day) ?? day
    }

    private static func makeStories(anya: Friend, dima: Friend, katya: Friend, papa: Friend, oleg: Friend) -> [Story] {
        [
            // Today — hero day for the main screen
            Story(daysAgo: 0, hour: 9, title: "Первый снег",
                  text: "Аня разбудила меня в семь утра криком «снег!». Пили кофе на балконе в пледах и смотрели, как двор становится белым. Хочу запомнить этот запах — мороз и корица.",
                  tagged: [anya], isSent: false),
            Story(daysAgo: 0, hour: 14, title: "Снеговик-катастрофа",
                  text: "Макс уверял, что умеет лепить снеговиков. Через час у нас было нечто с морковкой вместо руки. Назвали его Геннадий. Геннадий прекрасен.",
                  owner: dima),
            Story(daysAgo: 0, hour: 19, title: nil,
                  text: "Вечером глинтвейн у Димы, настолки до полуночи. Аня снова всех обыграла в «Каркассон» и делает вид, что случайно.",
                  tagged: [anya, dima], isSent: false),

            // Single-friend days so each color shows up on the calendar
            Story(daysAgo: 14, hour: 20, title: "Кофейня",
                  text: "Макс полчаса выбирал между капучино и рафом, а потом взял чай. Это настолько он, что я записала.",
                  owner: katya),
            Story(daysAgo: 25, hour: 19, title: nil, text: "Катя учила меня кататься на роликах. Колени помнят каждый урок.", tagged: [katya]),
            Story(daysAgo: 32, hour: 21, title: "Наш сериал",
                  text: "Досмотрели с Максом сериал, который начали ещё в универе. Финал так себе, но ждали мы его вместе семь лет.",
                  owner: katya),
            Story(daysAgo: 40, hour: 18, title: nil, text: "Катя подарила мне книгу с запиской на полях. Читаю медленно, чтобы не пропустить ни одной.", tagged: [katya]),
            Story(daysAgo: 17, hour: 12, title: "Гараж с папой",
                  text: "Перебирали с папой старые вещи в гараже. Нашли мой первый велосипед. Папа помнит, как я с него упал, лучше меня.",
                  tagged: [papa]),
            Story(daysAgo: 36, hour: 19, title: "Про сына",
                  text: "Макс приехал помочь с антресолями, а в итоге два часа слушал мои истории про армию. Хороший у меня сын. Терпеливый.",
                  owner: papa),
            Story(daysAgo: 48, hour: 7, title: nil, text: "Рассвет на рыбалке с папой. Не поймали ничего, но молчали так хорошо, как давно не разговаривали.", tagged: [papa]),
            Story(daysAgo: 22, hour: 20, title: nil, text: "Олежка показал фокус с монеткой. Повторил двадцать раз и так и не понял, как он это делает.", tagged: [oleg]),
            Story(daysAgo: 28, hour: 22, title: "Ночной заплыв",
                  text: "Уговорил Макса искупаться в октябре. Он визжал. Я тоже, но об этом никому.",
                  owner: oleg),
            Story(daysAgo: 43, hour: 17, title: nil, text: "Олежка затащил на скалодром. Долез до середины и понял, что спускаться страшнее.", tagged: [oleg]),
            Story(daysAgo: 50, hour: 21, title: nil, text: "Дима и Олежка спорили, кто лучше жарит шашлык. Победил дождь.", tagged: [dima, oleg]),
            // Short fillers for a denser calendar heatmap
            Story(daysAgo: 3, hour: 21, title: nil, text: "Аня научила меня завязывать шарф «по-парижски». Выгляжу как художник без картин.", tagged: [anya]),
            Story(daysAgo: 5, hour: 8, title: nil, text: "Проспал будильник, но успел на встречу. День удался ещё до завтрака.", tagged: []),
            Story(daysAgo: 7, hour: 20, title: nil, text: "Дима прислал голосовое на 7 минут про то, как выбирал чайник. Дослушал. Это дружба.", tagged: [dima]),
            Story(daysAgo: 10, hour: 19, title: "Ужин при свечах", text: "Выключили свет во всём доме — оказалось, не романтика, а авария. Но ужин всё равно вышел отличный.", tagged: [anya]),
            Story(daysAgo: 12, hour: 22, title: nil, text: "Посмотрели с Аней старые видео с нашего отпуска. Ржали до слёз над моим загаром.", tagged: [anya]),
            Story(daysAgo: 15, hour: 18, title: nil, text: "Первый раз сам поменял колесо. Дима руководил по видеосвязи с дивана.", tagged: [dima]),
            Story(daysAgo: 19, hour: 20, title: nil, text: "Катя испекла торт без повода. Лучший повод.", tagged: [katya]),
            Story(daysAgo: 20, hour: 9, title: nil, text: "Дождливое воскресенье, кофе, книга. Ничего не случилось — и это прекрасно.", tagged: []),
            Story(daysAgo: 23, hour: 21, title: nil, text: "Аня заснула на моём плече в метро. Проехал свою станцию, но не пожалел.", tagged: [anya]),
            Story(daysAgo: 26, hour: 19, title: nil, text: "Футбол во дворе с Димой и соседскими пацанами. Пацаны выиграли 7:2.", tagged: [dima]),
            Story(daysAgo: 29, hour: 22, title: nil, text: "Купили с Аней кактус и назвали его Кеша. Кеша колючий, но любимый.", tagged: [anya]),
            Story(daysAgo: 35, hour: 18, title: nil, text: "Нашёл в куртке билет с нашего первого концерта. Положил в этот дневник — ну, почти.", tagged: []),
            Story(daysAgo: 39, hour: 20, title: nil, text: "Дима женится! Узнал первым. Ну, вторым после невесты.", tagged: [dima]),
            Story(daysAgo: 44, hour: 13, title: nil, text: "Ярмарка мёда: попробовали 30 видов, купили один. Аня выбрала, конечно.", tagged: [anya]),
            Story(daysAgo: 47, hour: 21, title: nil, text: "Ночью гроза, сидели на подоконнике и считали секунды до грома.", tagged: [anya]),
            Story(daysAgo: 51, hour: 19, title: nil, text: "Бадминтон с Катей и Аней. Девочки играли против меня. Честно.", tagged: [anya, katya]),
            Story(daysAgo: 55, hour: 20, title: nil, text: "Последний тёплый вечер. Ели мороженое на крыше у Димы.", tagged: [dima]),
            Story(daysAgo: 60, hour: 18, title: nil, text: "Аня подстриглась и спросила, замечаю ли я разницу. Заметил! С третьей попытки.", tagged: [anya]),
            Story(daysAgo: 64, hour: 10, title: nil, text: "Завтрак на веранде у родителей. Папа рассказывал, как познакомился с мамой. Никогда раньше не слышал.", tagged: []),
            Story(daysAgo: 70, hour: 21, title: nil, text: "Караоке. Дима исполнил «Я свободен» на коленях. Бармен аплодировал.", tagged: [dima]),
            Story(daysAgo: 1, hour: 20, title: "Сырники",
                  text: "Впервые пожарил сырники, которые не развалились. Аня съела три и сказала «ну нормально». Это успех.",
                  tagged: [anya]),
            Story(daysAgo: 2, hour: 18, title: "Каток в парке",
                  text: "Открыли каток. Дима упал ровно 11 раз, я считал. На двенадцатый он упал на меня.",
                  tagged: [dima]),
            Story(daysAgo: 4, hour: 22, title: nil,
                  text: "Долго гуляли по набережной без цели. Аня рассказывала про детство на даче, и я понял, что хочу однажды туда съездить вместе.",
                  tagged: [anya]),
            Story(daysAgo: 6, hour: 13, title: "Гаражная распродажа",
                  text: "Купили с Димой проигрыватель за 800 рублей. Он не работает. Но выглядит так, будто работает, и это главное.",
                  tagged: [dima]),
            Story(daysAgo: 8, hour: 21, title: "Наш фильм",
                  text: "Пересматривали «Амели» — тот самый фильм, на который мы пошли на первом свидании. Аня опять плакала в том же месте.",
                  tagged: [anya]),
            Story(daysAgo: 9, hour: 21, title: "Про «Амели»",
                  text: "Макс делает вид, что не плакал. Плакал. Я видела.",
                  owner: anya),
            Story(daysAgo: 11, hour: 10, title: nil,
                  text: "Утренняя пробежка, минус два, а я в шортах. Больше никогда. Наверное.",
                  tagged: []),
            // Calendar hero day: own tagged story, Katya's story, own untagged story
            Story(daysAgo: 13, hour: 19, title: "Повышение!",
                  text: "Меня повысили до тимлида. Первым позвонил Ане, вторым — Диме. Отмечали шавермой, как в студенчестве.",
                  tagged: [anya, dima]),
            Story(daysAgo: 13, hour: 21, title: "Наш тимлид",
                  text: "Макс теперь тимлид, а я помню, как на первой работе он случайно удалил тестовую базу и полдня делал вид, что так и задумано. Горжусь. Напоминать буду всегда.",
                  owner: katya),
            Story(daysAgo: 13, hour: 23, title: nil,
                  text: "Перед сном подумал: год назад я боялся даже предложить идею на созвоне. Хорошо, что записываю такие дни.",
                  tagged: []),
            Story(daysAgo: 16, hour: 17, title: "Квиз",
                  text: "Команда «Три сырника» заняла второе место. Проиграли на вопросе про Байкал, хотя Дима там был. Дважды.",
                  tagged: [anya, dima]),
            Story(daysAgo: 18, hour: 23, title: nil,
                  text: "Не мог уснуть, писал сюда старые воспоминания. Оказывается, я помню куда больше, чем думал.",
                  tagged: []),
            Story(daysAgo: 21, hour: 12, title: "Мамин пирог",
                  text: "Ездили к родителям. Мама впервые научила Аню своему яблочному пирогу. Папа сказал, что у Ани получилось лучше. Мама сделала вид, что не обиделась.",
                  tagged: [anya]),
            Story(daysAgo: 24, hour: 20, title: "Байкал, вспоминаем",
                  text: "Нашли с Максом фотки с Байкала пятилетней давности. Решили, что следующим летом едем снова. Записываю, чтобы он не отвертелся.",
                  owner: dima),
            Story(daysAgo: 27, hour: 15, title: nil,
                  text: "Наконец собрал полку из IKEA. Осталось шесть лишних шурупов. Полка держится. Пока.",
                  tagged: []),
            Story(daysAgo: 30, hour: 18, title: "Хэллоуин",
                  text: "Аня была Уэнсдей, я — вещью (рукой). Дима пришёл в костюме банана и выиграл конкурс костюмов. Несправедливо.",
                  tagged: [anya, dima, katya]),
            Story(daysAgo: 33, hour: 11, title: "Грибы",
                  text: "Ходили за грибами. Аня нашла 14 белых, я — один мухомор и ежа. Ёж был лучшей находкой.",
                  tagged: [anya]),
            Story(daysAgo: 37, hour: 21, title: nil,
                  text: "Дима позвонил в 3 ночи спросить, как зовут актёра из «Интерстеллара». Мэтью Макконахи. Друг на всю жизнь.",
                  tagged: [dima]),
            Story(daysAgo: 41, hour: 16, title: "Поход на Ястребиное",
                  text: "Два дня с палаткой на озере. Звёзды такие, что Аня молчала минут десять — рекорд. Дима забыл газовую горелку, ели тушёнку холодной и смеялись.",
                  tagged: [anya, dima]),
            Story(daysAgo: 42, hour: 9, title: "Утро на озере",
                  text: "Проснулась раньше всех, туман над водой. Мальчики храпят дуэтом. Счастье.",
                  owner: anya),
            Story(daysAgo: 45, hour: 19, title: nil,
                  text: "Первый раз сходил на керамику. Сделал чашку. Аня говорит, это пепельница.",
                  tagged: [anya]),
            Story(daysAgo: 49, hour: 20, title: "Дима и кальмар",
                  text: "Дима решил приготовить кальмара по видео. Кальмар победил. Заказали пиццу.",
                  tagged: [dima]),
            Story(daysAgo: 53, hour: 14, title: "Велопрогулка",
                  text: "35 км вдоль реки. Аня впереди, я сзади с одышкой. Остановились у старой мельницы и ели черешню.",
                  tagged: [anya]),
            Story(daysAgo: 56, hour: 9, title: "Йога с Катей",
                  text: "Катя затащила на утреннюю йогу в парке. Я был единственным, кто не смог дотянуться до пальцев ног. Зато дышал громче всех.",
                  tagged: [katya]),
            Story(daysAgo: 58, hour: 22, title: nil,
                  text: "Дождь всю ночь. Читали вслух по очереди «Маленького принца». Странно, но в 27 он звучит совсем по-другому.",
                  tagged: [anya]),
            Story(daysAgo: 62, hour: 18, title: "Концерт",
                  text: "Сорвали голос на концерте с Димой. Он знал все песни, я — только припевы. Но орал громче я.",
                  tagged: [dima]),
            Story(daysAgo: 66, hour: 12, title: "Питер на выходные",
                  text: "Сорвались в Питер на «Сапсане». Белые ночи уже закончились, но Аня всё равно не давала спать: «Ещё один мост!»",
                  tagged: [anya]),
            Story(daysAgo: 67, hour: 23, title: nil,
                  text: "Ночью на Дворцовой какой-то дедушка играл на саксофоне. Мы танцевали прямо там. Никогда так не делал.",
                  tagged: [anya]),
            Story(daysAgo: 72, hour: 17, title: "Новоселье",
                  text: "Дима переехал. Тащили его диван на пятый этаж без лифта. Он назвал это «отличная тренировка». Я назвал его по-другому.",
                  tagged: [dima]),
            Story(daysAgo: 77, hour: 20, title: nil,
                  text: "Аня впервые осталась на ужин с моими друзьями. Все в неё влюбились. Дима шепнул: «Не упусти».",
                  tagged: [anya, dima]),
            Story(daysAgo: 82, hour: 15, title: "Пикник",
                  text: "Пикник в Коломенском. Ветер унёс плед, Дима бежал за ним полпарка. Лучшая погоня года.",
                  tagged: [anya, dima]),
            Story(daysAgo: 84, hour: 23, title: "Свадьба Оли",
                  text: "Макс поймал букет невесты. Случайно — он просто стоял не там. Аня до сих пор смеётся, а он делает вид, что это была стратегия.",
                  owner: katya),
            Story(daysAgo: 88, hour: 21, title: "Год вместе",
                  text: "Ровно год с Аней. Вспоминали, как познакомились на квизе: она поправила мой ответ, и я обиделся. Хорошо, что ненадолго.",
                  tagged: [anya]),
            Story(daysAgo: 95, hour: 19, title: nil,
                  text: "Лето пахнет асфальтом после дождя и арбузом. Записываю, чтобы зимой вспомнить.",
                  tagged: []),
            Story(daysAgo: 101, hour: 13, title: "Рыбалка",
                  text: "Дима поймал одну рыбу и сорок минут с ней фотографировался. Отпустили. Рыба явно устала от славы.",
                  tagged: [dima]),
            Story(daysAgo: 99, hour: 17, title: nil,
                  text: "Полдня с Катей выбирали Ане подарок на годовщину. Катя забраковала одиннадцать вариантов. Двенадцатый оказался идеальным.",
                  tagged: [katya]),
            Story(daysAgo: 108, hour: 18, title: nil,
                  text: "Аня подарила мне этот дневник со словами «пиши про нас». Пишу.",
                  tagged: [anya]),
        ]
    }
    private static func makeEnglishStories(emma: Friend, leo: Friend, chloe: Friend, dad: Friend, ollie: Friend) -> [Story] {
        [
            // Today — hero day for the main screen
            Story(daysAgo: 0, hour: 9, title: "First snow",
                  text: "Emma woke me up at 7am yelling \"snow!\". We had coffee on the balcony wrapped in blankets and watched the street turn white. I want to remember that smell: frost and cinnamon.",
                  tagged: [emma], isSent: false),
            Story(daysAgo: 0, hour: 14, title: "Snowman disaster",
                  text: "Ethan swore he could build a snowman. An hour later we had something with a carrot for an arm. We named him Gary. Gary is perfect.",
                  owner: leo),
            Story(daysAgo: 0, hour: 19, title: nil,
                  text: "Hot cocoa and board games at Leo's until midnight. Emma crushed everyone at Ticket to Ride again and pretended it was luck.",
                  tagged: [emma, leo], isSent: false),

            // Single-friend days so each color shows up on the calendar
            Story(daysAgo: 14, hour: 20, title: "Coffee order",
                  text: "Ethan spent ten minutes choosing between a latte and a flat white, then ordered tea. That is so him I had to write it down.",
                  owner: chloe),
            Story(daysAgo: 25, hour: 19, title: nil, text: "Chloe tried to teach me rollerblading. My knees remember every lesson.", tagged: [chloe]),
            Story(daysAgo: 32, hour: 21, title: "Our show",
                  text: "Ethan and I finally finished the show we started back in college. The ending was meh, but we waited seven years for it together.",
                  owner: chloe),
            Story(daysAgo: 40, hour: 18, title: nil, text: "Chloe gave me a book with notes in the margins. I'm reading it slowly so I don't miss a single one.", tagged: [chloe]),
            Story(daysAgo: 17, hour: 12, title: "Garage day with Dad",
                  text: "Cleaned out the garage with Dad and found my first bike. He remembers me falling off it better than I do.",
                  tagged: [dad]),
            Story(daysAgo: 36, hour: 19, title: "About my son",
                  text: "Ethan came over to fix a shelf and ended up listening to my old road-trip stories for two hours. Good kid. Patient kid.",
                  owner: dad),
            Story(daysAgo: 48, hour: 7, title: nil, text: "Sunrise fishing with Dad. Caught nothing, but we were quiet together in the best way.", tagged: [dad]),
            Story(daysAgo: 22, hour: 20, title: nil, text: "Ollie showed me a coin trick twenty times. I still have no idea how he does it.", tagged: [ollie]),
            Story(daysAgo: 28, hour: 22, title: "Midnight swim",
                  text: "Talked Ethan into a swim in October. He screamed. So did I, but nobody needs to know.",
                  owner: ollie),
            Story(daysAgo: 43, hour: 17, title: nil, text: "Ollie dragged me to a climbing gym. Made it halfway up and realized going down is the scary part.", tagged: [ollie]),
            Story(daysAgo: 50, hour: 21, title: nil, text: "Leo and Ollie argued about who grills better. The rain won.", tagged: [leo, ollie]),

            // Short fillers for a denser calendar heatmap
            Story(daysAgo: 3, hour: 21, title: nil, text: "Emma taught me the \"Parisian\" scarf knot. I look like an artist with no paintings.", tagged: [emma]),
            Story(daysAgo: 5, hour: 8, title: nil, text: "Slept through my alarm and still made the meeting. Day won before breakfast.", tagged: []),
            Story(daysAgo: 7, hour: 20, title: nil, text: "Leo sent me a 7-minute voice note about choosing a kettle. I listened to all of it. That's friendship.", tagged: [leo]),
            Story(daysAgo: 10, hour: 19, title: "Candlelight dinner", text: "The power went out. Not romance, just a blackout. Dinner was great anyway.", tagged: [emma]),
            Story(daysAgo: 12, hour: 22, title: nil, text: "Watched old vacation videos with Emma. Cried laughing at my sunburn.", tagged: [emma]),
            Story(daysAgo: 15, hour: 18, title: nil, text: "Changed a tire by myself for the first time. Leo supervised over FaceTime from his couch.", tagged: [leo]),
            Story(daysAgo: 19, hour: 20, title: nil, text: "Chloe baked a cake for no reason. Best reason.", tagged: [chloe]),
            Story(daysAgo: 20, hour: 9, title: nil, text: "Rainy Sunday, coffee, a book. Nothing happened, and it was wonderful.", tagged: []),
            Story(daysAgo: 23, hour: 21, title: nil, text: "Emma fell asleep on my shoulder on the train. Missed my stop. No regrets.", tagged: [emma]),
            Story(daysAgo: 26, hour: 19, title: nil, text: "Pickup soccer with Leo and the neighborhood kids. The kids won 7–2.", tagged: [leo]),
            Story(daysAgo: 29, hour: 22, title: nil, text: "Emma and I adopted a cactus and named him Steve. Steve is prickly but loved.", tagged: [emma]),
            Story(daysAgo: 35, hour: 18, title: nil, text: "Found a ticket from our first concert in my jacket. Keeping it forever.", tagged: []),
            Story(daysAgo: 39, hour: 20, title: nil, text: "Leo is getting married! I was the first to know. Well, second, after his fiancée.", tagged: [leo]),
            Story(daysAgo: 44, hour: 13, title: nil, text: "Farmers market: tried thirty kinds of honey, bought one. Emma picked, obviously.", tagged: [emma]),
            Story(daysAgo: 47, hour: 21, title: nil, text: "Thunderstorm at night. We sat by the window counting seconds until the thunder.", tagged: [emma]),
            Story(daysAgo: 51, hour: 19, title: nil, text: "Badminton with Chloe and Emma. It was the two of them against me. Totally fair.", tagged: [emma, chloe]),
            Story(daysAgo: 55, hour: 20, title: nil, text: "Last warm evening of the year. Ice cream on Leo's rooftop.", tagged: [leo]),
            Story(daysAgo: 60, hour: 18, title: nil, text: "Emma got a haircut and asked if I noticed. I did! On the third try.", tagged: [emma]),
            Story(daysAgo: 64, hour: 10, title: nil, text: "Breakfast on the porch at my parents'. Dad told the story of how he met Mom. I'd never heard it.", tagged: []),
            Story(daysAgo: 70, hour: 21, title: nil, text: "Karaoke night. Leo sang \"Bohemian Rhapsody\" on his knees. The bartender gave him a standing ovation.", tagged: [leo]),

            Story(daysAgo: 1, hour: 20, title: "Pancakes",
                  text: "Made pancakes that didn't fall apart for the first time. Emma ate three and said \"not bad\". Huge win.",
                  tagged: [emma]),
            Story(daysAgo: 2, hour: 18, title: "Ice skating",
                  text: "The rink opened. Leo fell exactly 11 times, I counted. On the twelfth he fell on me.",
                  tagged: [leo]),
            Story(daysAgo: 4, hour: 22, title: nil,
                  text: "Long aimless walk by the river. Emma told me about summers at her grandma's farm, and I realized I want to go there with her someday.",
                  tagged: [emma]),
            Story(daysAgo: 6, hour: 13, title: "Yard sale",
                  text: "Leo and I bought a record player for $10. It doesn't work. But it looks like it does, and that's what matters.",
                  tagged: [leo]),
            Story(daysAgo: 8, hour: 21, title: "Our movie",
                  text: "Rewatched \"About Time\", the movie we saw on our first date. Emma cried at the exact same scene again.",
                  tagged: [emma]),
            Story(daysAgo: 9, hour: 21, title: "About that movie",
                  text: "Ethan pretends he didn't cry. He did. I saw.",
                  owner: emma),
            Story(daysAgo: 11, hour: 10, title: nil,
                  text: "Morning run, 28°F, and I wore shorts. Never again. Probably.",
                  tagged: []),
            // Calendar hero day: own tagged story, Chloe's story, own untagged story
            Story(daysAgo: 13, hour: 19, title: "Promotion!",
                  text: "Got promoted to team lead. Called Emma first, Leo second. We celebrated with tacos like we're still in college.",
                  tagged: [emma, leo]),
            Story(daysAgo: 13, hour: 21, title: "Our team lead",
                  text: "Ethan is a team lead now, and I still remember him accidentally wiping the test database at his first job and pretending it was on purpose. So proud. Will remind him forever.",
                  owner: chloe),
            Story(daysAgo: 13, hour: 23, title: nil,
                  text: "Before bed I thought: a year ago I was scared to share an idea in a meeting. Glad I write days like this down.",
                  tagged: []),
            Story(daysAgo: 16, hour: 17, title: "Trivia night",
                  text: "Team \"Three Pancakes\" took second place. We lost on a question about Yellowstone, even though Leo has been there. Twice.",
                  tagged: [emma, leo]),
            Story(daysAgo: 18, hour: 23, title: nil,
                  text: "Couldn't sleep, so I wrote down old memories here. Turns out I remember way more than I thought.",
                  tagged: []),
            Story(daysAgo: 21, hour: 12, title: "Mom's apple pie",
                  text: "Visited my parents. Mom taught Emma her apple pie recipe. Dad said Emma's was better. Mom pretended not to be offended.",
                  tagged: [emma]),
            Story(daysAgo: 24, hour: 20, title: "Remember Yosemite?",
                  text: "Found our Yosemite photos from five years ago with Ethan. We decided we're going back next summer. Writing it here so he can't back out.",
                  owner: leo),
            Story(daysAgo: 27, hour: 15, title: nil,
                  text: "Finally assembled the IKEA shelf. Six screws left over. The shelf is holding. For now.",
                  tagged: []),
            Story(daysAgo: 30, hour: 18, title: "Halloween",
                  text: "Emma went as Wednesday, I was Thing (the hand). Leo showed up as a banana and won the costume contest. Unfair.",
                  tagged: [emma, leo, chloe]),
            Story(daysAgo: 33, hour: 11, title: "Apple picking",
                  text: "Went apple picking. Emma filled two baskets, I found one worm and a hedgehog. The hedgehog was the best find.",
                  tagged: [emma]),
            Story(daysAgo: 37, hour: 21, title: nil,
                  text: "Leo called at 3am to ask the name of the actor from Interstellar. Matthew McConaughey. Friends for life.",
                  tagged: [leo]),
            Story(daysAgo: 41, hour: 16, title: "Camping at the lake",
                  text: "Two days in a tent by the lake. So many stars Emma was quiet for ten whole minutes. A record. Leo forgot the stove, so we ate cold beans and laughed.",
                  tagged: [emma, leo]),
            Story(daysAgo: 42, hour: 9, title: "Morning at the lake",
                  text: "Woke up before everyone. Fog over the water. The boys snoring in harmony. Pure happiness.",
                  owner: emma),
            Story(daysAgo: 45, hour: 19, title: nil,
                  text: "First pottery class. I made a mug. Emma says it's an ashtray.",
                  tagged: [emma]),
            Story(daysAgo: 49, hour: 20, title: "Leo vs. squid",
                  text: "Leo tried to cook squid from a YouTube video. The squid won. We ordered pizza.",
                  tagged: [leo]),
            Story(daysAgo: 53, hour: 14, title: "Bike ride",
                  text: "22 miles along the river. Emma in front, me behind, out of breath. We stopped at an old mill and ate cherries.",
                  tagged: [emma]),
            Story(daysAgo: 56, hour: 9, title: "Yoga with Chloe",
                  text: "Chloe dragged me to morning yoga in the park. I was the only one who couldn't touch my toes. But I breathed the loudest.",
                  tagged: [chloe]),
            Story(daysAgo: 58, hour: 22, title: nil,
                  text: "Rain all night. We took turns reading The Little Prince out loud. Somehow it hits differently at 27.",
                  tagged: [emma]),
            Story(daysAgo: 62, hour: 18, title: "Concert",
                  text: "Lost our voices at a concert with Leo. He knew every song, I only knew the choruses. But I sang louder.",
                  tagged: [leo]),
            Story(daysAgo: 66, hour: 12, title: "Weekend in Chicago",
                  text: "Spontaneous train trip to Chicago. Emma wouldn't let me sleep: \"Just one more bridge!\"",
                  tagged: [emma]),
            Story(daysAgo: 67, hour: 23, title: nil,
                  text: "An old man was playing saxophone by the river at night. We danced right there. I've never done that before.",
                  tagged: [emma]),
            Story(daysAgo: 72, hour: 17, title: "Moving day",
                  text: "Leo moved. We carried his couch up five floors with no elevator. He called it \"a great workout\". I called him something else.",
                  tagged: [leo]),
            Story(daysAgo: 77, hour: 20, title: nil,
                  text: "Emma joined dinner with my friends for the first time. Everyone fell for her. Leo whispered: \"Don't mess this up.\"",
                  tagged: [emma, leo]),
            Story(daysAgo: 82, hour: 15, title: "Picnic",
                  text: "Picnic in the park. The wind stole our blanket and Leo chased it halfway across the lawn. Best chase of the year.",
                  tagged: [emma, leo]),
            Story(daysAgo: 84, hour: 23, title: "Olivia's wedding",
                  text: "Ethan caught the bouquet. By accident, he was just standing in the wrong spot. Emma is still laughing, and he claims it was strategy.",
                  owner: chloe),
            Story(daysAgo: 88, hour: 21, title: "One year together",
                  text: "Exactly one year with Emma. We remembered meeting at trivia night: she corrected my answer and I got offended. Glad it didn't last.",
                  tagged: [emma]),
            Story(daysAgo: 95, hour: 19, title: nil,
                  text: "Summer smells like warm asphalt after rain and watermelon. Writing it down to remember in winter.",
                  tagged: []),
            Story(daysAgo: 101, hour: 13, title: "Fishing trip",
                  text: "Leo caught one fish and took photos with it for forty minutes. We let it go. The fish was clearly tired of fame.",
                  tagged: [leo]),
            Story(daysAgo: 99, hour: 17, title: nil,
                  text: "Spent half a day with Chloe picking an anniversary gift for Emma. Chloe rejected eleven options. The twelfth was perfect.",
                  tagged: [chloe]),
            Story(daysAgo: 108, hour: 18, title: nil,
                  text: "Emma gave me this journal and said: \"Write about us.\" So I do.",
                  tagged: [emma]),
        ]
    }
}
#endif
