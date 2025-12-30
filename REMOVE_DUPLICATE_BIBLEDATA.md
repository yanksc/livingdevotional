# Removing Duplicate BibleData Folder

## Current Situation
You have TWO BibleData folders:
1. **Top-level BibleData** (blue folder icon) - ✅ KEEP THIS ONE (folder reference)
2. **livingdevotional/Resources/BibleData** (inside auto-synced folder) - ❌ REMOVE THIS ONE

## Steps to Remove the Duplicate

### Option 1: Remove Reference Only (Recommended)

1. **In Xcode Project Navigator**, find `livingdevotional/Resources/BibleData`
   - It's inside the yellow `livingdevotional` folder
   - Inside `Resources` folder

2. **Right-click on `BibleData`** (the one inside Resources)

3. **Select "Delete"**

4. **In the dialog that appears, choose:**
   - ✅ **"Remove Reference"** (NOT "Move to Trash")
   - This removes it from Xcode but keeps files on disk

5. **Verify:**
   - Only the top-level `BibleData` (blue folder) should remain
   - The one inside Resources should be gone from Project Navigator

6. **Clean and Build:**
   - **Product** → **Clean Build Folder** (⇧⌘K)
   - **Product** → **Build** (⌘B)

### Option 2: Move Files (If Option 1 Doesn't Work)

If removing the reference doesn't work, you can move the files:

1. **In Finder**, move the BibleData folder:
   ```bash
   # The files are already in the right place
   # Just remove the Xcode reference as in Option 1
   ```

2. The top-level BibleData folder reference should point to the same files

## Why This Works

- **Top-level BibleData** (blue folder reference):
  - Preserves folder structure
  - No filename conflicts
  - Properly included in bundle

- **Resources/BibleData** (inside auto-synced folder):
  - Gets auto-synced by Xcode 16
  - Causes "Multiple commands" errors
  - Should be removed from project

## Verification

After removing:

- [ ] Only ONE BibleData folder in Project Navigator (top-level, blue)
- [ ] No BibleData inside Resources folder in Project Navigator
- [ ] Build succeeds without errors
- [ ] App runs and verses load correctly

## Important Note

**Don't delete the actual files from disk!** Only remove the Xcode reference. The files at `livingdevotional/Resources/BibleData/` can stay on disk - they just shouldn't be referenced by Xcode. The top-level folder reference will handle including them in the bundle.

