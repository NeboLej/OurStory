//
//  AppStore.swift
//  OurStory
//
//  Created by Nebo on 30.08.2026.
//

import SwiftUI

@Observable
final class AppStore {
    
    var selectedDate: Date = .now
    var selectedStory: Story?
    var stories: [BaseDate: Story] = [:]
    var allFriends: [Friend] = []
    var user: User
    
    var appCoordinator: AppCoordinator = AppCoordinator()
    
    @ObservationIgnored
    let userRepository: UserRepositoryProtocol
    @ObservationIgnored
    let friendsRepository: FriendRepositoryProtocol
    @ObservationIgnored
    let noteRepository: NoteRepositoryProtocol
    @ObservationIgnored
    let storyRepository: StoryRepositoryProtocol
    @ObservationIgnored
    private let userDefaultsManager: UserDefaultsManager = UserDefaultsManager()
    
    init(repositoryFactory: RepositoryFactoryProtocol) {
        self.userRepository = repositoryFactory.userRepository
        self.friendsRepository = repositoryFactory.friendRepository
        self.noteRepository = repositoryFactory.noteRepository
        self.storyRepository = repositoryFactory.storyRepository
        
        user = userDefaultsManager.getCurrentUser()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.loadData()
        }
    }
    
    func send(_ action: AppAction) {
        switch action {
        case .selectedDate(let date):
            selectedDate = date
            selectedStory = self.stories[BaseDate(date: selectedDate)]
        case .addNewNote(let newNote):
            addNewNote(newNote)
        case .editNote(let note):
            if let story = stories[BaseDate(date: note.date)] {
                let updatedStory = story.replaceNote(note)
                stories[BaseDate(date: note.date)] = updatedStory
                if story.date == selectedStory?.date {
                    selectedStory = updatedStory
                }
            }
            updateNote(note)
        case .syncNotes(let notes, let friend):
            syncNotes(notes, friend: friend)
        case .addNewFriend(let friend):
            addNewFriend(friend)
        case .editFriend(let friend):
            editFriend(friend)
        case .deleteFriend(let friend):
            deleteFriend(friend)
        case .editProfile(name: let name, color: let color):
            user = userDefaultsManager.editUser(name: name, color: color)
        }
    }
    
    func syncNotes(_ notes: [SyncNote], friend: Friend) {
        let notes = notes.sorted { $0.date < $1.date }
        guard let firstNoteDate = notes.first?.date, let lastNoteDate = notes.last?.date else { return }
        
        Task {
            let syncStories = await storyRepository.getStories(startDate: firstNoteDate.getOffsetDate(-1, component: .day),
                                                               endDate: lastNoteDate.getOffsetDate(1, component: .day))
            
            for note in notes {
                var updatedStory: Story
                
                if let story = syncStories.first(where: { $0.baseDate == note.baseDate }) {
                    updatedStory = story
                } else {
                    updatedStory = Story(date: note.date)
                    await storyRepository.newStory(updatedStory)
                }
                
//                var newStory = syncStories.first(where: { $0.baseDate == note.baseDate }) ?? Story(date: note.date)
                    
                let newNote = Note(id: note.id, rootStoryID: updatedStory.id, title: note.title, date: note.date, text: note.text, friends: [], owner: friend)
                let currentUpdateStory = updatedStory.addNewNote(newNote)
                
                await noteRepository.addNote(newNote)
                stories[updatedStory.baseDate] = currentUpdateStory
                
                if selectedStory?.id == currentUpdateStory.id {
                    selectedStory = currentUpdateStory
                }
            }
        }
    }
    
    func getSelectedStory() -> Story {
        let story = selectedStory ?? stories[BaseDate(date: selectedDate)] ?? Story(date: selectedDate)
        selectedStory = story
        return story
    }

    func send(_ action: NavigateAction) {
        switch action {
        case .toNote(let note):
            appCoordinator.navigate(to: .note(note))
        case .toFriendsList:
            appCoordinator.navigate(to: .friendList)
        case .toFriend(let friend):
            appCoordinator.navigate(to: .friend(friend))
        case .toNewFriend: 
            appCoordinator.navigate(to: .newFriend)
        case .toSettings:
            appCoordinator.navigate(to: .setting)
        }
    }
    
    private func loadData() {
        Task {
            allFriends = await friendsRepository.getAllFriends()
            
            var stories = await storyRepository.getStories(startDate: Date().getOffsetDate(-1, component: .month),
                                                           endDate: Date().getOffsetDate(1, component: .month))
            
            //TMP preview
//            let newStory = await generateStory(on: Date())
//            stories.append(newStory)
            //
            
            stories.forEach { story in
                self.stories[BaseDate(date: story.date)] = story
            }
            
            selectedStory = getSelectedStory()
        }
    }
    
    private func generateStory(on date: Date) async -> Story {
        let texts = testStories.split(separator: "@").map { String($0) }
        let textCount = (0...5).randomElement()!
        var notes: [Note] = []
        

        
        (0..<textCount).forEach { _ in
            let isOwner = Bool.random() && Bool.random()
            var friends: [Friend] = []
            if let friend = allFriends.randomElement() {
                friends.append(friend)
            }
            
            let text = texts.randomElement() ?? ""
            let note = Note(title: text.count % 2 == 0 ? "Некторый заголовк" : nil,
                            date: date,
                            text: texts.randomElement() ?? "",
                            friends: friends,
                            owner: isOwner ? friends.first : nil)
            notes.append(note)
        }
        
        
        return Story(date: date, title: "Example", isUserTitle: true, notes: notes)
    }
}

let testStories = "Мы с Димой и Артёмом решили ночью покататься на велосипедах. В итоге заблудились и случайно нашли очень красивое место с видом на город.@Мы с друзьями устроили дома турнир по настольным играм. Я сначала проигрывал всем подряд, но в последней партии неожиданно выиграл и стал главным чемпионом вечера.@Я решил научиться готовить пасту. Позвал Сашу, и мы вместе устроили эксперимент с соусом — получилось настолько вкусно, что потом приготовили ещё две порции.@На выходных мы с Кириллом пошли в лес просто погулять. Взяли с собой кофе, немного еды и в итоге провели там почти весь день.@Мы с друзьями решили снять короткое смешное видео. На подготовку ушло больше времени, чем на саму съёмку, но результат получился настолько нелепым, что мы потом долго смеялись.@Вечером мы с Максом спонтанно поехали в соседний город. Никаких планов не было, поэтому просто гуляли по улицам и заходили в места, которые нам казались интересными.@Мы с друзьями устроили футбольный матч во дворе. Я забил решающий гол за несколько минут до конца, хотя до этого весь матч почти ничего не получалось.@Я помогал своему другу Артёму переезжать. Мы закончили только поздно вечером, заказали пиццу и ещё часа два сидели среди коробок и разговаривали.@На прошлой неделе мы решили попробовать приготовить домашнюю пиццу. Каждый отвечал за свою часть, а в итоге получилось пять совершенно разных вариантов.@Мы с друзьями пошли в караоке, хотя почти никто из нас не умел петь. В итоге мы так увлеклись, что провели там несколько часов и совершенно потеряли счёт времени.@Я утром решил просто выйти на прогулку без телефона. Встретил по дороге старого знакомого, мы разговорились и случайно провели вместе почти весь день.@Мы с Никитой поспорили, кто быстрее соберёт сложную модель конструктора. Я был уверен в своей победе, но в итоге он закончил первым всего на пару минут раньше меня.@Однажды мы с друзьями устроили вечер старых фильмов. Купили кучу еды, выключили свет и до глубокой ночи пересматривали любимые комедии.@Мы с Сашей решили попробовать себя в настольном теннисе. Сначала вообще не попадали по мячу, но через час уже устроили настоящий мини-турнир.@Вечером мы с друзьями просто сидели во дворе и обсуждали, чем хотели бы заняться в будущем. Разговор оказался настолько интересным, что мы просидели там до поздней ночи.@Я спал весь день@На конференции разработчиков WWDC 2025 Apple представили Foundation Models framework — встроенную в устройства LLM, работающую локально и без доступа к интернету. Модель не увеличивает размер приложения, имеет три миллиона параметров и, по словам Apple, оптимизирована для выполнения специфических задач, таких как обобщение, информирование и классификация, однако не подходит для продвинутых рассуждений. У модели также есть ограничения на контент, описанные на сайте Apple."
