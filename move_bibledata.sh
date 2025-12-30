#!/bin/bash
# Script to move BibleData outside project to fix Xcode 16 auto-sync issue

echo "=== Moving BibleData Outside Project ==="
echo ""

# Create destination
DEST="../BibleData"
mkdir -p "$DEST"

# Move from Resources if exists
if [ -d "livingdevotional/Resources/BibleData" ]; then
    echo "Moving from Resources/BibleData..."
    cp -r livingdevotional/Resources/BibleData/* "$DEST/" 2>/dev/null
    echo "✅ Copied from Resources"
fi

# Move from top-level if exists
if [ -d "BibleData" ] && [ ! -d "livingdevotional/Resources/BibleData" ]; then
    echo "Moving from top-level BibleData..."
    cp -r BibleData/* "$DEST/" 2>/dev/null
    echo "✅ Copied from top-level"
fi

# Verify
if [ -d "$DEST/bsb" ] && [ -d "$DEST/cuv" ]; then
    BSB_COUNT=$(find "$DEST/bsb" -name "*.json" | wc -l | tr -d ' ')
    CUV_COUNT=$(find "$DEST/cuv" -name "*.json" | wc -l | tr -d ' ')
    echo ""
    echo "✅ BibleData moved successfully!"
    echo "   Location: $(cd .. && pwd)/BibleData"
    echo "   BSB files: $BSB_COUNT"
    echo "   CUV files: $CUV_COUNT"
    echo ""
    echo "Next steps:"
    echo "1. In Xcode, delete old BibleData references"
    echo "2. Add new reference: Right-click project → Add Files → Select ../BibleData"
    echo "3. Choose 'Create folder references' (BLUE folder)"
    echo "4. UNCHECK 'Copy items if needed'"
    echo "5. Clean and Build"
else
    echo "❌ Error: BibleData structure not found in destination"
fi
