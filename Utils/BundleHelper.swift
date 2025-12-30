// BundleHelper - Utility for checking bundle resources

import Foundation

enum BundleHelper {
    /// Check if BibleData.bundle exists in the app bundle
    static func verifyBibleDataExists() -> Bool {
        return Bundle.main.url(forResource: "BibleData", withExtension: "bundle") != nil
    }
    
    /// List available translations in the bundle
    static func availableTranslations() -> [String] {
        guard let bundleUrl = Bundle.main.url(forResource: "BibleData", withExtension: "bundle"),
              let bibleBundle = Bundle(url: bundleUrl),
              let contents = try? FileManager.default.contentsOfDirectory(atPath: bibleBundle.bundlePath) else {
            return []
        }
        
        return contents.filter { item in
            let itemPath = (bibleBundle.bundlePath as NSString).appendingPathComponent(item)
            var isDirectory: ObjCBool = false
            FileManager.default.fileExists(atPath: itemPath, isDirectory: &isDirectory)
            return isDirectory.boolValue
        }
    }
    
    /// Debug: Print bundle structure for troubleshooting
    static func debugBundleStructure() {
        print("=== Bundle Structure Debug ===")
        print("Bundle path: \(Bundle.main.bundlePath)")
        
        if let resourcePath = Bundle.main.resourcePath {
            print("Resource path: \(resourcePath)")
            
            let fileManager = FileManager.default
            if let contents = try? fileManager.contentsOfDirectory(atPath: resourcePath) {
                print("Top-level resources: \(contents.prefix(10))")
            }
        }
        
        let translations = availableTranslations()
        print("Available translations: \(translations)")
        print("BibleData exists: \(verifyBibleDataExists())")
        print("=============================")
    }
}

