# Adding BibleData from Outside Project

## Current Situation
✅ BibleData has been moved to: `/Users/yhuang10/Code/BibleData` (outside project)
✅ Old BibleData removed from project directory
❌ Need to add it back as folder reference in Xcode

## Steps to Add BibleData Reference

1. **Open Xcode**

2. **In Project Navigator**, delete any existing `BibleData` references:
   - Right-click → Delete → Move to Trash (if prompted)

3. **Right-click on PROJECT ROOT** (blue "livingdevotional" icon at top)
   - NOT the yellow folder
   - The project icon itself

4. **Select "Add Files to 'livingdevotional'..."**

5. **Navigate to the parent directory:**
   - Click "Go to Folder" or navigate up one level
   - Path: `/Users/yhuang10/Code/`
   - Select the `BibleData` folder

6. **IMPORTANT Settings:**
   - ✅ **"Create folder references"** - Select this (BLUE folder icon)
   - ❌ **"Copy items if needed"** - UNCHECK this (since it's outside project)
   - ✅ **"Add to targets: livingdevotional"** - Check this

7. **Click "Add"**

8. **Verify:**
   - `BibleData` appears in Project Navigator with BLUE folder icon
   - It shows the path as `../BibleData` or similar

9. **Clean and Build:**
   - **Product** → **Clean Build Folder** (⇧⌘K)
   - **Product** → **Build** (⌘B)

## Why This Works

- **Outside project**: Xcode 16's auto-sync won't pick it up
- **Folder reference**: Preserves structure (BibleData/bsb/GEN/1.json)
- **No copy**: References files in place, no duplication
- **No conflicts**: Files aren't in the synchronized folder

## Verification

After adding:
- [ ] BibleData appears with BLUE folder icon
- [ ] Build succeeds without "Multiple commands" errors  
- [ ] App runs and verses load correctly
- [ ] Files are accessible via Bundle.main.url()

## If Build Still Fails

If you still get errors:

1. **Check Build Phases:**
   - Target → Build Phases → Copy Bundle Resources
   - Remove any individual JSON files
   - Only `BibleData` folder should be listed

2. **Verify folder reference:**
   - Select BibleData in Project Navigator
   - File Inspector (⌥⌘1) should show it as a folder reference
   - Path should show `../BibleData` or absolute path

3. **Clean DerivedData:**
   - **Xcode** → **Settings** → **Locations**
   - Click arrow next to DerivedData
   - Delete `livingdevotional-*` folder
   - Rebuild

