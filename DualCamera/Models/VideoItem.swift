//
//  VideoItem.swift
//  DualCamera
//
//  Created by Admin on 26/06/25.
//

import Foundation
import UIKit
import AVFoundation

// MARK: - Enhanced VideoItem Model

struct VideoItem: Codable {
    let id: String
    let videoURL: String
    let thumbnailURL: String?
    let title: String?
    let creator: String?
    let duration: Double
    let createdAt: Date
    let viewCount: Int
    let likeCount: Int
    let hashtags: String?
    
    init(id: String = UUID().uuidString,
         videoURL: String,
         thumbnailURL: String? = nil,
         title: String? = nil,
         creator: String? = nil,
         duration: Double = 0,
         createdAt: Date = Date(),
         viewCount: Int = 0,
         likeCount: Int = 0,
         hashtags: String? = nil) {
        self.id = id
        self.videoURL = videoURL
        self.thumbnailURL = thumbnailURL
        self.title = title
        self.creator = creator
        self.duration = duration
        self.createdAt = createdAt
        self.viewCount = viewCount
        self.likeCount = likeCount
        self.hashtags = hashtags
    }
    
    // Computed properties for UI
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var formattedViews: String {
        if viewCount >= 1000000 {
            return String(format: "%.1fM", Double(viewCount) / 1000000)
        } else if viewCount >= 1000 {
            return String(format: "%.1fK", Double(viewCount) / 1000)
        } else {
            return "\(viewCount)"
        }
    }
    
    var formattedLikes: String {
        if likeCount >= 1000000 {
            return String(format: "%.1fM", Double(likeCount) / 1000000)
        } else if likeCount >= 1000 {
            return String(format: "%.1fK", Double(likeCount) / 1000)
        } else {
            return "\(likeCount)"
        }
    }
    
    var timeAgo: String {
        let timeInterval = Date().timeIntervalSince(createdAt)
        
        if timeInterval < 3600 { // Less than 1 hour
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m ago"
        } else if timeInterval < 86400 { // Less than 1 day
            let hours = Int(timeInterval / 3600)
            return "\(hours)h ago"
        } else { // More than 1 day
            let days = Int(timeInterval / 86400)
            return "\(days)d ago"
        }
    }
}
