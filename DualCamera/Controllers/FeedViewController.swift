//
//  FeedViewController.swift
//  DualCamera
//
//  Created by Admin on 26/06/25.
//

import Foundation
import UIKit
import AVFoundation

class FeedViewController: UIViewController {
    
    private var videos: [VideoItem] = []
    private var currentVideoIndex = 0
    private var isLoading = false
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .black
        cv.delegate = self
        cv.dataSource = self
        cv.isPagingEnabled = true
        cv.showsVerticalScrollIndicator = false
        cv.prefetchDataSource = self // Add prefetching for better performance
        cv.register(EnhancedVideoFeedCell.self, forCellWithReuseIdentifier: EnhancedVideoFeedCell.identifier)
        return cv
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.color = .white
        return indicator
    }()
    
    private let refreshControl: UIRefreshControl = {
        let refresh = UIRefreshControl()
        refresh.tintColor = .white
        refresh.attributedTitle = NSAttributedString(string: "Pull to refresh videos",
                                                   attributes: [.foregroundColor: UIColor.white])
        return refresh
    }()
    
    private let errorView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .black
        view.isHidden = true
        
        let imageView = UIImageView(image: UIImage(systemName: "wifi.slash"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Failed to load videos\nCheck your connection"
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 16)
        
        view.addSubview(imageView)
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30),
            imageView.widthAnchor.constraint(equalToConstant: 60),
            imageView.heightAnchor.constraint(equalToConstant: 60),
            
            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ])
        
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("🎬 Loading Optimized Feed Controller...")
        setupUI()
        loadVideos()
        setupRefreshControl()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        
        // Resume video playback if coming back to this tab
        if !videos.isEmpty {
            playCurrentVideo()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pauseAllVideos()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        view.addSubview(collectionView)
        view.addSubview(loadingIndicator)
        view.addSubview(errorView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            errorView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            errorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            errorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            errorView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func setupRefreshControl() {
        refreshControl.addTarget(self, action: #selector(refreshVideos), for: .valueChanged)
        collectionView.refreshControl = refreshControl
    }
    
    @objc private func refreshVideos() {
        print("🔄 Refreshing video feed...")
        loadVideos()
    }
    
    private func loadVideos() {
        guard !isLoading else { return }
        
        isLoading = true
        
        if videos.isEmpty {
            loadingIndicator.startAnimating()
            errorView.isHidden = true
        }
        
        NetworkManager.shared.fetchJellyVideos { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.loadingIndicator.stopAnimating()
                self?.refreshControl.endRefreshing()
                
                switch result {
                case .success(let videos):
                    print("✅ Loaded \(videos.count) videos")
                    self?.videos = videos
                    self?.collectionView.reloadData()
                    self?.errorView.isHidden = true
                    
                    // Auto-play first video after loading
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self?.playCurrentVideo()
                    }
                    
                case .failure(let error):
                    print("❌ Error loading videos: \(error)")
                    self?.showError(error)
                }
            }
        }
    }
    
    private func showError(_ error: Error) {
        if videos.isEmpty {
            errorView.isHidden = false
            
            // Add retry button to error view
            let retryButton = UIButton(type: .system)
            retryButton.setTitle("Retry", for: .normal)
            retryButton.setTitleColor(.systemBlue, for: .normal)
            retryButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
            retryButton.addTarget(self, action: #selector(retryLoading), for: .touchUpInside)
            
            if !errorView.subviews.contains(where: { $0 is UIButton }) {
                errorView.addSubview(retryButton)
                retryButton.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    retryButton.centerXAnchor.constraint(equalTo: errorView.centerXAnchor),
                    retryButton.topAnchor.constraint(equalTo: errorView.subviews[1].bottomAnchor, constant: 20)
                ])
            }
        } else {
            // Show toast for non-critical errors
            showToast("Failed to refresh videos")
        }
    }
    
    @objc private func retryLoading() {
        errorView.isHidden = true
        loadVideos()
    }
    
    private func showToast(_ message: String) {
        let toast = UILabel()
        toast.text = message
        toast.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        toast.textColor = .white
        toast.textAlignment = .center
        toast.layer.cornerRadius = 20
        toast.clipsToBounds = true
        toast.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(toast)
        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            toast.widthAnchor.constraint(equalToConstant: 250),
            toast.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        UIView.animate(withDuration: 0.3, animations: {
            toast.alpha = 1.0
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 2.0, options: [], animations: {
                toast.alpha = 0.0
            }) { _ in
                toast.removeFromSuperview()
            }
        }
    }
    
    private func playCurrentVideo() {
        if let currentCell = collectionView.cellForItem(at: IndexPath(item: currentVideoIndex, section: 0)) as? EnhancedVideoFeedCell {
            currentCell.playVideo()
        }
    }
    
    private func pauseAllVideos() {
        if let visibleCells = collectionView.visibleCells as? [EnhancedVideoFeedCell] {
            for cell in visibleCells {
                cell.pauseVideo()
            }
        }
    }
}

// MARK: - Collection View Data Source & Delegate

extension FeedViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EnhancedVideoFeedCell.identifier, for: indexPath) as! EnhancedVideoFeedCell
        cell.configure(with: videos[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: view.frame.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let index = Int(scrollView.contentOffset.y / scrollView.frame.height)
        if index != currentVideoIndex && index < videos.count {
            currentVideoIndex = index
            
            // Pause all videos first
            pauseAllVideos()
            
            // Play current video
            playCurrentVideo()
            
            print("📹 Now playing video \(currentVideoIndex + 1) of \(videos.count)")
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // Pause current video when user starts scrolling
        pauseAllVideos()
    }
}

// MARK: - Collection View Prefetching

extension FeedViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        // Prefetch video data for smoother scrolling
        for indexPath in indexPaths {
            if indexPath.item < videos.count {
                let video = videos[indexPath.item]
                print("🔄 Prefetching video: \(video.title ?? "Unknown")")
                // Pre-load video player here if needed
            }
        }
    }
}

// MARK: - Enhanced Video Feed Cell

import UIKit
import AVFoundation

class EnhancedVideoFeedCell: UICollectionViewCell {
    static let identifier = "EnhancedVideoFeedCell"
    
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var timeObserver: Any?
    
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .black
        return view
    }()
    
    private let gradientView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.textColor = .white
        label.numberOfLines = 2
        label.shadowColor = .black
        label.shadowOffset = CGSize(width: 1, height: 1)
        return label
    }()
    
    private let creatorLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .lightGray
        label.shadowColor = .black
        label.shadowOffset = CGSize(width: 1, height: 1)
        return label
    }()
    
    private let statsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .lightGray
        label.shadowColor = .black
        label.shadowOffset = CGSize(width: 1, height: 1)
        return label
    }()
    
    private let playButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "play.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 60)), for: .normal)
        button.tintColor = .white
        button.alpha = 0.0
        button.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        button.layer.cornerRadius = 35
        return button
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.color = .white
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private let progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.progressTintColor = .systemBlue
        progress.trackTintColor = UIColor.white.withAlphaComponent(0.3)
        progress.layer.cornerRadius = 2
        progress.clipsToBounds = true
        return progress
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupGradient()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        cleanupPlayer()
    }
    
    private func setupUI() {
        contentView.addSubview(containerView)
        contentView.addSubview(gradientView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(creatorLabel)
        contentView.addSubview(statsLabel)
        contentView.addSubview(playButton)
        contentView.addSubview(loadingIndicator)
        contentView.addSubview(progressView)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            gradientView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            gradientView.heightAnchor.constraint(equalToConstant: 200),
            
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.bottomAnchor.constraint(equalTo: creatorLabel.topAnchor, constant: -8),
            
            creatorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            creatorLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            creatorLabel.bottomAnchor.constraint(equalTo: statsLabel.topAnchor, constant: -4),
            
            statsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            statsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            statsLabel.bottomAnchor.constraint(equalTo: progressView.topAnchor, constant: -12),
            
            progressView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            progressView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            progressView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32),
            progressView.heightAnchor.constraint(equalToConstant: 4),
            
            playButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 70),
            playButton.heightAnchor.constraint(equalToConstant: 70),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        
        playButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
        
        // Add tap gesture for play/pause
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(playButtonTapped))
        contentView.addGestureRecognizer(tapGesture)
    }
    
    private func setupGradient() {
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.8).cgColor
        ]
        gradient.locations = [0.0, 1.0]
        gradientView.layer.addSublayer(gradient)
    }
    
    func configure(with video: VideoItem) {
        titleLabel.text = video.title
        creatorLabel.text = video.creator
        
        // Format stats
        let viewsFormatted = formatCount(video.viewCount)
        let likesFormatted = formatCount(video.likeCount)
        statsLabel.text = "👀 \(viewsFormatted) views • ❤️ \(likesFormatted) likes"
        
        setupVideoPlayer(with: video.videoURL)
    }
    
    private func formatCount(_ count: Int) -> String {
        if count >= 1000000 {
            return String(format: "%.1fM", Double(count) / 1000000)
        } else if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000)
        } else {
            return "\(count)"
        }
    }
    
    private func setupVideoPlayer(with urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        loadingIndicator.startAnimating()
        
        player = AVPlayer(url: url)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = containerView.bounds
        playerLayer?.videoGravity = .resizeAspectFill
        
        containerView.layer.addSublayer(playerLayer!)
        
        // Setup player observers
        setupPlayerObservers()
        
        // Auto-play muted
        player?.isMuted = true
        
        // Setup looping
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem,
            queue: .main
        ) { [weak self] _ in
            self?.player?.seek(to: .zero)
            self?.player?.play()
        }
    }
    
    private func setupPlayerObservers() {
        // Add time observer for progress
        timeObserver = player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: .main) { [weak self] time in
            self?.updateProgress(time: time)
        }
        
        // Add ready to play observer
        player?.currentItem?.addObserver(self, forKeyPath: "status", options: [.new, .initial], context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            if player?.currentItem?.status == .readyToPlay {
                DispatchQueue.main.async {
                    self.loadingIndicator.stopAnimating()
                }
            }
        }
    }
    
    private func updateProgress(time: CMTime) {
        guard let duration = player?.currentItem?.duration else { return }
        
        let currentTime = CMTimeGetSeconds(time)
        let totalDuration = CMTimeGetSeconds(duration)
        
        if !currentTime.isNaN && !totalDuration.isNaN && totalDuration > 0 {
            let progress = Float(currentTime / totalDuration)
            progressView.progress = progress
        }
    }
    
    @objc private func playButtonTapped() {
        if player?.timeControlStatus == .playing {
            pauseVideo()
        } else {
            playVideo()
        }
    }
    
    func playVideo() {
        player?.play()
        UIView.animate(withDuration: 0.3) {
            self.playButton.alpha = 0.0
        }
    }
    
    func pauseVideo() {
        player?.pause()
        UIView.animate(withDuration: 0.3) {
            self.playButton.alpha = 0.8
        }
    }
    
    private func cleanupPlayer() {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        
        player?.currentItem?.removeObserver(self, forKeyPath: "status")
        player?.pause()
        player = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        progressView.progress = 0
        loadingIndicator.stopAnimating()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = containerView.bounds
        gradientView.layer.sublayers?.first?.frame = gradientView.bounds
    }
}
