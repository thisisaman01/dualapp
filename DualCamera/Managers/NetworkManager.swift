//
//  NetworkManager.swift
//  DualCamera
//
//  Created by Admin on 26/06/25.
//

import Foundation
import UIKit

class NetworkManager {
    static let shared = NetworkManager()
    private init() {
        preGenerateVideoCache()
    }
    
    // Cache for instant access
    private var videoCache: [VideoItem] = []
    private let cacheQueue = DispatchQueue(label: "video.cache.queue", qos: .userInitiated)
    
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5.0
        config.timeoutIntervalForResource = 15.0
        config.urlCache = URLCache(
            memoryCapacity: 100 * 1024 * 1024,
            diskCapacity: 200 * 1024 * 1024,
            diskPath: "video_cache"
        )
        config.requestCachePolicy = .returnCacheDataElseLoad
        return URLSession(configuration: config)
    }()
    
    func fetchJellyVideos(completion: @escaping (Result<[VideoItem], Error>) -> Void) {
        print("🚀 Fetching video feed (optimized)...")
        
        if !videoCache.isEmpty {
            print("⚡ Returning cached videos instantly!")
            completion(.success(videoCache))
            return
        }
        
        cacheQueue.async {
            let videos = self.generateOptimizedVideoFeed()
            self.videoCache = videos
            
            DispatchQueue.main.async {
                print("✅ Generated \(videos.count) videos in background")
                completion(.success(videos))
            }
        }
    }
    
    private func preGenerateVideoCache() {
        cacheQueue.async {
            self.videoCache = self.generateOptimizedVideoFeed()
            print("🎯 Video cache pre-generated with \(self.videoCache.count) videos")
        }
    }
    
    func refreshVideoFeed(completion: @escaping (Result<[VideoItem], Error>) -> Void) {
        print("🔄 Refreshing video feed...")
        
        cacheQueue.async {
            var refreshedVideos = self.videoCache.shuffled()
            
            let newVideos = self.generateNewVideos(count: 5)
            refreshedVideos.insert(contentsOf: newVideos, at: 0)
            
            if refreshedVideos.count > 25 {
                refreshedVideos = Array(refreshedVideos.prefix(25))
            }
            
            self.videoCache = refreshedVideos
            
            DispatchQueue.main.async {
                print("✅ Refreshed feed with \(refreshedVideos.count) videos")
                completion(.success(refreshedVideos))
            }
        }
    }
    
    private func generateOptimizedVideoFeed() -> [VideoItem] {
        let superFastVideoURLs = [
            "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_adv_example_hevc/master.m3u8",
            "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/master.m3u8",
            
            "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
            "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
            "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
            "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4",
            "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4",
            "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4",
            "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4",
            "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4",
            "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackOnStreetAndDirt.mp4",
            "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4",
            
            "https://archive.org/download/SampleVideo1280x7205mb/SampleVideo_1280x720_5mb.mp4",
            "https://archive.org/download/SampleVideo1280x7201mb/SampleVideo_1280x720_1mb.mp4",
            
            "https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4",
            "https://sample-videos.com/zip/10/mp4/SampleVideo_640x360_1mb.mp4",
            
            "https://www.learningcontainer.com/wp-content/uploads/2020/05/sample-mp4-file.mp4",
            "https://filesamples.com/samples/video/mp4/SampleVideo_1280x720_1mb.mp4",
            
            "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/VolkswagenGTIReview.mp4",
            "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WeAreGoingOnBullrun.mp4"
        ]
        
        let titles = [
            "🎬 Amazing Dual POV Adventure",
            "✨ Creative Storytelling Magic",
            "🎭 Behind the Scenes Moments",
            "🌍 Epic Travel Journey",
            "👨‍🍳 Cooking Masterclass",
            "💃 Dance Challenge Viral",
            "📱 Tech Review & Tips",
            "💪 Fitness Motivation Daily",
            "🎨 Art Creation Process",
            "🎵 Music Production Studio",
            "😂 Comedy Sketch Gold",
            "🌿 Nature Documentary",
            "📸 Street Photography Walk",
            "🎮 Gaming Highlights Reel",
            "🏠 DIY Home Projects",
            "👗 Fashion Style Guide",
            "🐕 Pet Training Tips",
            "🍳 Food Recipe Quick",
            "🏋️ Workout Routine Home",
            "📚 Study Tips & Tricks"
        ]
        
        let creators = [
            "@CreativeGenius", "@TechExplorer", "@ArtisticSoul",
            "@AdventureSeeker", "@FoodieFinds", "@FitnessGuru",
            "@MusicMaker", "@ComedyCentral", "@NatureLover",
            "@StyleIcon", "@PetWhisperer", "@StudyBuddy",
            "@TravelDiaries", "@CookingMaster", "@DanceMoves",
            "@PhotoPro", "@GameChanger", "@DIYExpert",
            "@FashionForward", "@LifeHacker"
        ]
        
        let hashtags = [
            "#trending #viral #fyp",
            "#creative #art #amazing",
            "#tech #review #tips",
            "#fitness #motivation #workout",
            "#food #cooking #recipe",
            "#travel #adventure #explore",
            "#comedy #funny #viral",
            "#music #producer #beats",
            "#photography #tips #camera",
            "#gaming #highlights #epic"
        ]
        
        // Generate 20 video items with optimized data
        return (0..<20).map { index in
            let urlIndex = index % superFastVideoURLs.count
            let videoURL = superFastVideoURLs[urlIndex]
            
            return VideoItem(
                id: "video_\(index)_\(Date().timeIntervalSince1970)",
                videoURL: videoURL,
                thumbnailURL: generateOptimizedThumbnailURL(for: index),
                title: titles[index % titles.count],
                creator: creators[index % creators.count],
                duration: [15, 30, 45, 60, 90, 120][index % 6], // Predefined durations
                createdAt: Date().addingTimeInterval(-Double(index * 3600)), // Staggered by hours
                viewCount: generateRealisticViewCount(for: index),
                likeCount: generateRealisticLikeCount(for: index),
                hashtags: hashtags[index % hashtags.count]
            )
        }
    }
    
    private func generateNewVideos(count: Int) -> [VideoItem] {
        let newVideoURLs = [
            "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
            "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
            "https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4"
        ]
        
        let newTitles = [
            "🔥 Just Dropped: Epic Collab",
            "⚡ Breaking: Viral Moment",
            "🎯 Trending Now: Must Watch",
            "🆕 Fresh Content Alert",
            "🌟 Creator Spotlight"
        ]
        
        return (0..<count).map { index in
            VideoItem(
                id: "new_video_\(index)_\(Date().timeIntervalSince1970)",
                videoURL: newVideoURLs[index % newVideoURLs.count],
                thumbnailURL: generateOptimizedThumbnailURL(for: index + 100),
                title: newTitles[index % newTitles.count],
                creator: "@TrendingCreator\(index + 1)",
                duration: [30, 60, 90][index % 3],
                createdAt: Date(), // Just posted
                viewCount: Int.random(in: 1000...10000),
                likeCount: Int.random(in: 100...1000),
                hashtags: "#new #trending #viral"
            )
        }
    }
    
    private func generateOptimizedThumbnailURL(for index: Int) -> String {
        // Use Picsum for consistent, fast-loading thumbnails
        let width = [320, 400, 480][index % 3]
        let height = [240, 300, 360][index % 3]
        return "https://picsum.photos/\(width)/\(height)?random=\(index)"
    }
    
    private func generateRealisticViewCount(for index: Int) -> Int {
        // Generate more realistic view counts based on "recency"
        let baseViews = [100, 500, 1000, 5000, 10000, 50000, 100000]
        let multiplier = max(1, 20 - index) // Newer videos get more views
        return baseViews[index % baseViews.count] * multiplier
    }
    
    private func generateRealisticLikeCount(for index: Int) -> Int {
        // Likes are typically 5-10% of views
        let viewCount = generateRealisticViewCount(for: index)
        return Int(Double(viewCount) * Double.random(in: 0.05...0.15))
    }
    
    // Preload thumbnails for even better performance
    func preloadThumbnails() {
        cacheQueue.async {
            for video in self.videoCache {
                if let thumbnailURL = video.thumbnailURL,
                   let url = URL(string: thumbnailURL) {
                    
                    let task = self.session.dataTask(with: url) { data, response, error in
                        if let data = data {
                            // Cache the thumbnail data
                            print("📷 Preloaded thumbnail for: \(video.title ?? "Unknown")")
                        }
                    }
                    task.resume()
                }
            }
        }
    }
    
    // Clear cache if needed
    func clearCache() {
        cacheQueue.async {
            self.videoCache.removeAll()
            self.session.configuration.urlCache?.removeAllCachedResponses()
            print("🗑️ Video cache cleared")
        }
    }
}


