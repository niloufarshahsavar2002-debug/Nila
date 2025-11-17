//
//  ContentView.swift
//  Nila
//
//  Created by Niloufar on 15/11/25.
//

import SwiftUI
import AVFoundation

struct PagedAffirmationsView: View {
    let phrases: [String]
    
    @State private var currentPage = 0
    // Persist favorites by indices so the state survives relaunches
    @AppStorage("favoriteIndices")
    private var favoriteIndicesData: Data = Data()
    @State private var favoriteIndices: Set<Int> = []
    
    // Simple share sheet
    @State private var shareItem: [Any]? // changed to array to support text + image
    
    // In-app toast
    @State private var showToast = false
    @State private var toastMessage = ""
    
    // Profile sheet
    @State private var showProfile = false
    
    // Streak storage (persisted)
    @AppStorage("streakMarkedDates")
    private var streakDatesData: Data = Data()
    @State private var streakMarkedDates: Set<String> = [] // "yyyy-MM-dd"
    @State private var showStreak = false

    // Use environment display scale instead of UIScreen.main
    @Environment(\.displayScale) private var displayScale: CGFloat
    
    // Extracted to reduce type-checking load
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 1.0, green: 0.85, blue: 0.90),
                Color(red: 0.90, green: 0.75, blue: 1.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var topBar: some View {
        HStack {
            StreakButton(
                isTodayMarked: isTodayMarked,
                weekDates: weekDates,
                isMarked: { (date: Date) in
                    streakMarkedDates.contains(dateKey(for: date))
                },
                action: { showStreak = true }
            )
            
            Spacer()
            
            Button {
                showProfile = true
            } label: {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                    .padding(10)
                    .background(.black.opacity(0.15), in: Capsule())
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
    }
    
    private var pager: some View {
        TabView(selection: $currentPage) {
            ForEach(phrases.indices, id: \.self) { index in
                PhraseCardView(
                    phrase: phrases[index],
                    isFavorite: isFavorite(index: index),
                    onToggleFavorite: { toggleFavorite(index: index) },
                    onShare: { presentShare(for: phrases[index]) }
                )
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.easeInOut, value: currentPage)
    }
    
    private var pageIndicator: some View {
        CustomPageIndicator(
            numberOfPages: phrases.count,
            currentPage: $currentPage
        )
        .padding(.top, 12)
        .padding(.bottom, 12)
    }
    
    private var actionRow: some View {
        ActionRowView(
            phrasesCount: phrases.count,
            currentPage: $currentPage
        )
        .padding(.horizontal)
        .padding(.bottom, 32)
    }
    
    private var toastOverlay: some View {
        Group {
            if showToast {
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .semibold))
                        Text(toastMessage)
                            .foregroundColor(.white)
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.black.opacity(0.75), in: Capsule())
                    .padding(.bottom, 24)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.25), value: showToast)
                .ignoresSafeArea(edges: .bottom)
            }
        }
    }
    
    var body: some View {
        ZStack {
            backgroundGradient
            
            VStack(spacing: 0) {
                topBar
                pager
                pageIndicator
                actionRow
            }
            
            toastOverlay
        }
        .onAppear {
            favoriteIndices = loadFavorites()
            streakMarkedDates = loadStreak()
        }
        .onChange(of: favoriteIndices) { _, newValue in
            saveFavorites(newValue)
        }
        .onChange(of: streakMarkedDates) { _, newValue in
            saveStreak(newValue)
        }
        // Share sheet: now binds to optional [Any]
        .sheet(item: $shareItem.asIdentifiedArray) { items in
            // Present the system share sheet with your payload
            ShareView(activityItems: items.value)
        }
        // Profile sheet
        .sheet(isPresented: $showProfile) {
            ProfileView()
        }
        // Streak sheet
        .sheet(isPresented: $showStreak) {
            StreakView(
                weekDates: weekDates,
                isMarked: { date in streakMarkedDates.contains(dateKey(for: date)) },
                markToday: { markToday() },
                close: { showStreak = false }
            )
        }
    }
    
    // MARK: - Share helpers
    
    private func presentShare(for phrase: String) {
        // Always include the text
        var items: [Any] = [phrase]
        // Also include a rendered image for better compatibility with social apps
        if let image = renderAffirmationImage(text: phrase, scale: displayScale) {
            items.append(image)
        }
        shareItem = items
    }
    
    private func renderAffirmationImage(text: String, scale: CGFloat) -> UIImage? {
        // Build a simple stylized card image using SwiftUI
        let card = ZStack {
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.85, blue: 0.90),
                    Color(red: 0.90, green: 0.75, blue: 1.0)
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(0.2))
                    .padding(12)
            )
            VStack(spacing: 12) {
                Text("I Am")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.95))
                    .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                Text(text)
                    .font(.custom("Chalkduster", size: 22))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
            }
            .padding()
        }
        .frame(width: 1080/2, height: 1920/2) // 540x960 px ~ 9:16 portrait
        
        if #available(iOS 16.0, *) {
            let renderer = ImageRenderer(content: card)
            renderer.scale = scale
            return renderer.uiImage
        } else {
            let controller = UIHostingController(rootView: card)
            let view = controller.view
            let targetSize = CGSize(width: 540, height: 960)
            view?.bounds = CGRect(origin: .zero, size: targetSize)
            view?.backgroundColor = .clear
            let renderer = UIGraphicsImageRenderer(size: targetSize)
            return renderer.image { _ in
                view?.drawHierarchy(in: CGRect(origin: .zero, size: targetSize), afterScreenUpdates: true)
            }
        }
    }
    
    // MARK: - Favorites
    
    private func isFavorite(index: Int) -> Bool {
        favoriteIndices.contains(index)
    }
    
    private func toggleFavorite(index: Int) {
        let wasFavorite = favoriteIndices.contains(index)
        if wasFavorite {
            favoriteIndices.remove(index)
            showToast(message: "Removed from favorites")
        } else {
            favoriteIndices.insert(index)
            showToast(message: "Added to favorites")
        }
    }
    
    private func showToast(message: String) {
        toastMessage = message
        withAnimation { showToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { showToast = false }
        }
    }
    
    private func saveFavorites(_ set: Set<Int>) {
        do {
            let data = try JSONEncoder().encode(Array(set))
            favoriteIndicesData = data
        } catch {
            // Silent fail is fine for this simple app
        }
    }
    
    private func loadFavorites() -> Set<Int> {
        guard !favoriteIndicesData.isEmpty else { return [] }
        do {
            let arr = try JSONDecoder().decode([Int].self, from: favoriteIndicesData)
            return Set(arr.filter { $0 >= 0 && $0 < phrases.count })
        } catch {
            return []
        }
    }
    
    // MARK: - Streak helpers
    
    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 2 // Monday as first day
        return cal
    }
    
    private var weekDates: [Date] {
        let today = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) ?? today
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }
    
    private var isTodayMarked: Bool {
        streakMarkedDates.contains(dateKey(for: Date()))
    }
    
    private func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func markToday() {
        let key = dateKey(for: Date())
        if !streakMarkedDates.contains(key) {
            streakMarkedDates.insert(key)
            showToast(message: "Streak marked for today")
        }
    }
    
    private func saveStreak(_ set: Set<String>) {
        do {
            let data = try JSONEncoder().encode(Array(set))
            streakDatesData = data
        } catch {
            // ignore
        }
    }
    
    private func loadStreak() -> Set<String> {
        guard !streakDatesData.isEmpty else { return [] }
        do {
            let arr = try JSONDecoder().decode([String].self, from: streakDatesData)
            return Set(arr)
        } catch {
            return []
        }
    }
}

// MARK: - Profile

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("profile_name") private var name: String = ""
    @AppStorage("profile_email") private var email: String = ""
    // Store dob as time interval to be @AppStorage-friendly
    @AppStorage("profile_dob") private var dobTimeInterval: Double = Date().timeIntervalSince1970
    
    private var dobBinding: Binding<Date> {
        Binding<Date>(
            get: { Date(timeIntervalSince1970: dobTimeInterval) },
            set: { dobTimeInterval = $0.timeIntervalSince1970 }
        )
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Profile")) {
                    TextField("Name", text: $name)
                        .textContentType(.name)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                    
                    DatePicker("Date of Birth", selection: dobBinding, displayedComponents: .date)
                    
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                
                if !email.isEmpty && !isValidEmail(email) {
                    Text("Please enter a valid email.")
                        .font(.footnote)
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("Your Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func isValidEmail(_ text: String) -> Bool {
        let parts = text.split(separator: "@")
        guard parts.count == 2, parts[0].count > 0, parts[1].contains(".") else { return false }
        return true
    }
}

// MARK: - Streak Sheet

struct StreakView: View {
    let weekDates: [Date]
    let isMarked: (Date) -> Bool
    let markToday: () -> Void
    let close: () -> Void
    
    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 2
        return cal
    }
    
    private var weekdaySymbols: [String] {
        let symbols = calendar.shortWeekdaySymbols // Sun..Sat
        // Reorder to Mon..Sun
        let monIndex = 1 // Monday in Calendar with firstWeekday=2
        return Array(symbols[monIndex...] + symbols[..<monIndex])
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Week grid
                HStack(spacing: 12) {
                    ForEach(Array(weekDates.enumerated()), id: \.element) { idx, date in
                        VStack(spacing: 6) {
                            Text(weekdaySymbols[idx % 7])
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Circle()
                                .fill(isMarked(date) ? Color.orange : Color.gray.opacity(0.3))
                                .frame(width: 18, height: 18)
                        }
                    }
                }
                .padding(.top, 16)
                
                Button {
                    markToday()
                } label: {
                    Label("Mark Today", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(.orange, in: Capsule())
                }
                .padding(.top, 8)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Your Streak")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { close() }
                }
            }
        }
    }
}

// MARK: - Nuovi Componenti Riutilizzabili

/// Indica la pagina corrente con dei puntini.
struct CustomPageIndicator: View {
    let numberOfPages: Int
    @Binding var currentPage: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<numberOfPages, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color.black : Color.black.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .scaleEffect(index == currentPage ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
        }
    }
}

struct PhraseCardView: View {
    let phrase: String
    let isFavorite: Bool
    let onToggleFavorite: () -> Void
    let onShare: () -> Void
    
    // Consistent circular button style
    @ViewBuilder
    private func CircularIconButton(systemName: String, foreground: Color = .white, background: Color) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(foreground)
            .frame(width: 40, height: 40)
            .background(background, in: Circle())
    }
    
    var body: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 24)
            
            // The phrase text
            Text(phrase)
                .font(.custom("Chalkduster", size: 26))
                .multilineTextAlignment(.center)
                .foregroundColor(.black)
                .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
                .padding(.horizontal)
                .transition(.opacity .combined(with: .scale))
                .animation(.easeInOut(duration: 0.4), value: phrase)
            
            // Decorative little hearts under the sentence
            HStack(spacing: 6) {
                ForEach(0..<5, id: \.self) { i in
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red.opacity(i % 2 == 0 ? 0.9 : 0.6))
                        .font(.system(size: 10, weight: .bold))
                        .shadow(color: .black.opacity(0.1), radius: 1, y: 1)
                }
            }
            .padding(.top, 6)
            
            Spacer()
            
            // Favorite toggle e Share
            HStack(spacing: 16) {
                // Favorite toggle (circular)
                Button {
                    onToggleFavorite()
                } label: {
                    CircularIconButton(
                        systemName: isFavorite ? "heart.fill" : "heart",
                        foreground: isFavorite ? .red : .white,
                        background: Color.black.opacity(0.15)
                    )
                }
                .accessibilityLabel(isFavorite ? "Rimuovi Preferito" : "Aggiungi Preferito")
                
                // Share (circular)
                Button {
                    onShare()
                } label: {
                    CircularIconButton(
                        systemName: "square.and.arrow.up",
                        foreground: .white,
                        background: Color.black.opacity(0.15)
                    )
                }
            }
            .padding(.bottom, 10)
        }
    }
}

struct ActionRowView: View {
    let phrasesCount: Int
    @Binding var currentPage: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // Previous
            Button {
                withAnimation(.easeInOut) {
                    currentPage = max(0, currentPage - 1)
                }
            } label: {
                Label("Previous", systemImage: "chevron.left")
                    .labelStyle(.iconOnly)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(.black.opacity(0.15), in: Circle())
            }
            .disabled(currentPage == 0)
            .opacity(currentPage == 0 ? 0.5 : 1.0)
            
            Spacer()
            
            // Shuffle
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    currentPage = Int.random(in: 0..<phrasesCount)
                }
            } label: {
                Image(systemName: "shuffle")
                    .foregroundColor(.white)
                    .padding(12)
                    .background(.black.opacity(0.15), in: Capsule())
            }
            
            Spacer()

            // Next
            Button {
                withAnimation(.easeInOut) {
                    currentPage = min(phrasesCount - 1, currentPage + 1)
                }
            } label: {
                Label("Next", systemImage: "chevron.right")
                    .labelStyle(.iconOnly)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(.black.opacity(0.15), in: Circle())
            }
            .disabled(currentPage == phrasesCount - 1)
            .opacity(currentPage == phrasesCount - 1 ? 0.5 : 1.0)
        }
    }
}

// MARK: - Helpers
private struct IdentifiedValue<T>: Identifiable {
    let id = UUID()
    let value: T
}

private extension Binding where Value == [Any]? {
    var asIdentifiedArray: Binding<IdentifiedValue<[Any]>?> {
        Binding<IdentifiedValue<[Any]>?>(
            get: {
                if let v = self.wrappedValue {
                    return IdentifiedValue<[Any]>(value: v)
                }
                return nil
            },
            set: { newValue in
                self.wrappedValue = newValue?.value
            }
        )
    }
}

// MARK: - ShareView
struct ShareView: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Extracted small views to ease type checking

private struct StreakButton: View {
    let isTodayMarked: Bool
    let weekDates: [Date]
    let isMarked: (Date) -> Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isTodayMarked ? .orange : .white)
                    .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                
                WeekDotsView(weekDates: weekDates, isMarked: isMarked)
            }
            .padding(10)
            .background(.black.opacity(0.15), in: Capsule())
            .accessibilityLabel("Streak")
        }
    }
}

private struct WeekDotsView: View {
    let weekDates: [Date]
    let isMarked: (Date) -> Bool
    
    private func dotColor(for date: Date) -> Color {
        isMarked(date) ? .orange : Color.white.opacity(0.35)
    }
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(weekDates, id: \.self) { date in
                Circle()
                    .fill(dotColor(for: date))
                    .frame(width: 6, height: 6)
            }
        }
    }
}

#Preview {
    PagedAffirmationsView(phrases: [
        "I am full of infinite hope.",
        "I am grounded, calm, and present.",
        "I am worthy of love and peace.",
        "I am growing into my best self.",
        "I am resilient and capable.",
        "I am grateful for this moment.",
        "I am open to joy and abundance.",
        "I am confident in my path.",
        "I am kind to myself and others.",
        "I am learning and evolving every day.",
        "I am strong in mind, body, and spirit.",
        "I am exactly where I need to be."
    ])
}
