////
////  MainTabBarController.swift
////  DualCamera
////
////  Created by Admin on 26/06/25.
////
//

import UIKit

class MainTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("🎯 MainTabBarController loaded successfully!")
        setupTabBar()
        setupViewControllers()
    }
    
    private func setupTabBar() {
        print("🎨 Setting up tab bar appearance...")
        tabBar.tintColor = .systemBlue
        tabBar.unselectedItemTintColor = .systemGray
        tabBar.backgroundColor = .systemBackground
        
        // Add subtle shadow
        tabBar.layer.shadowColor = UIColor.black.cgColor
        tabBar.layer.shadowOpacity = 0.1
        tabBar.layer.shadowOffset = CGSize(width: 0, height: -2)
        tabBar.layer.shadowRadius = 4
    }
    
    private func setupViewControllers() {
        print("📱 Setting up FULL view controllers...")
        
        // Replace test controllers with REAL ones
        let feedVC = createNavigationController(
            rootViewController: FeedViewController(),  // REAL FEED
            title: "Feed",
            image: UIImage(systemName: "house.fill")
        )
        
        let cameraVC = createNavigationController(
            rootViewController: DualCameraViewController(),  // REAL CAMERA
            title: "Camera",
            image: UIImage(systemName: "camera.fill")
        )
        
        let galleryVC = createNavigationController(
            rootViewController: CameraRollViewController(),  // REAL GALLERY
            title: "Gallery",
            image: UIImage(systemName: "photo.on.rectangle")
        )
        
        viewControllers = [feedVC, cameraVC, galleryVC]
        print("✅ FULL view controllers setup complete!")
    }
    
    private func createNavigationController(rootViewController: UIViewController, title: String, image: UIImage?) -> UINavigationController {
        let navController = UINavigationController(rootViewController: rootViewController)
        navController.tabBarItem.title = title
        navController.tabBarItem.image = image
        navController.navigationBar.prefersLargeTitles = false
        return navController
    }
}
