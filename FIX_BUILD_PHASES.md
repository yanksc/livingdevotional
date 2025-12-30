# Fixing "Multiple Commands Produce" Error in Build Phases

## Problem
Even with a folder reference, Xcode is still copying JSON files directly to the bundle root, causing filename conflicts.

## Solution: Exclude JSON Files from Direct Copy

The issue is that Xcode 16's auto-sync is still trying to copy individual JSON files. We need to exclude them from the "Copy Bundle Resources" build phase.

### Step-by-Step Fix:

1. **In Xcode, select your project** (blue icon at top)

2. **Select the "livingdevotional" target** (under TARGETS)

3. **Go to "Build Phases" tab**

4. **Expand "Copy Bundle Resources" section**

5. **Look for individual `.json` files** listed there
   - You might see files like `1.json`, `10.json`, etc.
   - Or you might see the `BibleData` folder listed

6. **If you see individual JSON files:**
   - Select all JSON files (⌘+Click to multi-select)
   - Press **Delete** or click the **-** button
   - Choose "Remove" when prompted

7. **If you see `BibleData` folder listed:**
   - Select it
   - Click the **-** button to remove it
   - We'll add it back correctly in step 8

8. **Add BibleData folder reference correctly:**
   - Click the **+** button in "Copy Bundle Resources"
   - Navigate to and select the **top-level `BibleData` folder** (blue folder)
   - Make sure it's added as a folder reference, not individual files

9. **Alternative: Use Build Settings Exclusion**
   - If the above doesn't work, we can exclude JSON files via build settings
   - See "Alternative Method" below

10. **Clean and Build:**
    - **Product** → **Clean Build Folder** (⇧⌘K)
    - **Product** → **Build** (⌘B)

## Alternative Method: Exclude via Build Settings

If removing from Build Phases doesn't work:

1. **Select project** → **Target "livingdevotional"** → **Build Settings**

2. **Search for**: `EXCLUDED_SOURCE_FILE_NAMES`

3. **Add pattern**: `*.json`

4. **Or search for**: `COPY_PHASE_STRIP` and related copy settings

5. **Clean and Build**

## Nuclear Option: Move BibleData Outside Project

If nothing works:

1. **Move BibleData outside the project folder:**
   ```bash
   mv livingdevotional/Resources/BibleData ../BibleData
   ```

2. **Remove old reference from Xcode**

3. **Add new reference** pointing to `../BibleData`

4. **Update code** if needed (Bundle path might change)

## Check Current Build Phases

To see what's currently being copied:

1. **Target** → **Build Phases** → **Copy Bundle Resources**
2. Look for:
   - Individual `.json` files → Remove them
   - `BibleData` folder → Should be there as folder reference only
   - Any duplicate entries → Remove duplicates

The folder reference should preserve structure, so files should be at:
`BibleData/bsb/GEN/1.json` not just `1.json` in bundle root.

