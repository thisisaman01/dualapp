# 📹 DualCamera - iOS Video Recording App

A professional iOS app showcasing advanced **dual camera recording**, **TikTok-style video feeds**, and **sophisticated video processing**. Built with 100% **UIKit programmatic UI** to demonstrate senior iOS development skills.

## 🚀 **Features**

### **📱 Feed Tab**
- TikTok-style vertical video player with smooth scrolling
- Auto-play with mute and custom controls
- Network streaming with intelligent caching

### **📹 Camera Tab** 
- Picture-in-Picture dual camera recording
- Real-time camera switching with smooth transitions
- 15-second recording with visual timer

### **🎬 Gallery Tab**
- Grid-based video gallery with thumbnails
- Full-screen playback with custom player
- Swipe-to-delete functionality

## 🏗️ **Technical Highlights**

- **AVFoundation**: Advanced dual camera capture and video processing
- **Single Session Management**: Optimized for iOS hardware limitations
- **Professional Architecture**: MVC + Manager pattern with clean separation
- **Performance Optimized**: Background processing, smart caching, memory management
- **Modern UI/UX**: Smooth animations, haptic feedback, accessibility support

## 📁 **Project Structure**

```
DualCamera/
├── Controllers/     # MainTabBar, Feed, Camera, Gallery
├── Views/          # Custom cells and UI components  
├── Models/         # VideoItem data model
├── Managers/       # Network, Storage, Cache managers
└── Extensions/     # UIKit utilities and helpers
```

## 🛠️ **Setup**

1. **Clone repository**
2. **Add camera/microphone permissions** to Info.plist:
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>Camera access for video recording</string>
   <key>NSMicrophoneUsageDescription</key>
   <string>Microphone access for audio recording</string>
   ```
3. **Build on physical device** (camera required)

## 🎯 **Key Technologies**

| Technology | Purpose |
|-----------|---------|
| **AVCaptureSession** | Multi-camera recording |
| **AVMutableComposition** | Video processing |
| **URLSession** | Network video streaming |
| **Core Animation** | Smooth UI transitions |
| **Photos Framework** | Gallery integration |

## 🎨 **UI/UX**

- **100% Programmatic UIKit** (no storyboards)
- **iOS native design patterns** with system colors
- **Dark/Light mode support**
- **Responsive layouts** for all iPhone sizes
- **Accessibility optimized**

## 📊 **Performance**

- **Instant video loading** with pre-cached data
- **<200ms camera switching** with single session approach
- **Memory efficient** with automatic cleanup
- **Battery optimized** preview layers



---
