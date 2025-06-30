//
//  VideoCacheManager.swift
//  DualCamera
//
//  Created by Admin on 30/06/25.
//

import Foundation
import Foundation
import UIKit

class VideoCacheManager {
    static let shared = VideoCacheManager()
    private init() {
        setupCache()
    }
    
    private let cache = NSCache<NSString, NSData>()
    private let cacheQueue = DispatchQueue(label: "video.cache.manager", qos: .utility)
    
    private func setupCache() {
        cache.countLimit = 50 // Cache up to 50 video thumbnails
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB limit
        
        // Clear cache when app receives memory warning
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.clearCache()
        }
    }
    
    func cacheData(_ data: Data, forKey key: String) {
        cacheQueue.async {
            self.cache.setObject(data as NSData, forKey: key as NSString)
        }
    }
    
    func cachedData(forKey key: String) -> Data? {
        return cache.object(forKey: key as NSString) as Data?
    }
    
    func clearCache() {
        cacheQueue.async {
            self.cache.removeAllObjects()
            print("🗑️ Video cache cleared")
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
