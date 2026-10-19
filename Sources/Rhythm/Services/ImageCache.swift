import UIKit

class ImageCache {
    static let shared = ImageCache()
    
    private let cache = NSCache<NSString, UIImage>()
    
    private init() {
        cache.countLimit = 200
        cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
    }
    
    func image(for url: URL) async -> UIImage? {
        let key = url.absoluteString as NSString
        
        if let cached = cache.object(forKey: key) {
            return cached
        }
        
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let image = UIImage(data: data) else {
            return nil
        }
        
        cache.setObject(image, forKey: key)
        return image
    }
    
    func clearCache() {
        cache.removeAllObjects()
    }
}
