# Fixing Xcode 16 Build Error with Automatic File System Sync

## Problem
Xcode 16 uses `PBXFileSystemSynchronizedRootGroup` which automatically syncs all files in the `livingdevotional` folder. This causes the "Multiple commands produce 1.json" error because all JSON files are being copied to the bundle.

## Solution: Exclude BibleData from Auto-Sync

Since Xcode 16 automatically includes all files, we need to exclude `BibleData` from the automatic synchronization and add it separately as a folder reference.

### Option 1: Exclude via Xcode UI (Recommended)

1. **Open Xcode Project Navigator**
2. **Select the `livingdevotional` folder** (the synchronized root group)
3. **Open File Inspector** (⌥⌘1 - Option + Command + 1)
4. **Look for "Excluded Paths" or "Path Exceptions"** section
5. **Add exclusion pattern**: `Resources/BibleData/**`
   - Or add: `**/BibleData/**`
6. **Clean Build Folder** (⇧⌘K)
7. **Rebuild** (⌘B)

### Option 2: Add BibleData as Separate Folder Reference

1. **In Xcode Project Navigator**, right-click the project root
2. **Select "Add Files to 'livingdevotional'..."**
3. **Navigate to**: `livingdevotional/Resources/BibleData`
4. **IMPORTANT Settings**:
   - ✅ Check **"Copy items if needed"**
   - ✅ Select **"Create folder references"** (BLUE folder icon)
   - ✅ Check **"Add to targets: livingdevotional"**
   - ✅ Check **"Create groups"** is NOT selected
5. **Click "Add"**
6. **Verify**: BibleData appears as a BLUE folder (folder reference)
7. **Clean Build Folder** (⇧⌘K)
8. **Rebuild** (⌘B)

### Option 3: Move BibleData Outside Synchronized Folder

If the above doesn't work, move BibleData outside the synchronized folder:

1. **Move folder**:
   ```bash
   mv livingdevotional/Resources/BibleData ./BibleData
   ```

2. **Add as folder reference** (as in Option 2)

3. **Update code** if needed (the Bundle path should still work)

## Verify the Fix

After applying the fix:

1. **Build should succeed** without "Multiple commands" errors
2. **Check Project Navigator**: BibleData should be a BLUE folder (folder reference)
3. **Run app**: Verses should load correctly

## Why This Happens in Xcode 16

- **PBXFileSystemSynchronizedRootGroup**: Automatically includes ALL files in the folder
- **Problem**: All `1.json` files from different books get copied to the same bundle location
- **Solution**: Exclude from auto-sync OR add as separate folder reference that preserves structure

## Alternative: Configure Build Phases

If exclusion doesn't work, you can also:

1. **Select project** → **Target "livingdevotional"** → **Build Phases**
2. **Expand "Copy Bundle Resources"**
3. **Remove all individual JSON files** (they shouldn't be there if using folder reference)
4. **Ensure only the BibleData folder reference** is listed (if at all)

The folder reference approach preserves the structure: `BibleData/bsb/GEN/1.json` stays separate from `BibleData/bsb/EXO/1.json`.

