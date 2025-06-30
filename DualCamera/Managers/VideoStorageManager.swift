//
//  VideoStorageManager.swift
//  DualCamera
//
//  Created by Admin on 26/06/25.
//

import Foundation
import UIKit

// MARK: - Video Storage Manager

import Photos

class VideoStorageManager {
    static let shared = VideoStorageManager()
    private init() {}
    
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    
    func saveVideo(at url: URL, completion: @escaping (Bool) -> Void) {
        let fileName = "video_\(Date().timeIntervalSince1970).mov"
        let destinationURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.copyItem(at: url, to: destinationURL)
            print("✅ Video copied to documents: \(destinationURL)")
            completion(true)
        } catch {
            print("❌ Error saving video: \(error)")
            completion(false)
        }
    }
    
    func getLocalVideos() -> [URL] {
        do {
            let videoURLs = try FileManager.default.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
                .filter { $0.pathExtension.lowercased() == "mov" || $0.pathExtension.lowercased() == "mp4" }
                .sorted { url1, url2 in
                    let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                    let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                    return date1 > date2
                }
            print("📁 Found \(videoURLs.count) local videos")
            return videoURLs
        } catch {
            print("❌ Error getting local videos: \(error)")
            return []
        }
    }
}
