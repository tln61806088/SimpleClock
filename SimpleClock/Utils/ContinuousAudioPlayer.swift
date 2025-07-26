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
        
        // 确保音频会话配置正确
        AudioSessionManager.shared.activateAudioSession()
        
        let success = player.play()
        isPlaying = success
        
        if success {
            logger.info("✅ 开始持续播放piano_01.mp3音频，音量: \(player.volume)")
            logger.info("🔄 已调用startContinuousPlayback方法")
            
            // 延迟检查播放状态
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self = self, let player = self.audioPlayer else { return }
                self.logger.info("播放状态检查 - isPlaying: \(self.isPlaying), player.isPlaying: \(player.isPlaying), currentTime: \(player.currentTime)")
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
    
    /// 设置远程控制命令
    private func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // 启用播放/暂停控制
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.isEnabled = true
        
        // 设置播放命令处理器
        commandCenter.playCommand.addTarget { [weak self] event in
            self?.logger.info("🎵 锁屏播放命令")
            // 通知TimerViewModel开始计时
            NotificationCenter.default.post(name: .lockScreenPlayCommand, object: nil)
            return .success
        }
        
        // 设置暂停命令处理器
        commandCenter.pauseCommand.addTarget { [weak self] event in
            self?.logger.info("🎵 锁屏暂停命令")
            // 通知TimerViewModel暂停计时
            NotificationCenter.default.post(name: .lockScreenPauseCommand, object: nil)
            return .success
        }
        
        // 设置播放/暂停切换命令处理器
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] event in
            self?.logger.info("🎵 锁屏切换命令")
            // 通知TimerViewModel切换计时状态
            NotificationCenter.default.post(name: .lockScreenToggleCommand, object: nil)
            return .success
        }
        
        // 设置上一首命令处理器（可以用于其他功能）
        commandCenter.previousTrackCommand.addTarget { [weak self] event in
            self?.logger.info("🎵 锁屏上一首命令")
            return .success
        }
        
        // 设置下一首命令处理器（可以用于其他功能）
        commandCenter.nextTrackCommand.addTarget { [weak self] event in
            self?.logger.info("🎵 锁屏下一首命令")
            return .success
        }
        
        logger.info("🎵 设置远程控制命令完成")
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