// BookListView - Displays list of Bible books organized by Testament

import SwiftUI

struct BookListView: View {
    @ObservedObject var viewModel: BibleViewModel
    @ObservedObject var settingsStore = SettingsStore.shared
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Segmented Control for Testament Selection
                Picker("Testament", selection: $selectedTab) {
                    Text(BibleData.localizedTestamentName(.old, language: settingsStore.primaryLanguage))
                        .tag(0)
                    Text(BibleData.localizedTestamentName(.new, language: settingsStore.primaryLanguage))
                        .tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
                
                // Book List based on selected tab
                List {
                    if selectedTab == 0 {
                        // Old Testament
                        ForEach(viewModel.oldTestamentBooks) { book in
                            BookRow(book: book, viewModel: viewModel)
                                .listRowBackground(Color.clear)
                        }
                    } else {
                        // New Testament
                        ForEach(viewModel.newTestamentBooks) { book in
                            BookRow(book: book, viewModel: viewModel)
                                .listRowBackground(Color.clear)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Bible")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct BookRow: View {
    let book: BibleBook
    @ObservedObject var viewModel: BibleViewModel
    @ObservedObject var settingsStore = SettingsStore.shared
    
    var body: some View {
        NavigationLink(value: NavigationDestination.chapterGrid(book)) {
            HStack {
                Text(book.localizedName(for: settingsStore.primaryLanguage))
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.primaryText)
                Spacer()
                Text("\(book.chapters) \(book.chapters == 1 ? "chapter" : "chapters")")
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppTheme.primaryGradient.opacity(0.1))
                    .cornerRadius(8)
            }
            .padding(.vertical, 4)
        }
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
        .onTapGesture {
            // Update viewModel state when NavigationLink is tapped
            viewModel.selectBook(book)
        }
    }
}

#Preview {
    NavigationStack {
        BookListView(viewModel: BibleViewModel())
    }
}

