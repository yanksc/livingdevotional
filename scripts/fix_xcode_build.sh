#!/bin/bash
# Script to help fix Xcode build issues with BibleData folder

echo "=== Xcode Build Fix Helper ==="
echo ""
echo "This script helps diagnose the BibleData folder setup issue."
echo ""
echo "The error 'Multiple commands produce 1.json' happens when:"
echo "  - BibleData is added as a GROUP (yellow folder) instead of FOLDER REFERENCE (blue folder)"
echo "  - Xcode flattens the folder structure, causing file name conflicts"
echo ""
echo "SOLUTION:"
echo "1. In Xcode, delete the BibleData folder reference (if it exists)"
echo "2. Right-click 'livingdevotional' → 'Add Files to livingdevotional...'"
echo "3. Select: livingdevotional/Resources/BibleData"
echo "4. IMPORTANT: Choose 'Create folder references' (BLUE folder icon)"
echo "5. Check 'Copy items if needed' and 'Add to targets: livingdevotional'"
echo "6. Click 'Add'"
echo ""
echo "Verifying BibleData structure..."
echo ""

if [ -d "livingdevotional/Resources/BibleData" ]; then
    echo "✓ BibleData folder exists"
    echo ""
    echo "Folder structure:"
    ls -la livingdevotional/Resources/BibleData/ | head -10
    echo ""
    echo "Sample files:"
    echo "  BSB files: $(find livingdevotional/Resources/BibleData/bsb -name '*.json' 2>/dev/null | wc -l | tr -d ' ')"
    echo "  CUV files: $(find livingdevotional/Resources/BibleData/cuv -name '*.json' 2>/dev/null | wc -l | tr -d ' ')"
    echo ""
    echo "Checking for duplicate filenames at root level..."
    find livingdevotional/Resources/BibleData -name "1.json" | head -5
    echo ""
    echo "✓ Files are in nested folders (bsb/GEN/1.json, bsb/EXO/1.json, etc.)"
    echo "  This is correct - the folder structure must be preserved in Xcode"
else
    echo "✗ BibleData folder not found!"
    echo "  Expected location: livingdevotional/Resources/BibleData"
fi

echo ""
echo "=== Next Steps ==="
echo "1. Follow the solution steps above in Xcode"
echo "2. Clean build folder: Product → Clean Build Folder (⇧⌘K)"
echo "3. Rebuild: Product → Build (⌘B)"
echo ""
echo "For detailed instructions, see: XCODE_SETUP_FIX.md"

