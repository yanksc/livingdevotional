# Bible Data Setup Guide

## Download Status

The Bible data download script is running in the background. It will download:
- **BSB** (Berean Standard Bible) → saved as `niv/` folder
- **cmn_cuv** (Chinese Union Version) → saved as `cuv/` folder  
- **ENGWEBP** (English Web) → saved as `engwebp/` folder

## File Structure

Files are being downloaded to:
```
livingdevotional/Resources/BibleData/
├── niv/
│   ├── GEN/
│   │   ├── 1.json
│   │   ├── 2.json
│   │   └── ...
│   ├── EXO/
│   └── ...
├── cuv/
│   ├── GEN/
│   └── ...
└── engwebp/
    └── ...
```

## Next Steps

### 1. Wait for Download to Complete
Check progress:
```bash
tail -f download.log
```

Or check file count:
```bash
find livingdevotional/Resources/BibleData -name "*.json" | wc -l
```

Expected: ~3,567 JSON files (1,189 chapters × 3 translations)

### 2. Add BibleData to Xcode Project

1. Open `livingdevotional.xcodeproj` in Xcode
2. Right-click on the `livingdevotional` folder in Project Navigator
3. Select "Add Files to 'livingdevotional'..."
4. Navigate to and select the `Resources/BibleData` folder
5. **Important**: Make sure these options are checked:
   - ✅ "Copy items if needed" (if files aren't already in project)
   - ✅ "Create groups" (not "Create folder references")
   - ✅ Add to target: `livingdevotional`
6. Click "Add"

### 3. Verify Bundle Inclusion

1. Select the `BibleData` folder in Xcode
2. In the File Inspector (right panel), verify:
   - Target Membership: `livingdevotional` is checked
   - Location: "Relative to Group" or "Relative to Project"

### 4. Test the App

The app should now be able to load Bible verses from the local JSON files. The `BibleService` will look for files in:
- `BibleData/niv/{bookId}/{chapter}.json`
- `BibleData/cuv/{bookId}/{chapter}.json`

## Troubleshooting

### Files Not Found Error
If you see "Bible file not found" errors:
1. Verify `BibleData` folder is in the app bundle:
   - Build the app
   - Right-click the `.app` in Products → "Show in Finder"
   - Right-click the `.app` → "Show Package Contents"
   - Check if `BibleData` folder exists

2. Check the path in `BibleService.swift` matches your folder structure

### Download Issues
If download fails or is incomplete:
```bash
# Re-run the download script
python3 scripts/download_bible_data.py
```

The script will skip already-downloaded files and continue from where it left off.

## JSON Format

Each chapter JSON file contains an array of verses:
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

This format matches what `BibleService` expects.

