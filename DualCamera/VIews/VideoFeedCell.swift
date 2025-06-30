//
//  VideoFeedCell.swift
//  DualCamera
//
//  Created by Admin on 26/06/25.
//

import Foundation
import UIKit
import AVFoundation


// MARK: - Video Feed Cell

class VideoFeedCell: UICollectionViewCell {
    static let identifier = "VideoFeedCell"
    
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .black
        return view
    }()
    
    private let overlayView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.textColor = .white
        label.numberOfLines = 2
        return label
    }()
    
    private let creatorLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .lightGray
        return label
    }()
    
    private let playButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "play.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 60)), for: .normal)
        button.tintColor = .white
        button.alpha = 0.8
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        pauseVideo()
        player = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
    }
    
    private func setupUI() {
        contentView.addSubview(containerView)
        contentView.addSubview(overlayView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(creatorLabel)
        contentView.addSubview(playButton)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            overlayView.topAnchor.constraint(equalTo: contentView.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.bottomAnchor.constraint(equalTo: creatorLabel.topAnchor, constant: -8),
            
            creatorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            creatorLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            creatorLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32),
            
            playButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        
        playButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
    }
    
    func configure(with video: VideoItem) {
        titleLabel.text = video.title
        creatorLabel.text = video.creator
        
        guard let url = URL(string: video.videoURL) else { return }
        
        player = AVPlayer(url: url)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = containerView.bounds
        playerLayer?.videoGravity = .resizeAspectFill
        
        containerView.layer.addSublayer(playerLayer!)
        
        // Auto-play muted
        player?.isMuted = true
        player?.play()
        playButton.isHidden = true
        
        // Loop video
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem, queue: .main) { _ in
            self.player?.seek(to: .zero)
            self.player?.play()
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
        playButton.isHidden = true
    }
    
    func pauseVideo() {
        player?.pause()
        playButton.isHidden = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = containerView.bounds
    }
}
