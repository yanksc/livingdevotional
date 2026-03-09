// SereneBackgroundManager - Manages random selection of serene background images from bg_serene folder
// Ensures no duplicates within a session and provides persistent selection for reading plans

import SwiftUI
import ImageIO

// MARK: - Image Cache for Performance

/// Thread-safe image cache using NSCache
final class SereneImageCache {
    static let shared = SereneImageCache()
    
    private let cache = NSCache<NSString, UIImage>()
    private let loadingQueue = DispatchQueue(label: "com.livingdevotional.imageLoading", qos: .userInitiated, attributes: .concurrent)
    private var loadingTasks: [String: Bool] = [:]
    private let taskLock = NSLock()
    
    private init() {
        // Configure cache limits
        cache.countLimit = 50 // Max 50 images
        cache.totalCostLimit = 50 * 1024 * 1024 // ~50MB
    }
    
    /// Get cached image for filename
    func image(for filename: String) -> UIImage? {
        return cache.object(forKey: filename as NSString)
    }
    
    /// Store image in cache
    func store(_ image: UIImage, for filename: String) {
        let cost = Int(image.size.width * image.size.height * 4) // Approximate memory cost
        cache.setObject(image, forKey: filename as NSString, cost: cost)
    }
    
    /// Check if already loading this image
    func isLoading(_ filename: String) -> Bool {
        taskLock.lock()
        defer { taskLock.unlock() }
        return loadingTasks[filename] == true
    }
    
    /// Mark image as loading/not loading
    func setLoading(_ filename: String, _ isLoading: Bool) {
        taskLock.lock()
        defer { taskLock.unlock() }
        if isLoading {
            loadingTasks[filename] = true
        } else {
            loadingTasks.removeValue(forKey: filename)
        }
    }
    
    /// Load image asynchronously with downsampling for small card sizes (async/await version)
    func loadImageAsync(filename: String, targetSize: CGSize = CGSize(width: 320, height: 360)) async -> UIImage? {
        // Check cache first
        if let cached = image(for: filename) {
            return cached
        }
        
        // Load on background thread
        return await withCheckedContinuation { continuation in
            loadingQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: nil)
                    return
                }
                
                // Try to load from bg_serene folder with downsampling
                let loadedImage = self.loadDownsampledImage(named: filename, targetSize: targetSize)
                
                if let image = loadedImage {
                    self.store(image, for: filename)
                }
                
                continuation.resume(returning: loadedImage)
            }
        }
    }
    
    /// Load image asynchronously with completion handler (for preloading)
    func loadImageWithCompletion(filename: String, targetSize: CGSize = CGSize(width: 320, height: 360), completion: @escaping (UIImage?) -> Void) {
        // Check cache first
        if let cached = image(for: filename) {
            completion(cached)
            return
        }
        
        // Prevent duplicate loading
        if isLoading(filename) {
            return
        }
        setLoading(filename, true)
        
        loadingQueue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            // Try to load from bg_serene folder with downsampling
            let loadedImage = self.loadDownsampledImage(named: filename, targetSize: targetSize)
            
            DispatchQueue.main.async {
                self.setLoading(filename, false)
                if let image = loadedImage {
                    self.store(image, for: filename)
                }
                completion(loadedImage)
            }
        }
    }
    
    /// Load and downsample image for better performance
    private func loadDownsampledImage(named filename: String, targetSize: CGSize) -> UIImage? {
        // Find the file path
        var filePath: String? = nil
        
        if let path = Bundle.main.path(forResource: filename, ofType: nil, inDirectory: "bg_serene") {
            filePath = path
        } else if let path = Bundle.main.path(forResource: filename, ofType: nil) {
            filePath = path
        }
        
        guard let path = filePath else {
            #if DEBUG
            print("SereneImageCache: Could not find file: \(filename)")
            #endif
            return nil
        }
        
        let url = URL(fileURLWithPath: path)
        
        // Try ImageIO for efficient downsampled loading
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        if let imageSource = CGImageSourceCreateWithURL(url as CFURL, imageSourceOptions) {
            // Calculate the scale factor for downsampling
            let scale = UIScreen.main.scale
            let maxDimensionInPixels = max(targetSize.width, targetSize.height) * scale
            
            let downsampleOptions = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
            ] as CFDictionary
            
            if let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) {
                return UIImage(cgImage: downsampledImage)
            }
        }
        
        // Fallback: Load full image and resize manually (works better with AVIF)
        if let fullImage = UIImage(contentsOfFile: path) {
            return resizeImage(fullImage, targetSize: targetSize)
        }
        
        return nil
    }
    
    /// Resize image to target size for memory efficiency
    private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        guard image.size.width > 0, image.size.height > 0 else { return image }
        
        let scale = UIScreen.main.scale
        let scaledSize = CGSize(width: targetSize.width * scale, height: targetSize.height * scale)
        
        // Calculate aspect-fill size
        let widthRatio = scaledSize.width / image.size.width
        let heightRatio = scaledSize.height / image.size.height
        let ratio = max(widthRatio, heightRatio)
        
        let newSize = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    /// Preload multiple images for visible cards
    func preloadImages(filenames: [String], targetSize: CGSize = CGSize(width: 320, height: 360)) {
        for filename in filenames {
            if image(for: filename) == nil && !isLoading(filename) {
                loadImageWithCompletion(filename: filename, targetSize: targetSize) { _ in }
            }
        }
    }
}

class SereneBackgroundManager: ObservableObject {
    static let shared = SereneBackgroundManager()
    
    private let userDefaults = UserDefaults.standard
    private let planBackgroundsKey = "planBackgroundAssignments"
    private let usedBackgroundsKey = "usedBackgroundIndices"
    
    // All available serene background filenames from bg_serene folder
    private let allBackgrounds: [String] = [
        // Original avif set
        "photo-1435224654926-ecc9f7fa028c.avif",
        "photo-1444791252404-500e5b11f71b.avif",
        "photo-1465173121987-373740a169b3.avif",
        "photo-1472396961693-142e6e269027.avif",
        "photo-1474540412665-1cdae210ae6b.avif",
        "photo-1477840539360-4a1d23071046.avif",
        "photo-1483354483454-4cd359948304.avif",
        "photo-1491929536571-bdbc57e72324.avif",
        "photo-1493815793585-d94ccbc86df8.avif",
        "photo-1499980762202-04245017d5bf.avif",
        "photo-1500534314209-a25ddb2bd429.avif",
        "photo-1503435980610-a51f3ddfee50.avif",
        "photo-1503891617560-5b8c2e28cbf6.avif",
        "photo-1504608524841-42fe6f032b4b.avif",
        "photo-1504893524553-b855bce32c67.avif",
        "photo-1505142468610-359e7d316be0.avif",
        "photo-1505533542167-8c89838bb19e.avif",
        "photo-1506744038136-46273834b3fb.avif",
        "photo-1513836279014-a89f7a76ae86.avif",
        "photo-1514810771018-276192729582.avif",
        "photo-1514975440715-7b6852af4ee7.avif",
        "photo-1516461238104-007b441a08ae.avif",
        "photo-1516676839530-135a545cce02.avif",
        "photo-1517664604184-9c1d2962d0a6.avif",
        "photo-1518889735218-3e3a03fd3128.avif",
        "photo-1522143804971-93c748148fbd.avif",
        "photo-1525838983331-f8bd3c000585.avif",
        "photo-1529419412599-7bb870e11810.avif",
        "photo-1541296434114-65d3360d5772.avif",
        "photo-1541831405157-453bbfdc8c3e.avif",
        "photo-1584358838337-8f86d1b3922e.avif",
        "photo-1586348943529-beaae6c28db9.avif",
        "photo-1592677298363-c2586b8cafde.avif",
        "photo-1603729287771-e03b8ac6ebf5.avif",
        "photo-1615729947596-a598e5de0ab3.avif",
        // New Unsplash additions
        "aaron-burden-09AhDCedXF8-unsplash.jpg",
        "alexander-grey-SavQfLRm4Do-unsplash.jpg",
        "ann-savchenko-yOQntxCp0r0-unsplash.jpg",
        "colin-lloyd-V72xxgvew-A-unsplash.jpg",
        "daniel-angele-Joo3UBw789Q-unsplash.jpg",
        "heriberto-garcia-YdjrYLvLO5Y-unsplash.jpg",
        "jakub-kriz-4r_tHA3gsUY-unsplash.jpg",
        "kalen-emsley-Bkci_8qcdvQ-unsplash.jpg",
        "katie-moum-5FHv5nS7yGg-unsplash.jpg",
        "lukasz-szmigiel-jFCViYFYcus-unsplash.jpg",
        "luke-richardson-dI7vfR1Bqcg-unsplash.jpg",
        "mark-basarab-z8ct_Q3oCqM-unsplash.jpg",
        "nic-y-c-WzazSaQF1F8-unsplash.jpg",
        "vinicius-henrique-photography-oQ-Dw_2SMUM-unsplash.jpg",
        "yoal-desurmont-9CjgeMAM2SI-unsplash.jpg"
    ]
    
    // Shuffled backgrounds for the current session (for category cards)
    @Published private(set) var shuffledBackgrounds: [String] = []
    
    // Persistent background for journey card (changes on app restart)
    @Published private(set) var journeyBackground: String = ""
    
    // Persistent mapping of plan IDs to background filenames
    @Published private(set) var planBackgrounds: [String: String] = [:]
    
    // Track indices of backgrounds already assigned to plans
    private var usedBackgroundIndices: Set<Int> = []
    
    private init() {
        loadPlanBackgrounds()
        loadUsedBackgrounds()
        shuffleBackgrounds()
        selectJourneyBackground()
    }
    
    // MARK: - Session Backgrounds (for category cards)
    
    /// Shuffle backgrounds for a new session
    func shuffleBackgrounds() {
        shuffledBackgrounds = allBackgrounds.shuffled()
    }
    
    /// Select a random background for the journey view
    private func selectJourneyBackground() {
        journeyBackground = allBackgrounds.randomElement() ?? "photo-1506744038136-46273834b3fb.avif"
    }
    
    /// Get a background for a specific index (wraps around if needed)
    /// Use this to assign non-repeating backgrounds to category cards
    func background(at index: Int) -> String {
        guard !shuffledBackgrounds.isEmpty else {
            return allBackgrounds.randomElement() ?? "photo-1506744038136-46273834b3fb.avif"
        }
        let safeIndex = index % shuffledBackgrounds.count
        return shuffledBackgrounds[safeIndex]
    }
    
    /// Get total count of available backgrounds
    var count: Int {
        return allBackgrounds.count
    }
    
    /// Get a random background (may repeat)
    func randomBackground() -> String {
        return allBackgrounds.randomElement() ?? "photo-1506744038136-46273834b3fb.avif"
    }
    
    // MARK: - Plan Backgrounds (persistent, non-repeating)
    
    /// Get or assign a unique background for a reading plan
    /// Once assigned, the same background will always be returned for that plan ID
    func backgroundForPlan(planId: String) -> String {
        // Return existing assignment if available
        if let existing = planBackgrounds[planId] {
            return existing
        }
        
        // Assign a new unique background
        let background = assignUniqueBackground(for: planId)
        return background
    }
    
    /// Assign a unique background that hasn't been used by other plans
    private func assignUniqueBackground(for planId: String) -> String {
        // Find available indices (not yet used)
        let availableIndices = Set(0..<allBackgrounds.count).subtracting(usedBackgroundIndices)
        
        let selectedIndex: Int
        if availableIndices.isEmpty {
            // All backgrounds used, reset and start over (but pick different from recent)
            usedBackgroundIndices.removeAll()
            selectedIndex = Int.random(in: 0..<allBackgrounds.count)
        } else {
            // Pick randomly from available
            selectedIndex = availableIndices.randomElement() ?? 0
        }
        
        // Mark as used and save
        usedBackgroundIndices.insert(selectedIndex)
        let background = allBackgrounds[selectedIndex]
        planBackgrounds[planId] = background
        
        savePlanBackgrounds()
        saveUsedBackgrounds()
        
        return background
    }
    
    /// Remove a plan's background assignment (when plan is deleted)
    func removePlanBackground(for planId: String) {
        if let background = planBackgrounds[planId],
           let index = allBackgrounds.firstIndex(of: background) {
            usedBackgroundIndices.remove(index)
        }
        planBackgrounds.removeValue(forKey: planId)
        savePlanBackgrounds()
        saveUsedBackgrounds()
    }
    
    // MARK: - Persistence
    
    private func loadPlanBackgrounds() {
        if let data = userDefaults.data(forKey: planBackgroundsKey),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            planBackgrounds = decoded
        }
    }
    
    private func savePlanBackgrounds() {
        if let encoded = try? JSONEncoder().encode(planBackgrounds) {
            userDefaults.set(encoded, forKey: planBackgroundsKey)
        }
    }
    
    private func loadUsedBackgrounds() {
        if let data = userDefaults.data(forKey: usedBackgroundsKey),
           let decoded = try? JSONDecoder().decode([Int].self, from: data) {
            usedBackgroundIndices = Set(decoded)
        }
    }
    
    private func saveUsedBackgrounds() {
        if let encoded = try? JSONEncoder().encode(Array(usedBackgroundIndices)) {
            userDefaults.set(encoded, forKey: usedBackgroundsKey)
        }
    }
    
    // MARK: - Image Loading Helper
    
    /// Load a UIImage from the bg_serene folder in the bundle
    static func loadImage(named filename: String) -> UIImage? {
        // Try to load from bg_serene folder in bundle
        if let path = Bundle.main.path(forResource: filename, ofType: nil, inDirectory: "bg_serene") {
            return UIImage(contentsOfFile: path)
        }
        
        // Fallback: try without directory
        if let path = Bundle.main.path(forResource: filename, ofType: nil) {
            return UIImage(contentsOfFile: path)
        }
        
        return nil
    }
    
    // MARK: - Preloading for ExploreView
    
    /// Preload images for visible cards in ExploreView to eliminate loading delay
    /// Call this when ExploreView appears
    func preloadExploreViewImages(categoryCount: Int, planIds: [String]) {
        var filenames: [String] = []
        
        // Get backgrounds for category cards (including "Ask Any Question" at index 0)
        for i in 0..<(categoryCount + 2) { // +1 for AskAnyQuestion, +1 for CreatePersonalizedPlan
            filenames.append(background(at: i))
        }
        
        // Get backgrounds for reading plan cards
        for planId in planIds {
            filenames.append(backgroundForPlan(planId: planId))
        }
        
        // Preload all images
        SereneImageCache.shared.preloadImages(filenames: filenames)
    }
}

// MARK: - SwiftUI View Extension for Serene Backgrounds

extension View {
    /// Apply a serene background with gradient overlay for text readability
    func sereneBackground(_ imageName: String, overlayOpacity: Double = 0.5) -> some View {
        self.background(
            ZStack {
                SereneBackgroundImage(filename: imageName)
                
                // Gradient overlay for text readability
                LinearGradient(
                    colors: [
                        Color.black.opacity(overlayOpacity),
                        Color.black.opacity(overlayOpacity * 0.6),
                        Color.black.opacity(overlayOpacity)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        )
    }
}

// MARK: - Image Loader Observable Class

/// Observable class to handle async image loading with proper SwiftUI state management
@MainActor
final class SereneImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var loadAttempted: Bool = false
    
    private var filename: String = ""
    private var targetSize: CGSize = CGSize(width: 320, height: 360)
    
    func load(filename: String, targetSize: CGSize) {
        // Skip if already loaded this file
        if self.filename == filename && (image != nil || loadAttempted) {
            return
        }
        
        self.filename = filename
        self.targetSize = targetSize
        
        // Check cache first (synchronous, fast)
        if let cached = SereneImageCache.shared.image(for: filename) {
            self.image = cached
            self.loadAttempted = true
            return
        }
        
        // Load asynchronously
        Task {
            let loadedImage = await SereneImageCache.shared.loadImageAsync(filename: filename, targetSize: targetSize)
            self.image = loadedImage
            self.loadAttempted = true
        }
    }
}

// MARK: - Serene Background Image View

/// A view that loads and displays an image from the bg_serene folder
/// Optimized with caching, async loading, and downsampling for small card sizes
struct SereneBackgroundImage: View {
    let filename: String
    var targetSize: CGSize = CGSize(width: 320, height: 360) // 2x for 160x180 cards
    
    @StateObject private var loader = SereneImageLoader()
    
    // Fallback asset names from SereneBackgrounds in Asset catalog
    private static let fallbackAssets = [
        "SereneBackground1",
        "SereneBackground2",
        "SereneBackground3",
        "SereneBackground4",
        "SereneBackground5",
        "SereneBackground6"
    ]
    
    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
            } else if loader.loadAttempted {
                // Use a fallback from asset catalog based on filename hash
                Image(fallbackAssetName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
            } else {
                // Placeholder while loading - subtle gradient instead of solid color
                LinearGradient(
                    colors: [
                        Color.gray.opacity(0.2),
                        Color.gray.opacity(0.15)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .onAppear {
            loader.load(filename: filename, targetSize: targetSize)
        }
    }
    
    private var fallbackAssetName: String {
        // Use filename hash to consistently pick a fallback
        let hash = abs(filename.hashValue)
        let index = hash % Self.fallbackAssets.count
        return Self.fallbackAssets[index]
    }
}
