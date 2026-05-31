import SwiftUI
import Combine

// MARK: - GameState (Central State Manager)
@MainActor
final class GameState: ObservableObject {
    // MARK: - Published Properties
    @Published var userLevel: UserLevel = UserLevel()
    @Published var healthCards: [HealthCard] = []
    @Published var habitCards: [HabitCard] = []
    @Published var achievements: [Achievement] = []
    @Published var lastPulledCard: HealthCard?
    @Published var showCardAnimation: Bool = false
    @Published var totalCardsCollected: Int = 0
    @Published var todayHabitsCompleted: Int = 0
    @Published var currentXPAnimation: Int = 0
    
    // MARK: - Private
    private let userDefaults = UserDefaults.standard
    private let xpPerHabit = 25
    private let xpPerCard = 50
    
    // MARK: - Initialization
    init() {
        loadData()
        if healthCards.isEmpty {
            setupDefaultCards()
        }
        if habitCards.isEmpty {
            setupDefaultHabits()
        }
        if achievements.isEmpty {
            setupAchievements()
        }
    }
    
    // MARK: - Setup
    private func setupDefaultCards() {
        healthCards = [
            HealthCard.heartRate(value: 72),
            HealthCard.steps(value: 0),
            HealthCard.sleep(value: 0),
            HealthCard.water(count: 0),
            HealthCard.meditation(done: false)
        ]
    }
    
    private func setupDefaultHabits() {
        habitCards = [
            HabitCard(name: "Morning Walk", description: "Start your day right", icon: "figure.walk", color: "4ECDC4", targetCount: 1, rarity: .common),
            HabitCard(name: "Drink Water", description: "8 glasses a day", icon: "drop.fill", color: "3498DB", targetCount: 8, rarity: .common),
            HabitCard(name: "Meditation", description: "10 minutes mindfulness", icon: "brain.head.profile", color: "9B59B6", targetCount: 1, rarity: .uncommon),
            HabitCard(name: "Exercise", description: "30 minutes workout", icon: "figure.run", color: "E74C3C", targetCount: 1, rarity: .rare),
            HabitCard(name: "Sleep Early", description: "Before 11 PM", icon: "moon.stars.fill", color: "2C3E50", targetCount: 1, rarity: .uncommon)
        ]
    }
    
    private func setupAchievements() {
        achievements = [
            Achievement(name: "First Steps", description: "Collect your first card", icon: "sparkles", requirement: 1, rarity: .common, xpReward: 50),
            Achievement(name: "Habit Master", description: "Complete 10 habits", icon: "trophy.fill", requirement: 10, rarity: .rare, xpReward: 200),
            Achievement(name: "Card Collector", description: "Collect 10 cards", icon: "square.stack.fill", requirement: 10, rarity: .epic, xpReward: 500),
            Achievement(name: "Week Warrior", description: "Maintain a 7-day streak", icon: "flame.fill", requirement: 7, rarity: .rare, xpReward: 300),
            Achievement(name: "Perfect Day", description: "Complete all habits in one day", icon: "star.circle.fill", requirement: 5, rarity: .legendary, xpReward: 1000)
        ]
    }
    
    // MARK: - Card Operations
    func completeHabit(_ habitId: UUID) {
        guard let index = habitCards.firstIndex(where: { $0.id == habitId }) else { return }
        var habit = habitCards[index]
        
        if !habit.isCompletedToday {
            habit.isCompletedToday = true
            habit.currentStreak += 1
            habit.lastCompleted = Date()
            if habit.currentStreak > habit.longestStreak {
                habit.longestStreak = habit.currentStreak
            }
            habitCards[index] = habit
            todayHabitsCompleted += 1
            
            // Award XP
            userLevel.addXP(xpPerHabit)
            currentXPAnimation = xpPerHabit
            triggerXPAnimation()
            
            // Check evolution
            checkHabitEvolution(habit)
            
            // Update achievement progress
            updateAchievementProgress(id: "habit_master")
            updateAchievementProgress(id: "week_warrior")
            if todayHabitsCompleted >= habitCards.count {
                unlockAchievement(id: "perfect_day")
            }
            
            saveData()
        }
    }
    
    private func checkHabitEvolution(_ habit: HabitCard) {
        // Award shiny card after 30 day streak
        if habit.evolutionStage == 3 {
            if let healthCard = healthCards.first(where: { $0.name == habit.name }) {
                if let index = healthCards.firstIndex(where: { $0.id == healthCard.id }) {
                    var card = healthCards[index]
                    card.isShiny = true
                    healthCards[index] = card
                }
            }
        }
    }
    
    func updateHealthCard(id: UUID, value: Double) {
        guard let index = healthCards.firstIndex(where: { $0.id == id }) else { return }
        var card = healthCards[index]
        card.currentValue = value
        if value > 0 && !card.isCollected {
            card.isCollected = true
            totalCardsCollected += 1
            lastPulledCard = card
            showCardAnimation = true
            userLevel.addXP(xpPerCard)
            triggerCardAnimation()
            updateAchievementProgress(id: "first_steps")
            updateAchievementProgress(id: "card_collector")
        }
        healthCards[index] = card
        saveData()
    }
    
    // MARK: - Achievement Operations
    private func updateAchievementProgress(id: String) {
        // Implementation
    }
    
    private func unlockAchievement(id: String) {
        // Implementation
    }
    
    // MARK: - Animations
    private func triggerXPAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.currentXPAnimation = 0
        }
    }
    
    private func triggerCardAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.showCardAnimation = false
            self?.lastPulledCard = nil
        }
    }
    
    // MARK: - Data Persistence
    func saveData() {
        if let healthData = try? JSONEncoder().encode(healthCards) {
            userDefaults.set(healthData, forKey: "healthCards")
        }
        if let habitData = try? JSONEncoder().encode(habitCards) {
            userDefaults.set(habitData, forKey: "habitCards")
        }
        if let levelData = try? JSONEncoder().encode(userLevel) {
            userDefaults.set(levelData, forKey: "userLevel")
        }
        if let achievementData = try? JSONEncoder().encode(achievements) {
            userDefaults.set(achievementData, forKey: "achievements")
        }
        userDefaults.set(totalCardsCollected, forKey: "totalCardsCollected")
        userDefaults.set(todayHabitsCompleted, forKey: "todayHabitsCompleted")
    }
    
    private func loadData() {
        if let healthData = userDefaults.data(forKey: "healthCards"),
           let cards = try? JSONDecoder().decode([HealthCard].self, from: healthData) {
            healthCards = cards
        }
        if let habitData = userDefaults.data(forKey: "habitCards"),
           let habits = try? JSONDecoder().decode([HabitCard].self, from: habitData) {
            habitCards = habits
        }
        if let levelData = userDefaults.data(forKey: "userLevel"),
           let level = try? JSONDecoder().decode(UserLevel.self, from: levelData) {
            userLevel = level
        }
        if let achievementData = userDefaults.data(forKey: "achievements"),
           let achievementsData = try? JSONDecoder().decode([Achievement].self, from: achievementData) {
            achievements = achievementsData
        }
        totalCardsCollected = userDefaults.integer(forKey: "totalCardsCollected")
        todayHabitsCompleted = userDefaults.integer(forKey: "todayHabitsCompleted")
    }
    
    func resetDailyHabits() {
        for i in habitCards.indices {
            habitCards[i].isCompletedToday = false
        }
        todayHabitsCompleted = 0
        saveData()
    }
}