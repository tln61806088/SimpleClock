//
//  ContinuousAudioPlayer.swift
//  SimpleClock
//
//  持续播放微弱音频以维持后台音频会话
//

import AVFoundation
import UIKit
import MediaPlayer
import os.log

class ContinuousAudioPlayer: NSObject {
    static let shared = ContinuousAudioPlayer()
    
    private let logger = Logger(subsystem: "SimpleClock", category: "ContinuousAudioPlayer")
    private var audioPlayer: AVAudioPlayer?
    private var isPlaying = false
    
    // 临时调整到正常音量，方便测试听到滴答声效果
    private let minimalVolume: Float = 1.0
    
    private override init() {
        super.init()
        logger.info("🔊 ContinuousAudioPlayer初始化")
        setupAudioPlayer()
        setupRemoteCommands()
        setupAudioSessionObserver()
    }
    
    /// 设置音频播放器
    private func setupAudioPlayer() {
        guard let audioPath = Bundle.main.path(forResource: "piano_01", ofType: "mp3") else {
            logger.error("无法找到piano_01.mp3音频文件")
            return
        }
        
        logger.info("找到音频文件路径: \(audioPath)")
        
        do {
            let audioURL = URL(fileURLWithPath: audioPath)
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.delegate = self
            audioPlayer?.volume = minimalVolume
            audioPlayer?.numberOfLoops = -1  // 无限循环
            let prepared = audioPlayer?.prepareToPlay() ?? false
            
            logger.info("持续音频播放器初始化成功，prepareToPlay: \(prepared)")
            let duration = audioPlayer?.duration ?? 0
            logger.info("音频文件时长: \(duration) 秒")
        } catch {
            logger.error("创建音频播放器失败: \(error.localizedDescription)")
        }
    }
    
    /// 开始持续播放
    func startContinuousPlayback() {
        logger.info("🔄 准备启动持续音频播放")
        
        if audioPlayer == nil {
            logger.error("音频播放器未初始化，重新初始化")
            setupAudioPlayer()
            if audioPlayer == nil {
                logger.error("重新初始化音频播放器失败")
                return
            }
            logger.info("重新初始化音频播放器成功")
        }
        
        guard let player = audioPlayer else {
            logger.error("音频播放器为nil")
            return
        }
        
        logger.info("🔄 获取到ContinuousAudioPlayer实例")
        
        if isPlaying {
            logger.info("持续音频已在播放中，跳过启动")
            return
        }
        
        logger.info("🔄 开始持续音频播放")
        
        // 确保音频会话配置正确且已激活
        AudioSessionManager.shared.activateAudioSession()
        
        // 注意：音频会话已通过AudioSessionManager统一管理，避免重复配置
        
        // 确保播放器已准备好
        let prepared = player.prepareToPlay()
        logger.info("🎵 音频播放器准备状态: \(prepared)")
        
        // 开始播放
        let success = player.play()
        isPlaying = success
        
        if success {
            logger.info("✅ 开始持续播放piano_01.mp3音频，音量: \(player.volume)")
            logger.info("🔄 音频播放已启动 - isPlaying: \(player.isPlaying), currentTime: \(player.currentTime)")
            
            // 等待音频真正开始播放后设置锁屏信息
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                guard let self = self, let player = self.audioPlayer else { return }
                
                if player.isPlaying {
                    self.logger.info("🎵 音频确实在播放，设置锁屏信息")
                    self.updateInitialNowPlayingInfo()
                } else {
                    self.logger.warning("⚠️ 音频未在播放，重试启动")
                    // 重试一次
                    let retrySuccess = player.play()
                    if retrySuccess {
                        self.logger.info("🎵 重试播放成功，设置锁屏信息")
                        self.updateInitialNowPlayingInfo()
                    } else {
                        self.logger.error("❌ 重试播放失败")
                    }
                }
            }
            
            // 1秒后验证锁屏信息设置
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self = self else { return }
                self.logger.info("🎵 验证播放状态：")
                self.logger.info("  - 内部状态: \(self.isPlaying)")
                self.logger.info("  - 播放器状态: \(self.audioPlayer?.isPlaying ?? false)")
                self.logger.info("  - 播放时间: \(self.audioPlayer?.currentTime ?? 0)")
                
                let nowPlayingState = MPNowPlayingInfoCenter.default().playbackState
                let nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo
                self.logger.info("  - 锁屏状态: \(nowPlayingState.rawValue)")
                self.logger.info("  - 锁屏信息: \(nowPlayingInfo != nil ? "已设置" : "未设置")")
            }
        } else {
            logger.error("❌ 无法开始持续音频播放")
            isPlaying = false
        }
    }
    
    /// 停止持续播放
    func stopContinuousPlayback() {
        guard let player = audioPlayer else {
            logger.info("音频播放器未初始化")
            return
        }
        
        if !isPlaying {
            logger.info("持续音频并未在播放")
            return
        }
        
        player.stop()
        isPlaying = false
        
        logger.info("🛑 停止持续播放piano_01.mp3音频")
    }
    
    /// 调整音量
    func setVolume(_ volume: Float) {
        audioPlayer?.volume = minimalVolume
        logger.info("调整持续音频音量至: \(self.minimalVolume)")
    }
    
    /// 检查是否正在播放
    var isContinuouslyPlaying: Bool {
        let actuallyPlaying = self.isPlaying && (self.audioPlayer?.isPlaying ?? false)
        logger.info("播放状态检查 - 标记状态: \(self.isPlaying), 实际播放: \(self.audioPlayer?.isPlaying ?? false)")
        return actuallyPlaying
    }
    
    /// 强制重启播放
    func forceRestartPlayback() {
        logger.info("强制重启持续音频播放")
        stopContinuousPlayback()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.startContinuousPlayback()
        }
    }
    
    /// 强化后台播放保持机制
    func ensureBackgroundPlayback() {
        guard let player = audioPlayer else { return }
        
        if isPlaying && !player.isPlaying {
            logger.warning("🔄 后台播放中断，强制重启")
            DispatchQueue.main.async {
                // 重新配置音频会话
                AudioSessionManager.shared.activateAudioSession()
                
                // 重启播放
                let success = player.play()
                if success {
                    self.logger.info("✅ 后台播放重启成功")
                } else {
                    self.logger.error("❌ 后台播放重启失败，尝试完全重新初始化")
                    self.setupAudioPlayer()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.startContinuousPlayback()
                    }
                }
            }
        }
    }
    
    /// 设置远程控制命令（参考开源项目最佳实践）
    private func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // 先清理所有现有的target，避免重复注册
        commandCenter.playCommand.removeTarget(self)
        commandCenter.pauseCommand.removeTarget(self)
        commandCenter.togglePlayPauseCommand.removeTarget(self)
        commandCenter.nextTrackCommand.removeTarget(self)
        commandCenter.previousTrackCommand.removeTarget(self)
        
        // 启用核心播放控制（根据SwiftAudioEx模式）
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.isEnabled = true
        
        // 启用跳跃控制（用于计时器调整）
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.isEnabled = true
        
        // 禁用不需要的控制
        commandCenter.skipForwardCommand.isEnabled = false
        commandCenter.skipBackwardCommand.isEnabled = false
        commandCenter.seekForwardCommand.isEnabled = false
        commandCenter.seekBackwardCommand.isEnabled = false
        commandCenter.changePlaybackPositionCommand.isEnabled = false
        
        // 设置播放命令处理器（开始/恢复计时）
        commandCenter.playCommand.addTarget { [weak self] event in
            self?.logger.info("🎵 锁屏播放命令 - 开始/恢复计时")
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .lockScreenPlayCommand, object: nil)
            }
            return .success
        }
        
        // 设置暂停命令处理器（暂停计时）
        commandCenter.pauseCommand.addTarget { [weak self] event in
            self?.logger.info("🎵 锁屏暂停命令 - 暂停计时")
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .lockScreenPauseCommand, object: nil)
            }
            return .success
        }
        
        // 设置播放/暂停切换命令处理器
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] event in
            self?.logger.info("🎵 锁屏切换命令 - 播放/暂停计时")
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .lockScreenToggleCommand, object: nil)
            }
            return .success
        }
        
        // 上一首：减少计时时间（可选功能）
        commandCenter.previousTrackCommand.addTarget { [weak self] event in
            self?.logger.info("🎵 锁屏上一首命令 - 减少计时时间")
            // 可以实现减少计时时间的功能
            return .success
        }
        
        // 下一首：增加计时时间（可选功能）
        commandCenter.nextTrackCommand.addTarget { [weak self] event in
            self?.logger.info("🎵 锁屏下一首命令 - 增加计时时间")
            // 可以实现增加计时时间的功能
            return .success
        }
        
        logger.info("🎵 远程控制命令配置完成 - 遵循iOS音频播放器标准")
    }
    
    /// 设置音频会话监听（参考GitHub最佳实践）
    private func setupAudioSessionObserver() {
        // 监听音频会话恢复通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionResumed),
            name: .audioSessionResumed,
            object: nil
        )
        
        logger.info("🎵 音频会话监听器设置完成")
    }
    
    @objc private func handleAudioSessionResumed() {
        logger.info("🎵 接收到音频会话恢复通知，检查播放状态")
        
        // 如果应该播放但实际没有播放，重新启动
        if isPlaying && !(audioPlayer?.isPlaying ?? false) {
            logger.info("🎵 检测到播放状态不一致，重新启动播放")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.forceRestartPlayback()
            }
        }
        
        // 额外保险：即使状态一致，也确保音频会话配置正确
        AudioSessionManager.shared.activateAudioSession()
    }
    
    /// 设置锁屏信息（按照Apple最佳实践）
    private func updateInitialNowPlayingInfo() {
        // 确保在主线程执行
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let player = self.audioPlayer else {
                self?.logger.error("🎵 无法设置锁屏信息：播放器为nil")
                return
            }
            
            // 第一步：设置播放状态（关键）
            MPNowPlayingInfoCenter.default().playbackState = .playing
            self.logger.info("🎵 设置播放状态为.playing")
            
            // 第二步：设置详细媒体信息
            var nowPlayingInfo = [String: Any]()
            
            // 基础媒体信息
            nowPlayingInfo[MPMediaItemPropertyTitle] = "SimpleClock 计时器"
            nowPlayingInfo[MPMediaItemPropertyArtist] = "正在计时"
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = "SimpleClock"
            
            // 关键：播放率必须为1.0才能激活锁屏控件
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
            nowPlayingInfo[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue
            
            // 设置时间信息
            let duration = player.duration.isFinite ? player.duration : 300.0 // 5分钟默认
            let currentTime = player.currentTime
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
            
            // 添加专辑封面
            if let image = UIImage(systemName: "timer") {
                let size = CGSize(width: 512, height: 512)
                let renderer = UIGraphicsImageRenderer(size: size)
                let artwork = renderer.image { context in
                    // 设置蓝色背景
                    UIColor.systemBlue.setFill()
                    context.fill(CGRect(origin: .zero, size: size))
                    
                    // 绘制白色计时器图标
                    let iconSize = CGSize(width: 256, height: 256)
                    let iconRect = CGRect(
                        x: (size.width - iconSize.width) / 2,
                        y: (size.height - iconSize.height) / 2,
                        width: iconSize.width,
                        height: iconSize.height
                    )
                    image.withTintColor(.white).draw(in: iconRect)
                }
                nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: size) { _ in artwork }
            }
            
            // 第三步：设置到系统
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            
            self.logger.info("🎵 锁屏信息设置完成 - 标题: SimpleClock 计时器, 播放率: 1.0, 时长: \(duration)秒")
            
            // 验证设置是否成功
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let currentInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo
                let currentState = MPNowPlayingInfoCenter.default().playbackState
                self.logger.info("🎵 验证锁屏信息 - 状态: \(currentState.rawValue), 信息: \(currentInfo != nil ? "已设置" : "未设置")")
            }
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let lockScreenPlayCommand = Notification.Name("lockScreenPlayCommand")
    static let lockScreenPauseCommand = Notification.Name("lockScreenPauseCommand")
    static let lockScreenToggleCommand = Notification.Name("lockScreenToggleCommand")
}

// MARK: - AVAudioPlayerDelegate
extension ContinuousAudioPlayer: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        logger.info("音频播放完成，成功: \(flag)")
        if flag && isPlaying {
            logger.warning("无限循环播放意外结束，重新启动")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.startContinuousPlayback()
            }
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        logger.error("音频播放解码错误: \(error?.localizedDescription ?? "未知错误")")
        isPlaying = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.logger.info("尝试重新初始化音频播放器...")
            self.setupAudioPlayer()
        }
    }
    
    func audioPlayerBeginInterruption(_ player: AVAudioPlayer) {
        logger.info("音频播放被中断")
        isPlaying = false
    }
    
    func audioPlayerEndInterruption(_ player: AVAudioPlayer, withOptions flags: Int) {
        logger.info("音频播放中断结束，标志: \(flags)")
        if UInt(flags) & AVAudioSession.InterruptionOptions.shouldResume.rawValue != 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.startContinuousPlayback()
            }
        }
    }
}