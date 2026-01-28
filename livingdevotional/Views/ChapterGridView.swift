// ChapterGridView - Grid layout for selecting chapters

import SwiftUI

struct ChapterGridView: View {
    let book: BibleBook
    @ObservedObject var viewModel: BibleViewModel
    @ObservedObject var settingsStore = SettingsStore.shared
    @ObservedObject var progressStore = ProgressStore.shared
    @Environment(\.dismiss) private var dismiss
    
    private let columns = [
        GridItem(.adaptive(minimum: 60), spacing: 12)
    ]
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(1...book.chapters, id: \.self) { chapter in
                        ChapterButton(
                            chapter: chapter,
                            book: book,
                            viewModel: viewModel,
                            isRead: progressStore.isChapterRead(book: book.name, chapter: chapter)
                        )
                    }
                }
                .padding()
            }
        }
        .navigationTitle(book.localizedName(for: settingsStore.primaryLanguage))
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    // Update viewModel state and dismiss in one action
                    // dismiss() will pop the navigation stack
                    viewModel.goBackToBookList()
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text(settingsStore.appLanguage.localizedString("Books"))
                    }
                    .foregroundColor(AppTheme.accentColor)
                }
            }
        }
    }
}

struct ChapterButton: View {
    let chapter: Int
    let book: BibleBook
    @ObservedObject var viewModel: BibleViewModel
    let isRead: Bool
    
    var body: some View {
        NavigationLink(value: NavigationDestination.reading(book, chapter)) {
            Text("\(chapter)")
                .font(.system(size: 18, weight: isRead ? .medium : .semibold))
                .foregroundColor(.white)
                .frame(width: 70, height: 70)
                .background(
                    AppTheme.chapterButtonGradient
                        .opacity(isRead ? 0.6 : 1.0)
                )
                .cornerRadius(16)
                .shadow(
                    color: AppTheme.chapterButtonColor.opacity(isRead ? 0.15 : 0.3), 
                    radius: 8, 
                    x: 0, 
                    y: 4
                )
        }
        .buttonStyle(PlainButtonStyle())
        .onTapGesture {
            // Update viewModel state when NavigationLink is tapped
            viewModel.selectChapter(chapter)
        }
    }
}

#Preview {
    NavigationStack {
        ChapterGridView(book: BibleData.books[0], viewModel: BibleViewModel())
    }
}

