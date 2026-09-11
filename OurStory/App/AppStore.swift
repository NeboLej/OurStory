//
//  AppStore.swift
//  OurStory
//
//  Created by Nebo on 30.08.2026.
//

import SwiftUI

@Observable
final class AppStore {
    
    var selectionDate: Date = .now
    var currentStory: Story?
    var stories: [BaseDate: Story] = [:]
    var allFriends: [Friend] = []
    
    var appCoordinator: AppCoordinator = AppCoordinator()
    
    init() {
        loadData()
    }
    
    func send(_ action: AppAction) {
        switch action {
        case .selectedDate(let date):
            selectionDate = date
            currentStory = self.stories[BaseDate(date: selectionDate)]
        case .addNewNote(let newNote):
            if let story = stories[BaseDate(date: newNote.date)] {
                let updatedStory = story.addNewNote(newNote)
                stories[BaseDate(date: newNote.date)] = updatedStory
                if story.date == currentStory?.date {
                    currentStory = updatedStory
                }
            } else {
                stories[BaseDate(date: newNote.date)] = Story(date: newNote.date, notes: [newNote])
            }
        case .editNote(let note):
            if let story = stories[BaseDate(date: note.date)] {
                let updatedStory = story.replaceNote(note)
                stories[BaseDate(date: note.date)] = updatedStory
                if story.date == currentStory?.date {
                    currentStory = updatedStory
                }
            }
        }
    }
    
    
    func send(_ action: NavigateAction) {
        switch action {
        case .toNote(let note):
            appCoordinator.navigate(to: .note(note))
        }
    }
    
    
    private func loadData() {
        Task {
            let days = (-5...1).compactMap { Date().getOffsetDate($0, component: .day) }
            
            var stories: [Story] = []
            
            for day in days {
                await stories.append(generateStory(on: day))
            }
            
            stories.forEach { story in
                self.stories[BaseDate(date: story.date)] = story
            }
            
            currentStory = self.stories[BaseDate(date: selectionDate)]
            
            allFriends = Friend.mock
        }
    }
    
    private func generateStory(on date: Date) async -> Story {
        let texts = gg.split(separator: "@").map { String($0) }
        let textCount = (0...5).randomElement()!
        var notes: [Note] = []
        

        
        (0..<textCount).forEach { _ in
            let isOwner = Bool.random() && Bool.random()
            let friends = Friend.getRandomFriends()
            
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

let gg = "Мы с Димой и Артёмом решили ночью покататься на велосипедах. В итоге заблудились и случайно нашли очень красивое место с видом на город.@Мы с друзьями устроили дома турнир по настольным играм. Я сначала проигрывал всем подряд, но в последней партии неожиданно выиграл и стал главным чемпионом вечера.@Я решил научиться готовить пасту. Позвал Сашу, и мы вместе устроили эксперимент с соусом — получилось настолько вкусно, что потом приготовили ещё две порции.@На выходных мы с Кириллом пошли в лес просто погулять. Взяли с собой кофе, немного еды и в итоге провели там почти весь день.@Мы с друзьями решили снять короткое смешное видео. На подготовку ушло больше времени, чем на саму съёмку, но результат получился настолько нелепым, что мы потом долго смеялись.@Вечером мы с Максом спонтанно поехали в соседний город. Никаких планов не было, поэтому просто гуляли по улицам и заходили в места, которые нам казались интересными.@Мы с друзьями устроили футбольный матч во дворе. Я забил решающий гол за несколько минут до конца, хотя до этого весь матч почти ничего не получалось.@Я помогал своему другу Артёму переезжать. Мы закончили только поздно вечером, заказали пиццу и ещё часа два сидели среди коробок и разговаривали.@На прошлой неделе мы решили попробовать приготовить домашнюю пиццу. Каждый отвечал за свою часть, а в итоге получилось пять совершенно разных вариантов.@Мы с друзьями пошли в караоке, хотя почти никто из нас не умел петь. В итоге мы так увлеклись, что провели там несколько часов и совершенно потеряли счёт времени.@Я утром решил просто выйти на прогулку без телефона. Встретил по дороге старого знакомого, мы разговорились и случайно провели вместе почти весь день.@Мы с Никитой поспорили, кто быстрее соберёт сложную модель конструктора. Я был уверен в своей победе, но в итоге он закончил первым всего на пару минут раньше меня.@Однажды мы с друзьями устроили вечер старых фильмов. Купили кучу еды, выключили свет и до глубокой ночи пересматривали любимые комедии.@Мы с Сашей решили попробовать себя в настольном теннисе. Сначала вообще не попадали по мячу, но через час уже устроили настоящий мини-турнир.@Вечером мы с друзьями просто сидели во дворе и обсуждали, чем хотели бы заняться в будущем. Разговор оказался настолько интересным, что мы просидели там до поздней ночи.@Я спал весь день@На конференции разработчиков WWDC 2025 Apple представили Foundation Models framework — встроенную в устройства LLM, работающую локально и без доступа к интернету. Модель не увеличивает размер приложения, имеет три миллиона параметров и, по словам Apple, оптимизирована для выполнения специфических задач, таких как обобщение, информирование и классификация, однако не подходит для продвинутых рассуждений. У модели также есть ограничения на контент, описанные на сайте Apple."
