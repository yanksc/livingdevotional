# Final Fix for Xcode 16 "Multiple Commands" Error

## Root Cause
Xcode 16's `PBXFileSystemSynchronizedRootGroup` automatically syncs ALL files in the `livingdevotional` folder, including JSON files in `BibleData`. Even with a folder reference, Xcode is trying to copy files in multiple ways.

## Solution: Exclude BibleData from Auto-Sync

Since Xcode 16 doesn't support exclusions in the UI for synchronized groups, we need to either:
1. Move BibleData outside the synchronized folder, OR
2. Configure Build Phases to exclude JSON files

### Method 1: Move BibleData Outside Project Folder (Recommended)

1. **Close Xcode**

2. **Move BibleData outside the project:**
   ```bash
   cd /Users/yhuang10/Code/livingdevotional
   mv livingdevotional/Resources/BibleData ../BibleData
   # Or move top-level if it exists:
   mv BibleData ../BibleData  # if top-level exists
   ```

3. **Open Xcode**

4. **Remove old BibleData references:**
   - Delete any BibleData folders from Project Navigator
   - Choose "Move to Trash" (files are already moved)

5. **Add BibleData from new location:**
   - Right-click project root → "Add Files to 'livingdevotional'..."
   - Navigate to `../BibleData` (parent directory)
   - Select BibleData folder
   - Check "Create folder references" (BLUE folder)
   - Check "Add to targets: livingdevotional"
   - **UNCHECK "Copy items if needed"** (since it's outside project)

6. **Update code if needed** (should work as-is)

7. **Clean and Build**

### Method 2: Exclude via Build Phases

1. **Select project** → **Target "livingdevotional"** → **Build Phases**

2. **Expand "Copy Bundle Resources"**

3. **Look for individual JSON files or BibleData entries**

4. **Remove any individual JSON files** (they shouldn't be there)

5. **If BibleData folder is listed**, remove it and re-add as folder reference

6. **Clean and Build**

### Method 3: Add to .gitignore and Exclude Pattern

1. **Create/update `.xcode-exclude` file** (if Xcode supports it)

2. **Or manually edit project.pbxproj** to add exceptions:
   ```pbxproj
   62CB97182F0267DE00A2C3D1 /* livingdevotional */ = {
       isa = PBXFileSystemSynchronizedRootGroup;
       path = livingdevotional;
       sourceTree = "<group>";
       exceptions = (
           "Resources/BibleData/**",
           "**/BibleData/**",
       );
   };
   ```

   **⚠️ Warning**: Manual editing can break project. Close Xcode first!

## Quick Fix Script

Run this to move BibleData outside:

```bash
cd /Users/yhuang10/Code/livingdevotional

# Backup first
cp -r livingdevotional/Resources/BibleData ~/Desktop/BibleData_backup 2>/dev/null || true
cp -r BibleData ~/Desktop/BibleData_backup 2>/dev/null || true

# Move outside project (choose one location)
mkdir -p ../BibleData
mv livingdevotional/Resources/BibleData/* ../BibleData/ 2>/dev/null || true
mv BibleData/* ../BibleData/ 2>/dev/null || true

# Remove old locations
rm -rf livingdevotional/Resources/BibleData
rm -rf BibleData

echo "BibleData moved to: $(pwd)/../BibleData"
echo "Now add it as folder reference in Xcode from: ../BibleData"
```

## Verification

After fixing:
- [ ] No BibleData inside `livingdevotional/` folder
- [ ] BibleData exists outside project (or as separate reference)
- [ ] Build succeeds without "Multiple commands" errors
- [ ] App runs and verses load

