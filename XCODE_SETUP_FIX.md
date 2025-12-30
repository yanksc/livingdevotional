# Fixing Xcode Build Error: Multiple Commands Produce Same File

## Problem
Error: `Multiple commands produce '/Users/.../livingdevotional.app/1.json'`

This happens because Xcode is trying to copy all JSON files (like `1.json`, `2.json`, etc.) from different book folders to the same location in the app bundle, causing conflicts.

## Solution: Use Folder References (Blue Folder)

The BibleData folder must be added as a **folder reference** (blue folder icon) to preserve the folder structure, NOT as a group (yellow folder icon).

### Step-by-Step Fix

1. **Remove Existing BibleData Reference** (if already added):
   - In Xcode Project Navigator, find `BibleData` folder
   - Right-click → **Delete**
   - Choose **"Remove Reference"** (NOT "Move to Trash")

2. **Add BibleData as Folder Reference**:
   - Right-click on `livingdevotional` folder in Project Navigator
   - Select **"Add Files to 'livingdevotional'..."**
   - Navigate to `livingdevotional/Resources/BibleData`
   - **CRITICAL SETTINGS**:
     - ✅ Check **"Copy items if needed"**
     - ✅ Select **"Create folder references"** (BLUE folder icon, NOT yellow)
     - ✅ Check **"Add to targets: livingdevotional"**
   - Click **"Add"**

3. **Verify Folder Type**:
   - Select `BibleData` folder in Project Navigator
   - Look at the icon - it should be **BLUE** (folder reference)
   - If it's yellow, delete and re-add using step 2

4. **Clean Build Folder**:
   - In Xcode menu: **Product** → **Clean Build Folder** (⇧⌘K)
   - Or: **Product** → **Clean** (⌘K)

5. **Rebuild**:
   - **Product** → **Build** (⌘B)
   - The error should be resolved

## Alternative: Exclude from Build (If Above Doesn't Work)

If folder references don't work, you can exclude the files from direct copying:

1. Select `BibleData` folder in Project Navigator
2. Open **File Inspector** (⌥⌘1)
3. Under **Target Membership**, **UNCHECK** `livingdevotional`
4. The files won't be copied directly, but you'll need to load them differently

**Note**: This alternative requires code changes to load files from the app bundle differently.

## Verification

After fixing, verify:
1. Build succeeds without errors
2. Run app in simulator
3. Navigate to a book → chapter
4. Verses should load and display

## Why This Happens

- **Groups (Yellow)**: Xcode flattens the folder structure, copying all files to the same location
- **Folder References (Blue)**: Xcode preserves the folder structure, keeping files in their original locations

The BibleService code expects the folder structure to be preserved:
```
BibleData/
├── bsb/
│   ├── GEN/
│   │   ├── 1.json
│   │   └── 2.json
│   └── EXO/
│       └── 1.json
└── cuv/
    └── ...
```

This structure is only preserved with **folder references** (blue folders).

