//
//  CameraRollViewController.swift
//  DualCamera
//
//  Created by Admin on 26/06/25.
//


import Foundation
import UIKit
import AVFoundation


class CameraRollViewController: UIViewController {
    
    private var videoURLs: [URL] = []
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 4
        layout.minimumInteritemSpacing = 4
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        
        let itemsPerRow: CGFloat = 2
        let spacing: CGFloat = 4
        let sectionInsets: CGFloat = 20
        let totalSpacing = (spacing * (itemsPerRow - 1)) + sectionInsets
        let itemWidth = (view.frame.width - totalSpacing) / itemsPerRow
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth * 1.2)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .systemBackground
        cv.delegate = self
        cv.dataSource = self
        cv.register(EnhancedVideoThumbnailCell.self, forCellWithReuseIdentifier: EnhancedVideoThumbnailCell.identifier)
        return cv
    }()
    
    private let emptyStateView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let imageView = UIImageView(image: UIImage(systemName: "video.slash", withConfiguration: UIImage.SymbolConfiguration(pointSize: 80)))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .systemGray3
        imageView.contentMode = .scaleAspectFit
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "No Videos Yet"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.textColor = .systemGray2
        titleLabel.textAlignment = .center
        
        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "📹 Record your first dual POV video!\nSwitch to Camera tab to get started."
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        subtitleLabel.font = UIFont.systemFont(ofSize: 16)
        subtitleLabel.textColor = .systemGray
        
        view.addSubview(imageView)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -60),
            imageView.widthAnchor.constraint(equalToConstant: 100),
            imageView.heightAnchor.constraint(equalToConstant: 100),
            
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            subtitleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32)
        ])
        
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("📱 Loading Enhanced Camera Roll Controller...")
        setupUI()
        loadVideos()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        title = "Camera Roll"
        setupNavigationBar()
        loadVideos() // Reload when returning to this tab
    }
    
    private func setupNavigationBar() {
        // Add clear all button
        if !videoURLs.isEmpty {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: "Clear All",
                style: .plain,
                target: self,
                action: #selector(clearAllVideos)
            )
            navigationItem.rightBarButtonItem?.tintColor = .red
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(collectionView)
        view.addSubview(emptyStateView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        // Add refresh control
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshVideos), for: .valueChanged)
        collectionView.refreshControl = refreshControl
        
        // Add long press gesture for deletion
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        collectionView.addGestureRecognizer(longPressGesture)
    }
    
    private func loadVideos() {
        videoURLs = VideoStorageManager.shared.getLocalVideos()
        collectionView.reloadData()
        updateEmptyState()
        setupNavigationBar()
        print("📁 Loaded \(videoURLs.count) videos")
    }
    
    @objc private func refreshVideos() {
        loadVideos()
        collectionView.refreshControl?.endRefreshing()
    }
    
    @objc private func clearAllVideos() {
        let alert = UIAlertController(
            title: "Clear All Videos",
            message: "Are you sure you want to delete all \(videoURLs.count) videos? This action cannot be undone.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete All", style: .destructive) { _ in
            self.deleteAllVideos()
        })
        
        present(alert, animated: true)
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let point = gesture.location(in: collectionView)
            if let indexPath = collectionView.indexPathForItem(at: point) {
                showDeleteOptions(for: indexPath)
            }
        }
    }
    
    private func showDeleteOptions(for indexPath: IndexPath) {
        let videoURL = videoURLs[indexPath.item]
        let fileName = videoURL.lastPathComponent
        
        let alert = UIAlertController(
            title: "Delete Video",
            message: "Delete '\(fileName)'?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            self.deleteVideo(at: indexPath)
        })
        
        present(alert, animated: true)
    }
    
    private func deleteVideo(at indexPath: IndexPath) {
        let videoURL = videoURLs[indexPath.item]
        
        do {
            try FileManager.default.removeItem(at: videoURL)
            videoURLs.remove(at: indexPath.item)
            
            collectionView.performBatchUpdates {
                collectionView.deleteItems(at: [indexPath])
            } completion: { _ in
                self.updateEmptyState()
                self.setupNavigationBar()
                print("✅ Deleted video: \(videoURL.lastPathComponent)")
            }
            
            // Show success feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
        } catch {
            print("❌ Error deleting video: \(error)")
            
            let alert = UIAlertController(
                title: "Delete Failed",
                message: "Could not delete the video. Please try again.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
    
    private func deleteAllVideos() {
        for videoURL in videoURLs {
            try? FileManager.default.removeItem(at: videoURL)
        }
        
        videoURLs.removeAll()
        collectionView.reloadData()
        updateEmptyState()
        setupNavigationBar()
        
        print("✅ Deleted all videos")
        
        // Show success feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func updateEmptyState() {
        emptyStateView.isHidden = !videoURLs.isEmpty
        collectionView.isHidden = videoURLs.isEmpty
    }
}

// MARK: - Enhanced Camera Roll Collection View Extensions

extension CameraRollViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videoURLs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EnhancedVideoThumbnailCell.identifier, for: indexPath) as! EnhancedVideoThumbnailCell
        cell.configure(with: videoURLs[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let videoURL = videoURLs[indexPath.item]
        let playerVC = VideoPlayerViewController(videoURL: videoURL)
        present(playerVC, animated: true)
    }
}

// MARK: - Enhanced Video Thumbnail Cell

class EnhancedVideoThumbnailCell: UICollectionViewCell {
    static let identifier = "EnhancedVideoThumbnailCell"
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .systemGray5
        iv.layer.cornerRadius = 12
        return iv
    }()
    
    private let gradientView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        return view
    }()
    
    private let durationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.textColor = .white
        label.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        label.textAlignment = .center
        label.layer.cornerRadius = 6
        label.clipsToBounds = true
        return label
    }()
    
    private let playIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "play.circle.fill"))
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        iv.layer.shadowColor = UIColor.black.cgColor
        iv.layer.shadowOpacity = 0.5
        iv.layer.shadowOffset = CGSize(width: 0, height: 2)
        iv.layer.shadowRadius = 4
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = .white
        label.numberOfLines = 1
        label.text = "Dual POV Video"
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .lightGray
        label.numberOfLines = 1
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.backgroundColor = .clear
        contentView.layer.cornerRadius = 12
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOpacity = 0.2
        contentView.layer.shadowOffset = CGSize(width: 0, height: 4)
        contentView.layer.shadowRadius = 8
        
        contentView.addSubview(imageView)
        contentView.addSubview(gradientView)
        contentView.addSubview(durationLabel)
        contentView.addSubview(playIcon)
        contentView.addSubview(titleLabel)
        contentView.addSubview(dateLabel)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.75),
            
            gradientView.topAnchor.constraint(equalTo: imageView.topAnchor),
            gradientView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
            
            durationLabel.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: -8),
            durationLabel.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -8),
            durationLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 40),
            durationLabel.heightAnchor.constraint(equalToConstant: 20),
            
            playIcon.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            playIcon.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            playIcon.widthAnchor.constraint(equalToConstant: 40),
            playIcon.heightAnchor.constraint(equalToConstant: 40),
            
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            
            dateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            dateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            dateLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -4)
        ])
        
        setupGradient()
    }
    
    private func setupGradient() {
        let gradient = CAGradientLayer()
        gradient.frame = gradientView.bounds
        gradient.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.6).cgColor
        ]
        gradient.locations = [0.5, 1.0]
        gradientView.layer.addSublayer(gradient)
    }
    
    func configure(with videoURL: URL) {
        generateThumbnail(for: videoURL) { [weak self] image in
            DispatchQueue.main.async {
                self?.imageView.image = image
            }
        }
        
        getDuration(for: videoURL) { [weak self] duration in
            DispatchQueue.main.async {
                let minutes = Int(duration) / 60
                let seconds = Int(duration) % 60
                self?.durationLabel.text = String(format: "%d:%02d", minutes, seconds)
            }
        }
        
        // Set date
        if let creationDate = videoURL.creationDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            dateLabel.text = formatter.string(from: creationDate)
        } else {
            dateLabel.text = "Just now"
        }
    }
    
    private func generateThumbnail(for videoURL: URL, completion: @escaping (UIImage?) -> Void) {
        DispatchQueue.global(qos: .background).async {
            let asset = AVAsset(url: videoURL)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            imageGenerator.apertureMode = .encodedPixels
            
            do {
                let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
                let thumbnail = UIImage(cgImage: cgImage)
                completion(thumbnail)
            } catch {
                print("❌ Error generating thumbnail: \(error)")
                completion(nil)
            }
        }
    }
    
    private func getDuration(for videoURL: URL, completion: @escaping (Double) -> Void) {
        DispatchQueue.global(qos: .background).async {
            let asset = AVAsset(url: videoURL)
            let duration = asset.duration.seconds
            completion(duration)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientView.layer.sublayers?.first?.frame = gradientView.bounds
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        durationLabel.text = ""
        dateLabel.text = ""
    }
}
