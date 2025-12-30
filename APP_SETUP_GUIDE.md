# Living Devotional App Setup Guide

## Current Status

✅ **Code Implementation Complete**
- All Swift code is implemented and ready
- BSB and CUV Bible data files are downloaded and converted
- Navigation flow: Books → Chapters → Reading View
- Dual-language support (BSB + CUV)
- Settings for language preferences
- Reading progress tracking

## File Structure

```
livingdevotional/
├── Models/
│   ├── Models.swift          ✅ Language enum (bsb, cuv), BibleVerse, etc.
│   └── BibleData.swift       ✅ Book metadata and localization
├── Data/
│   ├── BibleService.swift    ✅ Loads verses from JSON files
│   ├── SettingsStore.swift  ✅ Manages language preferences
│   └── ProgressStore.swift  ✅ Tracks reading progress
├── ViewModels/
│   ├── BibleViewModel.swift  ✅ Navigation state management
│   └── ReadingViewModel.swift ✅ Verse loading and display
├── Views/
│   ├── MainTabView.swift     ✅ Tab bar navigation
│   ├── BookListView.swift    ✅ List of Bible books
│   ├── ChapterGridView.swift ✅ Chapter selection grid
│   ├── ReadingView.swift     ✅ Verse display with dual-language
│   └── SettingsView.swift    ✅ Language settings
└── Resources/
    └── BibleData/
        ├── bsb/              ✅ 1,189 BSB chapter files
        └── cuv/              ✅ 1,189 CUV chapter files
```

## Required Steps to Make App Usable

### 1. Add BibleData Folder to Xcode Project

**Critical Step**: The `BibleData` folder must be added to your Xcode project so the files are included in the app bundle.

1. Open `livingdevotional.xcodeproj` in Xcode
2. Right-click on the `livingdevotional` folder in Project Navigator
3. Select **"Add Files to 'livingdevotional'..."**
4. Navigate to `livingdevotional/Resources/BibleData`
5. **Important Settings**:
   - ✅ Check **"Copy items if needed"** (if files aren't already in project)
   - ✅ Select **"Create groups"** (yellow folder icon, NOT "Create folder references")
   - ✅ Check **"Add to targets: livingdevotional"**
6. Click **"Add"**

### 2. Verify Bundle Inclusion

After adding the folder:

1. Select the `BibleData` folder in Xcode Project Navigator
2. Open the **File Inspector** (right panel, ⌥⌘1)
3. Verify:
   - **Target Membership**: `livingdevotional` is checked ✅
   - **Location**: Should show the folder path

### 3. Test the App

1. Build and run the app (⌘R)
2. Navigate: **Bible Tab** → Select a book → Select a chapter
3. Verify verses load and display correctly
4. Test language switching in **Settings**

## Expected Behavior

### Navigation Flow
1. **Bible Tab** → Shows list of 66 books (Old/New Testament)
2. **Tap a book** → Shows grid of chapters
3. **Tap a chapter** → Shows verses with dual-language display

### Language Display
- **Primary Language**: Displayed in normal text (default: BSB)
- **Secondary Language**: Displayed below in gray (default: CUV)
- Can be changed in **Settings** tab

### Reading Progress
- Automatically saves last read book/chapter
- App resumes from last position on launch

## Troubleshooting

### "Bible file not found" Error

**Problem**: Files not found in app bundle

**Solutions**:
1. Verify `BibleData` folder is added to Xcode project (see step 1 above)
2. Check Target Membership is enabled
3. Clean build folder (⌘⇧K) and rebuild
4. Check file path in `BibleService.swift` matches your folder structure

### Verses Not Displaying

**Check**:
1. Verify JSON files are in correct format: `[{"verse": 1, "text": "..."}, ...]`
2. Check console for error messages
3. Verify language settings in Settings tab

### Navigation Not Working

**Check**:
1. Verify `BibleViewModel` is properly initialized
2. Check that `selectBook()` and `selectChapter()` are being called
3. Verify NavigationStack is properly set up

## File Format Verification

Each chapter JSON file should look like:
```json
[
  {
    "verse": 1,
    "text": "In the beginning God created..."
  },
  {
    "verse": 2,
    "text": "Now the earth was formless..."
  }
]
```

## Next Steps After Setup

Once the app is working:
1. Test reading different books and chapters
2. Test language switching (BSB ↔ CUV)
3. Test reading progress persistence
4. Consider adding features:
   - Bookmarking verses
   - Search functionality
   - Verse of the day
   - Reading plans

## Support

If you encounter issues:
1. Check Xcode console for error messages
2. Verify all files are in the correct locations
3. Ensure BibleData folder is properly added to the project bundle

