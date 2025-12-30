// BookSelectionSheet - Bottom sheet for selecting books with expandable chapter grid

import SwiftUI

struct BookSelectionSheet: View {
    @ObservedObject var viewModel: BibleViewModel
    @Binding var isPresented: Bool
    @ObservedObject var settingsStore = SettingsStore.shared
    @State private var selectedTab = 0
    @State private var selectedBook: BibleBook?
    @State private var selectedChapter: Int = 1
    
    // Chapter grid columns - 5 per row
    private let chapterColumns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)
    
    var body: some View {
        NavigationStack {
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
                    
                    // Book List with smooth inline chapter expansion
                    List {
                        if selectedTab == 0 {
                            // Old Testament
                            ForEach(viewModel.oldTestamentBooks) { book in
                                DisclosureGroup(
                                    isExpanded: Binding(
                                        get: { selectedBook?.name == book.name },
                                        set: { isExpanded in
                                            withAnimation {
                                                if isExpanded {
                                                    selectedBook = book
                                                    selectedChapter = 1
                                                } else {
                                                    selectedBook = nil
                                                }
                                            }
                                        }
                                    )
                                ) {
                                    // Chapter grid - 5 columns per row
                                    LazyVGrid(columns: chapterColumns, spacing: 12) {
                                        ForEach(1...book.chapters, id: \.self) { chapter in
                                            ChapterSelectionButton(
                                                chapter: chapter,
                                                isSelected: selectedChapter == chapter,
                                                onSelect: {
                                                    selectedChapter = chapter
                                                    viewModel.selectBook(book)
                                                    viewModel.selectChapter(chapter)
                                                    isPresented = false
                                                }
                                            )
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                } label: {
                                    BookSelectionRow(
                                        book: book,
                                        isSelected: selectedBook?.name == book.name,
                                        onSelect: {
                                            withAnimation {
                                                if selectedBook?.name == book.name {
                                                    // If already selected, collapse
                                                    selectedBook = nil
                                                } else {
                                                    // Otherwise, expand
                                                    selectedBook = book
                                                    selectedChapter = 1
                                                }
                                            }
                                        }
                                    )
                                }
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                            }
                        } else {
                            // New Testament
                            ForEach(viewModel.newTestamentBooks) { book in
                                DisclosureGroup(
                                    isExpanded: Binding(
                                        get: { selectedBook?.name == book.name },
                                        set: { isExpanded in
                                            withAnimation {
                                                if isExpanded {
                                                    selectedBook = book
                                                    selectedChapter = 1
                                                } else {
                                                    selectedBook = nil
                                                }
                                            }
                                        }
                                    )
                                ) {
                                    // Chapter grid - 5 columns per row
                                    LazyVGrid(columns: chapterColumns, spacing: 12) {
                                        ForEach(1...book.chapters, id: \.self) { chapter in
                                            ChapterSelectionButton(
                                                chapter: chapter,
                                                isSelected: selectedChapter == chapter,
                                                onSelect: {
                                                    selectedChapter = chapter
                                                    viewModel.selectBook(book)
                                                    viewModel.selectChapter(chapter)
                                                    isPresented = false
                                                }
                                            )
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                } label: {
                                    BookSelectionRow(
                                        book: book,
                                        isSelected: selectedBook?.name == book.name,
                                        onSelect: {
                                            withAnimation {
                                                if selectedBook?.name == book.name {
                                                    // If already selected, collapse
                                                    selectedBook = nil
                                                } else {
                                                    // Otherwise, expand
                                                    selectedBook = book
                                                    selectedChapter = 1
                                                }
                                            }
                                        }
                                    )
                                }
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Select Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundColor(AppTheme.accentColor)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear {
            // Initialize with current selection if available
            if let currentBook = viewModel.selectedBook {
                selectedBook = currentBook
                selectedChapter = viewModel.selectedChapter ?? 1
                selectedTab = currentBook.testament == .old ? 0 : 1
            }
        }
    }
}

struct BookSelectionRow: View {
    let book: BibleBook
    let isSelected: Bool
    let onSelect: () -> Void
    @ObservedObject var settingsStore = SettingsStore.shared
    
    var body: some View {
        Button(action: onSelect) {
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
                    .background(AppTheme.chapterButtonColor.opacity(0.1))
                    .cornerRadius(8)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
        .listRowSeparator(.hidden)
    }
}

struct ChapterSelectionButton: View {
    let chapter: Int
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            Text("\(chapter)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isSelected ? AppTheme.chapterButtonColor : AppTheme.primaryText)
                .frame(width: 60, height: 60)
                .background(
                    isSelected 
                        ? AppTheme.chapterButtonColor.opacity(0.15)
                        : Color(red: 0.96, green: 0.96, blue: 0.98)
                )
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isSelected 
                                ? AppTheme.chapterButtonColor.opacity(0.4)
                                : Color.gray.opacity(0.2),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    BookSelectionSheet(
        viewModel: BibleViewModel(),
        isPresented: .constant(true)
    )
}

