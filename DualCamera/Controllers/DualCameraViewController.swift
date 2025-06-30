//
//  DualCameraViewController.swift
//  DualCamera
//
//  Created by Admin on 26/06/25.
//


import UIKit
import AVFoundation
import Photos

class DualCameraViewController: UIViewController {
    
    // Single capture session for both cameras
    private var captureSession: AVCaptureSession?
    private var frontPreviewLayer: AVCaptureVideoPreviewLayer?
    private var backPreviewLayer: AVCaptureVideoPreviewLayer?
    
    // Camera inputs
    private var frontCameraInput: AVCaptureDeviceInput?
    private var backCameraInput: AVCaptureDeviceInput?
    private var audioInput: AVCaptureDeviceInput?
    
    // Outputs
    private var movieFileOutput: AVCaptureMovieFileOutput?
    
    // Current active camera
    private var isUsingFrontCamera = true
    private var isRecording = false
    private var recordingTimer: Timer?
    private var recordingDuration: TimeInterval = 0
    
    // Permission flags
    private var cameraPermissionGranted = false
    private var microphonePermissionGranted = false
    
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .black
        return view
    }()
    
    private let mainCameraView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .black
        view.layer.borderWidth = 3
        view.layer.borderColor = UIColor.systemBlue.cgColor
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        
        // Add shadow for better visual appeal
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.3
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 8
        view.layer.masksToBounds = false
        
        return view
    }()
    
    private let pipCameraView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .black
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        
        return view
    }()
    
    private let mainCameraLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "📱 FRONT CAMERA (MAIN)"
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = .systemBlue
        label.textAlignment = .center
        label.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        return label
    }()
    
    private let pipCameraLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "🌍 BACK (PIP)"
        label.font = UIFont.boldSystemFont(ofSize: 10)
        label.textColor = .white
        label.textAlignment = .center
        label.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        label.layer.cornerRadius = 6
        label.clipsToBounds = true
        return label
    }()
    
    private let switchCameraButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "camera.rotate.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 24)), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        button.layer.cornerRadius = 20
        return button
    }()
    
    private let recordButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .red
        button.layer.cornerRadius = 40
        button.layer.borderWidth = 5
        button.layer.borderColor = UIColor.white.cgColor
        
        // Add inner circle for better visual
        let innerCircle = UIView()
        innerCircle.backgroundColor = .white
        innerCircle.layer.cornerRadius = 12
        innerCircle.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(innerCircle)
        
        NSLayoutConstraint.activate([
            innerCircle.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            innerCircle.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            innerCircle.widthAnchor.constraint(equalToConstant: 24),
            innerCircle.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        return button
    }()
    
    private let timerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 20, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.text = "00:00"
        label.backgroundColor = UIColor.red.withAlphaComponent(0.8)
        label.layer.cornerRadius = 12
        label.clipsToBounds = true
        label.layer.borderWidth = 2
        label.layer.borderColor = UIColor.white.cgColor
        return label
    }()
    
    private let instructionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "🎬 PICTURE-IN-PICTURE RECORDING\nTap switch to change main camera"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .white
        label.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        label.layer.cornerRadius = 12
        label.clipsToBounds = true
        return label
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "🔄 Checking Permissions..."
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .orange
        label.textAlignment = .center
        label.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("📹 Loading Picture-in-Picture Camera Controller...")
        setupUI()
        requestAllPermissions()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        title = "PiP Camera"
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.tintColor = .white
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        DispatchQueue.main.async {
            // Update preview layers when view bounds change
            if let mainLayer = self.isUsingFrontCamera ? self.frontPreviewLayer : self.backPreviewLayer {
                mainLayer.frame = self.mainCameraView.bounds
            }
            if let pipLayer = self.isUsingFrontCamera ? self.backPreviewLayer : self.frontPreviewLayer {
                pipLayer.frame = self.pipCameraView.bounds
            }
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        view.addSubview(containerView)
        containerView.addSubview(mainCameraView)
        containerView.addSubview(pipCameraView)
        containerView.addSubview(mainCameraLabel)
        containerView.addSubview(pipCameraLabel)
        view.addSubview(switchCameraButton)
        view.addSubview(recordButton)
        view.addSubview(timerLabel)
        view.addSubview(instructionLabel)
        view.addSubview(statusLabel)
        
        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            containerView.bottomAnchor.constraint(equalTo: instructionLabel.topAnchor, constant: -20),
            
            // Main Camera View (Full Size)
            mainCameraView.topAnchor.constraint(equalTo: containerView.topAnchor),
            mainCameraView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            mainCameraView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            mainCameraView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            // PiP Camera View (Corner)
            pipCameraView.topAnchor.constraint(equalTo: mainCameraView.topAnchor, constant: 20),
            pipCameraView.trailingAnchor.constraint(equalTo: mainCameraView.trailingAnchor, constant: -20),
            pipCameraView.widthAnchor.constraint(equalToConstant: 120),
            pipCameraView.heightAnchor.constraint(equalToConstant: 160),
            
            // Main Camera Label
            mainCameraLabel.topAnchor.constraint(equalTo: mainCameraView.topAnchor, constant: 12),
            mainCameraLabel.centerXAnchor.constraint(equalTo: mainCameraView.centerXAnchor),
            mainCameraLabel.widthAnchor.constraint(equalToConstant: 200),
            mainCameraLabel.heightAnchor.constraint(equalToConstant: 28),
            
            // PiP Camera Label
            pipCameraLabel.bottomAnchor.constraint(equalTo: pipCameraView.bottomAnchor, constant: -8),
            pipCameraLabel.centerXAnchor.constraint(equalTo: pipCameraView.centerXAnchor),
            pipCameraLabel.widthAnchor.constraint(equalToConstant: 80),
            pipCameraLabel.heightAnchor.constraint(equalToConstant: 20),
            
            // Switch Camera Button
            switchCameraButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            switchCameraButton.centerYAnchor.constraint(equalTo: recordButton.centerYAnchor),
            switchCameraButton.widthAnchor.constraint(equalToConstant: 40),
            switchCameraButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Timer Label
            timerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            timerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            timerLabel.widthAnchor.constraint(equalToConstant: 100),
            timerLabel.heightAnchor.constraint(equalToConstant: 35),
            
            // Status Label
            statusLabel.topAnchor.constraint(equalTo: timerLabel.bottomAnchor, constant: 8),
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.widthAnchor.constraint(equalToConstant: 220),
            statusLabel.heightAnchor.constraint(equalToConstant: 25),
            
            // Instruction Label
            instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            instructionLabel.bottomAnchor.constraint(equalTo: recordButton.topAnchor, constant: -20),
            instructionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            instructionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            instructionLabel.heightAnchor.constraint(equalToConstant: 50),
            
            // Record Button
            recordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recordButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            recordButton.widthAnchor.constraint(equalToConstant: 80),
            recordButton.heightAnchor.constraint(equalToConstant: 80)
        ])
        
        recordButton.addTarget(self, action: #selector(recordButtonTapped), for: .touchUpInside)
        switchCameraButton.addTarget(self, action: #selector(switchCameraButtonTapped), for: .touchUpInside)
        recordButton.isEnabled = false // Disable until permissions are granted
        
        // Add pulse animation to record button
        addPulseAnimation()
        
        // Add tap gesture to PiP view for switching
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(switchCameraButtonTapped))
        pipCameraView.addGestureRecognizer(tapGesture)
    }
    
    private func addPulseAnimation() {
        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        pulseAnimation.duration = 1.0
        pulseAnimation.fromValue = 1.0
        pulseAnimation.toValue = 1.05
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity
        recordButton.layer.add(pulseAnimation, forKey: "pulse")
    }
    
    // MARK: - Permission Handling
    
    private func requestAllPermissions() {
        statusLabel.text = "🔄 Requesting Camera Permission..."
        
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                self?.cameraPermissionGranted = granted
                if granted {
                    print("✅ Camera permission granted")
                    self?.statusLabel.text = "🔄 Requesting Microphone Permission..."
                    self?.requestMicrophonePermission()
                } else {
                    print("❌ Camera permission denied")
                    self?.statusLabel.text = "❌ Camera Access Denied"
                    self?.statusLabel.textColor = .red
                    self?.showPermissionDeniedAlert(type: "Camera")
                }
            }
        }
    }
    
    private func requestMicrophonePermission() {
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
            DispatchQueue.main.async {
                self?.microphonePermissionGranted = granted
                if granted {
                    print("✅ Microphone permission granted")
                    self?.statusLabel.text = "🔄 Setting up camera..."
                    self?.setupCamera()
                } else {
                    print("❌ Microphone permission denied")
                    self?.statusLabel.text = "❌ Microphone Access Denied"
                    self?.statusLabel.textColor = .red
                    self?.showPermissionDeniedAlert(type: "Microphone")
                }
            }
        }
    }
    
    private func setupCamera() {
        DispatchQueue.global(qos: .userInitiated).async {
            print("🔧 Setting up single capture session...")
            
            let session = AVCaptureSession()
            session.sessionPreset = .high
            
            // Setup front camera input
            guard let frontDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
                  let frontInput = try? AVCaptureDeviceInput(device: frontDevice) else {
                print("❌ Front camera not available")
                DispatchQueue.main.async {
                    self.statusLabel.text = "❌ Front Camera Error"
                    self.statusLabel.textColor = .red
                }
                return
            }
            
            // Setup back camera input
            guard let backDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let backInput = try? AVCaptureDeviceInput(device: backDevice) else {
                print("❌ Back camera not available")
                DispatchQueue.main.async {
                    self.statusLabel.text = "❌ Back Camera Error"
                    self.statusLabel.textColor = .red
                }
                return
            }
            
            // Setup audio input
            guard let audioDevice = AVCaptureDevice.default(for: .audio),
                  let audioInput = try? AVCaptureDeviceInput(device: audioDevice) else {
                print("❌ Audio device not available")
                DispatchQueue.main.async {
                    self.statusLabel.text = "❌ Audio Error"
                    self.statusLabel.textColor = .red
                }
                return
            }
            
            // Add front camera input (start with front camera)
            if session.canAddInput(frontInput) {
                session.addInput(frontInput)
                self.frontCameraInput = frontInput
                print("✅ Front camera input added")
            }
            
            // Store back camera input for later use
            self.backCameraInput = backInput
            
            // Add audio input
            if session.canAddInput(audioInput) {
                session.addInput(audioInput)
                self.audioInput = audioInput
                print("✅ Audio input added")
            }
            
            // Add movie output
            let movieOutput = AVCaptureMovieFileOutput()
            if session.canAddOutput(movieOutput) {
                session.addOutput(movieOutput)
                self.movieFileOutput = movieOutput
                print("✅ Movie output added")
            }
            
            // Setup preview layers on main thread
            DispatchQueue.main.async {
                // Front camera preview layer
                let frontPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
                frontPreviewLayer.videoGravity = .resizeAspectFill
                frontPreviewLayer.cornerRadius = 16
                
                // Back camera preview layer (initially not connected)
                let backPreviewLayer = AVCaptureVideoPreviewLayer()
                backPreviewLayer.videoGravity = .resizeAspectFill
                backPreviewLayer.cornerRadius = 12
                
                self.captureSession = session
                self.frontPreviewLayer = frontPreviewLayer
                self.backPreviewLayer = backPreviewLayer
                
                // Add preview layers to views
                self.mainCameraView.layer.addSublayer(frontPreviewLayer)
                self.pipCameraView.layer.addSublayer(backPreviewLayer)
                
                print("✅ Preview layers added")
                
                // Start session
                DispatchQueue.global(qos: .userInitiated).async {
                    session.startRunning()
                    
                    DispatchQueue.main.async {
                        if session.isRunning {
                            print("✅ Camera session started successfully")
                            self.statusLabel.text = "✅ Camera Ready"
                            self.statusLabel.textColor = .systemGreen
                            self.recordButton.isEnabled = true
                            self.recordButton.alpha = 1.0
                            self.updateCameraLabels()
                        } else {
                            print("❌ Camera session failed to start")
                            self.statusLabel.text = "❌ Camera Failed"
                            self.statusLabel.textColor = .red
                        }
                    }
                }
            }
        }
    }
    
    @objc private func switchCameraButtonTapped() {
        guard let session = captureSession,
              let frontInput = frontCameraInput,
              let backInput = backCameraInput else { return }
        
        print("🔄 Switching cameras...")
        
        DispatchQueue.global(qos: .userInitiated).async {
            session.beginConfiguration()
            
            if self.isUsingFrontCamera {
                // Switch to back camera
                session.removeInput(frontInput)
                if session.canAddInput(backInput) {
                    session.addInput(backInput)
                    print("✅ Switched to back camera")
                }
            } else {
                // Switch to front camera
                session.removeInput(backInput)
                if session.canAddInput(frontInput) {
                    session.addInput(frontInput)
                    print("✅ Switched to front camera")
                }
            }
            
            session.commitConfiguration()
            
            DispatchQueue.main.async {
                self.isUsingFrontCamera.toggle()
                self.updateCameraLabels()
                self.animateCameraSwitch()
            }
        }
    }
    
    private func updateCameraLabels() {
        if isUsingFrontCamera {
            mainCameraLabel.text = "📱 FRONT CAMERA (MAIN)"
            mainCameraLabel.textColor = .systemBlue
            pipCameraLabel.text = "🌍 BACK (PIP)"
            mainCameraView.layer.borderColor = UIColor.systemBlue.cgColor
        } else {
            mainCameraLabel.text = "🌍 BACK CAMERA (MAIN)"
            mainCameraLabel.textColor = .systemGreen
            pipCameraLabel.text = "📱 FRONT (PIP)"
            mainCameraView.layer.borderColor = UIColor.systemGreen.cgColor
        }
    }
    
    private func animateCameraSwitch() {
        UIView.transition(with: containerView, duration: 0.5, options: .transitionFlipFromLeft, animations: {
            // Visual feedback for switching
        }, completion: nil)
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    @objc private func recordButtonTapped() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        guard let movieOutput = movieFileOutput,
              let session = captureSession,
              session.isRunning else {
            print("❌ Recording setup not ready")
            statusLabel.text = "❌ Recording Setup Error"
            statusLabel.textColor = .red
            return
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let timestamp = Date().timeIntervalSince1970
        let cameraType = isUsingFrontCamera ? "front" : "back"
        let videoURL = documentsPath.appendingPathComponent("pip_video_\(cameraType)_\(timestamp).mov")
        
        movieOutput.startRecording(to: videoURL, recordingDelegate: self)
        
        isRecording = true
        recordingDuration = 0
        
        statusLabel.text = "🔴 Recording PiP Video"
        statusLabel.textColor = .red
        instructionLabel.text = "🔴 RECORDING IN PROGRESS\nMax 15 seconds"
        
        // Disable camera switching during recording
        switchCameraButton.isEnabled = false
        switchCameraButton.alpha = 0.5
        
        // Animate record button
        UIView.animate(withDuration: 0.3) {
            self.recordButton.backgroundColor = .systemRed
            self.recordButton.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }
        
        // Animate camera borders
        UIView.animate(withDuration: 0.5, delay: 0, options: [.repeat, .autoreverse], animations: {
            self.mainCameraView.layer.borderColor = UIColor.red.cgColor
            self.pipCameraView.layer.borderColor = UIColor.red.cgColor
        }, completion: nil)
        
        startTimer()
        print("🔴 Started recording PiP video")
    }
    
    private func stopRecording() {
        movieFileOutput?.stopRecording()
        
        isRecording = false
        
        statusLabel.text = "💾 Saving Video..."
        statusLabel.textColor = .orange
        instructionLabel.text = "💾 PROCESSING VIDEO\nPlease wait..."
        
        // Re-enable camera switching
        switchCameraButton.isEnabled = true
        switchCameraButton.alpha = 1.0
        
        UIView.animate(withDuration: 0.3) {
            self.recordButton.backgroundColor = .red
            self.recordButton.transform = .identity
        }
        
        // Stop border animations
        mainCameraView.layer.removeAllAnimations()
        pipCameraView.layer.removeAllAnimations()
        updateCameraLabels() // Reset border colors
        
        stopTimer()
        print("⏹️ Stopped recording")
    }
    
    private func startTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.recordingDuration += 1
            self?.updateTimerLabel()
            
            // Auto-stop at 15 seconds
            if self?.recordingDuration ?? 0 >= 15 {
                self?.stopRecording()
            }
        }
    }
    
    private func stopTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    private func updateTimerLabel() {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        timerLabel.text = String(format: "%02d:%02d", minutes, seconds)
        
        // Flash effect
        UIView.animate(withDuration: 0.5) {
            self.timerLabel.alpha = 0.5
        } completion: { _ in
            UIView.animate(withDuration: 0.5) {
                self.timerLabel.alpha = 1.0
            }
        }
    }
    
    private func showPermissionDeniedAlert(type: String) {
        let alert = UIAlertController(
            title: "\(type) Access Required",
            message: "Please allow \(type.lowercased()) access in Settings to use video recording.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func resetUI() {
        DispatchQueue.main.async {
            self.statusLabel.text = "📹 Ready to Record"
            self.statusLabel.textColor = .systemGreen
            self.instructionLabel.text = "🎬 PICTURE-IN-PICTURE RECORDING\nTap switch to change main camera"
            self.timerLabel.text = "00:00"
        }
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate

extension DualCameraViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
        if let error = error {
            print("❌ Recording error: \(error)")
            DispatchQueue.main.async {
                self.statusLabel.text = "❌ Recording Failed"
                self.statusLabel.textColor = .red
                self.instructionLabel.text = "❌ RECORDING FAILED\nTry again"
                self.resetUI()
            }
            return
        }
        
        print("✅ Video saved: \(outputFileURL.lastPathComponent)")
        
        // Save video to storage
        VideoStorageManager.shared.saveVideo(at: outputFileURL) { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    print("✅ Video saved to gallery successfully")
                    self?.statusLabel.text = "✅ Video Saved!"
                    self?.statusLabel.textColor = .systemGreen
                    self?.instructionLabel.text = "✅ VIDEO SAVED!\nSwitching to gallery..."
                    
                    // Navigate to gallery after 1.5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self?.tabBarController?.selectedIndex = 2
                        self?.resetUI()
                    }
                } else {
                    print("❌ Failed to save video to gallery")
                    self?.statusLabel.text = "❌ Save Failed"
                    self?.statusLabel.textColor = .red
                    self?.instructionLabel.text = "❌ SAVE FAILED\nTry recording again"
                    self?.resetUI()
                }
            }
        }
    }
}
