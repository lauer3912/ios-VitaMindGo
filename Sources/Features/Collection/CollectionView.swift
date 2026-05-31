import SwiftUI

struct CollectionView: View {
    @EnvironmentObject var gameState: GameState
    @State private var selectedFilter: CollectionFilter = .all
    @State private var selectedCard: HealthCard? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                VitaTheme.Colors.background.ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Filter tabs
                    CollectionFilterTab(selected: $selectedFilter)
                        .accessibilityIdentifier("collection_filter")
                    
                    // Collection stats
                    CollectionStatsBar()
                        .accessibilityIdentifier("collection_stats")
                    
                    // Card grid
                    CollectionGrid(
                        cards: filteredCards,
                        selectedFilter: selectedFilter,
                        onCardTap: { selectedCard = $0 }
                    )
                    .accessibilityIdentifier("collection_grid")
                    
                    // Achievements
                    AchievementsSection()
                        .accessibilityIdentifier("achievements_section")
                }
            }
            .navigationTitle("Collection")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(item: $selectedCard) { card in
                CardDetailSheet(card: card)
            }
        }
        .accessibilityIdentifier("collection_view")
    }
    
    private var filteredCards: [HealthCard] {
        switch selectedFilter {
        case .all:
            return gameState.healthCards
        case .collected:
            return gameState.healthCards.filter(\.isCollected)
        case .health:
            return gameState.healthCards.filter { $0.type == .health }
        case .habits:
            return gameState.healthCards.filter { $0.type == .habit }
        case .shiny:
            return gameState.healthCards.filter(\.isShiny)
        }
    }
}

// MARK: - Filter Enum
enum CollectionFilter: String, CaseIterable {
    case all = "All"
    case collected = "Collected"
    case health = "Health"
    case habits = "Habits"
    case shiny = "Shiny"
    
    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .collected: return "checkmark.circle"
        case .health: return "heart.fill"
        case .habits: return "checkmark.seal"
        case .shiny: return "sparkle"
        }
    }
}

// MARK: - Filter Tab
struct CollectionFilterTab: View {
    @Binding var selected: CollectionFilter
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CollectionFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        icon: filter.icon,
                        isSelected: selected == filter
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selected = filter
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(VitaTheme.Fonts.caption)
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? VitaTheme.Colors.primary : VitaTheme.Colors.surface)
            )
        }
    }
}

// MARK: - Stats Bar
struct CollectionStatsBar: View {
    @EnvironmentObject var gameState: GameState
    
    var body: some View {
        HStack(spacing: 16) {
            StatItem(value: "\(gameState.totalCardsCollected)", label: "Total Cards", icon: "square.stack.fill")
            StatItem(value: "\(gameState.healthCards.filter(\.isShiny).count)", label: "Shiny", icon: "sparkle")
            StatItem(value: "\(gameState.userLevel.level)", label: "Level", icon: "star.fill")
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: VitaTheme.Radius.lg)
                .fill(VitaTheme.Colors.surface)
        )
        .padding(.horizontal)
    }
}

struct StatItem: View {
    let value: String
    let label: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(VitaTheme.Colors.accent)
                Text(value)
                    .font(VitaTheme.Fonts.titleMedium)
                    .foregroundColor(.white)
            }
            Text(label)
                .font(VitaTheme.Fonts.statLabel)
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Collection Grid
struct CollectionGrid: View {
    let cards: [HealthCard]
    let selectedFilter: CollectionFilter
    let onCardTap: (HealthCard) -> Void
    
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                Button {
                    onCardTap(card)
                } label: {
                    CollectionCardItem(card: card, index: index)
                }
                .accessibilityIdentifier("collection_card_\(index)")
            }
        }
        .padding(.horizontal)
    }
}

struct CollectionCardItem: View {
    let card: HealthCard
    let index: Int
    
    var body: some View {
        ZStack {
            if card.isCollected {
                GameCardView(card: card, isInteractive: false)
            } else {
                LockedCardView(rarity: card.rarity)
            }
        }
    }
}

struct LockedCardView: View {
    let rarity: CardRarity
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: VitaTheme.Radius.card)
                .fill(VitaTheme.Colors.surface)
                .frame(width: 160, height: 220)
            
            VStack(spacing: 8) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
                
                Text("???")
                    .font(VitaTheme.Fonts.caption)
                    .foregroundColor(.gray)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: VitaTheme.Radius.card)
                .stroke(rarity.color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Achievements Section
struct AchievementsSection: View {
    @EnvironmentObject var gameState: GameState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Achievements")
                .font(VitaTheme.Fonts.title)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            ForEach(Array(gameState.achievements.enumerated()), id: \.element.id) { index, achievement in
                AchievementCardView(achievement: achievement)
                    .padding(.horizontal)
                    .accessibilityIdentifier("achievement_\(index)")
            }
        }
    }
}

// MARK: - Card Detail Sheet
struct CardDetailSheet: View {
    let card: HealthCard
    @EnvironmentObject var gameState: GameState
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                VitaTheme.Colors.background.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    GameCardView(card: card, isInteractive: true)
                        .accessibilityIdentifier("sheet_card")
                    
                    VStack(spacing: 16) {
                        HStack {
                            ForEach(0..<card.rarity.stars, id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .foregroundColor(card.rarity.color)
                            }
                        }
                        
                        Text(card.name)
                            .font(VitaTheme.Fonts.displayBold)
                            .foregroundColor(.white)
                        
                        Text(card.description)
                            .font(VitaTheme.Fonts.body)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                        
                        Divider()
                            .background(Color.white.opacity(0.2))
                        
                        HStack(spacing: 32) {
                            VStack {
                                Text("\(Int(card.currentValue))")
                                    .font(VitaTheme.Fonts.statNumber)
                                    .foregroundColor(VitaTheme.Colors.primary)
                                Text("Current")
                                    .font(VitaTheme.Fonts.caption)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            
                            VStack {
                                Text("\(Int(card.maxValue))")
                                    .font(VitaTheme.Fonts.statNumber)
                                    .foregroundColor(.white)
                                Text("Goal")
                                    .font(VitaTheme.Fonts.caption)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: VitaTheme.Radius.lg)
                            .fill(VitaTheme.Colors.surface)
                    )
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.top, 24)
            }
            .navigationTitle("Card Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(VitaTheme.Colors.primary)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}