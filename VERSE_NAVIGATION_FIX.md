# Verse Navigation Fix Documentation

## Problem Summary

When navigating to saved verses from notes or other sources, two critical issues occurred:

1. **Near-end verse overscroll**: Navigating to verses near the end of a chapter (last 4 verses) would cause overscroll, making verses disappear and the bottom navbar hide
2. **Scroll position jumps**: After scrolling to any target verse, the view would switch from VStack (eager loading) to LazyVStack (lazy loading) after 0.5s, causing SwiftUI to recalculate layout and jump to a different verse

## Root Cause

### Issue 1: Near-End Verse Overscroll
- Using `.top` anchor for near-end verses caused scroll to push beyond available content
- Not enough verses below to fill screen → overscroll → layout breaks

### Issue 2: VStack→LazyVStack Transition
- After targeted scroll completes, `hasCompletedInitialScroll` becomes `true`
- This triggered switch from VStack (all verses rendered) to LazyVStack (only visible verses)
- LazyVStack recalculates layout → scroll position jumps to different verse

## Solution

### 1. Near-End Verse Handling (`isVerseNearEnd`)
- Detects if target verse is within last 4 verses of chapter
- For near-end verses: scrolls to **last verse** of chapter with `.bottom` anchor
- Ensures all verses including the last one are visible
- Prevents overscroll that causes UI glitches

### 2. Persistent Eager Loading (`usedNearEndScroll` flag)
- Renamed from `usedNearEndScroll` (misleading name kept for compatibility)
- Set to `true` for **ALL** targeted scrolls (not just near-end)
- Keeps VStack (eager loading) active permanently for that chapter
- Prevents VStack→LazyVStack switch that causes scroll jumps
- Resets when navigating to new chapter (`reloadVersesIfReady`)

## Code Changes

### Key State Variable
```swift
@State private var usedNearEndScroll: Bool = false // Track if we did any targeted scroll (keep eager loading)
```

### Eager Loading Logic
```swift
private var shouldUseEagerLoading: Bool {
    return (pendingScrollVerse != nil && !hasCompletedInitialScroll) || usedNearEndScroll
}
```

### Near-End Detection
```swift
private func isVerseNearEnd(_ verseNumber: Int) -> Bool {
    guard !viewModel.verses.isEmpty else { return false }
    let lastVerseNumber = viewModel.verses.last?.verseNumber ?? 0
    let threshold = 4 // Last 4 verses
    return verseNumber > (lastVerseNumber - threshold)
}
```

### Scroll Target Selection
```swift
if isNearEnd {
    // Scroll to LAST verse with bottom anchor
    if let lastVerse = viewModel.verses.last {
        scrollTargetId = lastVerse.id
        scrollAnchor = .bottom
    }
} else {
    // Normal: scroll target verse to top
    scrollTargetId = targetId
    scrollAnchor = .top
}
```

### Persistent Eager Loading
```swift
// Set flag for ANY targeted scroll (not just near-end)
self.usedNearEndScroll = true
```

## Trade-offs

### Performance
- **Before**: LazyVStack used after scroll complete → better memory for long chapters
- **After**: VStack kept active for chapters with targeted scrolls → slightly higher memory usage
- **Justification**: Memory impact minimal (few hundred verses max), user experience significantly improved

### When Resets
- Flag resets on chapter navigation via `reloadVersesIfReady()`
- If user manually navigates to same chapter without targeted scroll, still uses LazyVStack

## Future Maintenance

### If Chapter Loading Performance Becomes Issue
Consider hybrid approach:
1. Keep VStack for first N seconds after scroll
2. Transition to LazyVStack after delay (e.g., 5-10s)
3. Store final scroll position before transition
4. Restore exact position after transition

### If Near-End Threshold Needs Adjustment
- Current threshold: 4 verses from end
- Adjust `threshold` constant in `isVerseNearEnd()`
- Consider making it dynamic based on screen height

### Testing Checklist
- [ ] Navigate to verse 1-5 of any chapter → should scroll to top
- [ ] Navigate to middle verses → should scroll to top
- [ ] Navigate to last 4 verses → should scroll to chapter bottom with all verses visible
- [ ] Verify no scroll jumps after navigation completes
- [ ] Test on chapters with varying lengths (short: 5-10 vs long: 50+ verses)
- [ ] Verify memory usage acceptable for longest chapters (Psalm 119: 176 verses)

## Architecture Notes

### Why Not Use UIScrollView Directly?
SwiftUI's ScrollViewReader with proxy.scrollTo is the recommended approach for iOS 14+. Direct UIScrollView manipulation would require UIViewRepresentable wrapper and lose SwiftUI benefits.

### Why Not Store Scroll Position?
SwiftUI's scroll position API is less reliable than keeping consistent view hierarchy (VStack). Storing/restoring positions across VStack↔LazyVStack transitions proved fragile in testing.

### Related Components
- `BibleViewModel`: Manages `targetVerse` state
- `AppRouter`: Initiates navigation with verse target
- `ReadingViewModel`: Loads verse data
- `SavedNotesListView`: Triggers navigation from saved notes

## Version History
- **2026-01-13**: Initial fix implemented and documented
  - Fixed near-end verse overscroll
  - Fixed scroll position jumps for all verses
  - Removed debug instrumentation
