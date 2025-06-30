////
////  SceneDelegate.swift
////  DualCamera
////
////  Created by Admin on 26/06/25.
////
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        print("🎬 Scene is connecting...")
        
        // Make sure we have a window scene
        guard let windowScene = (scene as? UIWindowScene) else {
            print("❌ No window scene found")
            return
        }
        
        print("✅ Window scene found: \(windowScene)")
        
        // Create window with the scene
        window = UIWindow(windowScene: windowScene)
        print("📱 Window created with scene")
        
        // Create main tab controller
        let mainTabController = MainTabBarController()
        print("📂 MainTabBarController created in scene")
        
        // Set root view controller
        window?.rootViewController = mainTabController
        window?.makeKeyAndVisible()
        
        print("✅ Window is now visible in scene!")
        
        // Setup app appearance
        setupAppAppearance()
    }
    
    private func setupAppAppearance() {
        print("🎨 Setting up app appearance in scene...")
        
        // Modern iOS appearance
        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .systemBackground
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        
        UINavigationBar.appearance().prefersLargeTitles = false
        UINavigationBar.appearance().tintColor = .systemBlue
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        print("📱 Scene disconnected")
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        print("📱 Scene became active")
    }

    func sceneWillResignActive(_ scene: UIScene) {
        print("📱 Scene will resign active")
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        print("📱 Scene will enter foreground")
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        print("📱 Scene did enter background")
    }
}
