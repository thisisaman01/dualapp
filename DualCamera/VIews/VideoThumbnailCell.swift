//
//  VideoThumbnailCell.swift
//  DualCamera
//
//  Created by Admin on 26/06/25.
//

import Foundation
import UIKit
import AVFoundation


// MARK: - Video Thumbnail Cell

class VideoThumbnailCell: UICollectionViewCell {
    static let identifier = "VideoThumbnailCell"
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .systemGray5
        return iv
    }()
    
    private let durationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .white
        label.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        label.textAlignment = .center
        label.layer.cornerRadius = 4
        label.clipsToBounds = true
        return label
    }()
    
    private let playIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "play.circle.fill"))
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(imageView)
        contentView.addSubview(durationLabel)
        contentView.addSubview(playIcon)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            durationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            durationLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            durationLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 35),
            durationLabel.heightAnchor.constraint(equalToConstant: 18),
            
            playIcon.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            playIcon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            playIcon.widthAnchor.constraint(equalToConstant: 30),
            playIcon.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        contentView.layer.cornerRadius = 8
        contentView.clipsToBounds = true
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
    }
    
    private func generateThumbnail(for videoURL: URL, completion: @escaping (UIImage?) -> Void) {
        DispatchQueue.global(qos: .background).async {
            let asset = AVAsset(url: videoURL)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            
            do {
                let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
                let thumbnail = UIImage(cgImage: cgImage)
                completion(thumbnail)
            } catch {
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
}
