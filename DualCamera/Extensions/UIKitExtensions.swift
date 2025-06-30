//
//  UIKitExtensions.swift
//  DualCamera
//
//  Created by Admin on 26/06/25.
//

import Foundation
import UIKit


// MARK: - UIView Extensions

import UIKit

extension UIView {
    
    // MARK: - Animation Helpers
    func fadeIn(duration: TimeInterval = 0.3, completion: (() -> Void)? = nil) {
        alpha = 0
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 1
        }) { _ in
            completion?()
        }
    }
    
    func fadeOut(duration: TimeInterval = 0.3, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 0
        }) { _ in
            completion?()
        }
    }
    
    func pulse(scale: CGFloat = 1.1, duration: TimeInterval = 0.15) {
        UIView.animate(withDuration: duration, animations: {
            self.transform = CGAffineTransform(scaleX: scale, y: scale)
        }) { _ in
            UIView.animate(withDuration: duration) {
                self.transform = .identity
            }
        }
    }
    
    func shake(intensity: CGFloat = 10, duration: TimeInterval = 0.5) {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = duration
        animation.values = [-intensity, intensity, -intensity, intensity, -intensity/2, intensity/2, -intensity/4, intensity/4, 0]
        layer.add(animation, forKey: "shake")
    }
    
    // MARK: - Layout Helpers
    func addSubviews(_ views: UIView...) {
        views.forEach { addSubview($0) }
    }
    
    func pinToSuperview(padding: UIEdgeInsets = .zero) {
        guard let superview = superview else { return }
        
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: superview.topAnchor, constant: padding.top),
            leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: padding.left),
            trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: -padding.right),
            bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -padding.bottom)
        ])
    }
    
    func center(in view: UIView) {
        NSLayoutConstraint.activate([
            centerXAnchor.constraint(equalTo: view.centerXAnchor),
            centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - Corner Radius & Shadows
    func roundCorners(radius: CGFloat = 8) {
        layer.cornerRadius = radius
        clipsToBounds = true
    }
    
    func addShadow(color: UIColor = .black, opacity: Float = 0.1, offset: CGSize = CGSize(width: 0, height: 2), radius: CGFloat = 4) {
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowOffset = offset
        layer.shadowRadius = radius
        layer.masksToBounds = false
    }
    
    func addBorder(color: UIColor, width: CGFloat) {
        layer.borderColor = color.cgColor
        layer.borderWidth = width
    }
}

// MARK: - UIViewController Extensions

extension UIViewController {
    
    // MARK: - Alert Helpers
    func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
    
    func showConfirmationAlert(title: String, message: String, confirmTitle: String = "Confirm", confirmAction: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: confirmTitle, style: .default) { _ in
            confirmAction()
        })
        present(alert, animated: true)
    }
    
    // MARK: - Loading Indicators
    private static var loadingView: UIView?
    
    func showLoadingIndicator() {
        hideLoadingIndicator()
        
        let loadingView = UIView()
        loadingView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.color = .white
        activityIndicator.startAnimating()
        
        loadingView.addSubview(activityIndicator)
        view.addSubview(loadingView)
        
        NSLayoutConstraint.activate([
            loadingView.topAnchor.constraint(equalTo: view.topAnchor),
            loadingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: loadingView.centerYAnchor)
        ])
        
        UIViewController.loadingView = loadingView
        loadingView.fadeIn()
    }
    
    func hideLoadingIndicator() {
        UIViewController.loadingView?.removeFromSuperview()
        UIViewController.loadingView = nil
    }
    
    // MARK: - Keyboard Handling
    func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        // Override in subclass
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        // Override in subclass
    }
}

// MARK: - String Extensions

extension String {
    
    var isValidURL: Bool {
        guard let url = URL(string: self) else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
    
    func formatDuration() -> String {
        guard let duration = Double(self) else { return "0:00" }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    func truncated(to length: Int, trailing: String = "...") -> String {
        return count > length ? String(prefix(length)) + trailing : self
    }
}

// MARK: - Date Extensions

extension Date {
    
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    func formatForFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter.string(from: self)
    }
}

// MARK: - URL Extensions

extension URL {
    
    var fileSize: Int64 {
        do {
            let resourceValues = try self.resourceValues(forKeys: [.fileSizeKey])
            return Int64(resourceValues.fileSize ?? 0)
        } catch {
            return 0
        }
    }
    
    var creationDate: Date? {
        do {
            let resourceValues = try self.resourceValues(forKeys: [.creationDateKey])
            return resourceValues.creationDate
        } catch {
            return nil
        }
    }
}

// MARK: - AVAsset Extensions

import AVFoundation

extension AVAsset {
    
    func generateThumbnail(at time: CMTime = .zero) async -> UIImage? {
        let imageGenerator = AVAssetImageGenerator(asset: self)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.apertureMode = .encodedPixels
        
        do {
            let cgImage = try await imageGenerator.image(at: time).image
            return UIImage(cgImage: cgImage)
        } catch {
            print("Error generating thumbnail: \(error)")
            return nil
        }
    }
    
    var videoDuration: TimeInterval {
        return duration.seconds
    }
    
    var videoSize: CGSize {
        guard let videoTrack = tracks(withMediaType: .video).first else {
            return .zero
        }
        return videoTrack.naturalSize.applying(videoTrack.preferredTransform)
    }
}

// MARK: - UIColor Extensions

extension UIColor {
    
    // MARK: - App Colors
    static let primaryBlue = UIColor.systemBlue
    static let secondaryGray = UIColor.systemGray2
    static let backgroundColor = UIColor.systemBackground
    static let cardBackground = UIColor.secondarySystemBackground
    
    // MARK: - Custom Colors
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    func lighter(by percentage: CGFloat = 0.2) -> UIColor {
        return self.adjustBrightness(by: abs(percentage))
    }
    
    func darker(by percentage: CGFloat = 0.2) -> UIColor {
        return self.adjustBrightness(by: -abs(percentage))
    }
    
    private func adjustBrightness(by percentage: CGFloat) -> UIColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        if getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            brightness = min(max(brightness + percentage, 0.0), 1.0)
            return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
        }
        
        return self
    }
}

// MARK: - Error Handling

enum AppError: LocalizedError {
    case cameraNotAvailable
    case microphoneNotAvailable
    case videoRecordingFailed
    case videoSaveFailed
    case networkError(String)
    case fileNotFound
    case permissionDenied(String)
    
    var errorDescription: String? {
        switch self {
        case .cameraNotAvailable:
            return "Camera is not available on this device"
        case .microphoneNotAvailable:
            return "Microphone access is required for video recording"
        case .videoRecordingFailed:
            return "Failed to record video. Please try again."
        case .videoSaveFailed:
            return "Failed to save video to your device"
        case .networkError(let message):
            return "Network error: \(message)"
        case .fileNotFound:
            return "The requested file could not be found"
        case .permissionDenied(let permission):
            return "\(permission) permission is required. Please enable it in Settings."
        }
    }
}

// MARK: - Device Utilities

struct DeviceUtilities {
    
    static var isIPhone: Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }
    
    static var isPad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
    
    static var hasNotch: Bool {
        if #available(iOS 11.0, *) {
            return UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0 > 20
        }
        return false
    }
    
    static var screenSize: CGSize {
        return UIScreen.main.bounds.size
    }
    
    static var isSmallScreen: Bool {
        return screenSize.height < 812 // iPhone SE and smaller
    }
}

// MARK: - Performance Monitor

class PerformanceMonitor {
    
    static let shared = PerformanceMonitor()
    private init() {}
    
    func logMemoryUsage() {
        let memoryUsage = getMemoryUsage()
        print("📊 Memory usage: \(memoryUsage) MB")
    }
    
    private func getMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / 1024.0 / 1024.0
        }
        
        return 0
    }
    
    func measureExecutionTime<T>(operation: () throws -> T) rethrows -> (result: T, time: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try operation()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        print("⏱️ Operation completed in \(String(format: "%.3f", timeElapsed)) seconds")
        return (result, timeElapsed)
    }
}

// MARK: - Logger

class Logger {
    
    enum Level: String {
        case debug = "🔍 DEBUG"
        case info = "ℹ️ INFO"
        case warning = "⚠️ WARNING"
        case error = "❌ ERROR"
    }
    
    static func log(_ message: String, level: Level = .info, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        let timestamp = DateFormatter.loggerFormatter.string(from: Date())
        print("\(timestamp) \(level.rawValue) [\(fileName):\(line)] \(function) - \(message)")
    }
    
    static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, file: file, function: function, line: line)
    }
    
    static func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, file: file, function: function, line: line)
    }
    
    static func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, file: file, function: function, line: line)
    }
    
    static func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, file: file, function: function, line: line)
    }
}

private extension DateFormatter {
    static let loggerFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
}

// MARK: - Haptic Feedback Manager

class HapticFeedbackManager {
    
    static let shared = HapticFeedbackManager()
    private init() {}
    
    func lightImpact() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    func mediumImpact() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    func heavyImpact() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
    
    func success() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    func warning() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.warning)
    }
    
    func error() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.error)
    }
    
    func selectionChanged() {
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.selectionChanged()
    }
}
