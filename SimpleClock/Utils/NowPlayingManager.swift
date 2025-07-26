//
//  NowPlayingManager.swift
//  SimpleClock
//
//  锁屏媒体控制管理器
//  实现锁屏界面的音乐播放控件，支持暂停/播放控制计时，上一首/下一首切换音乐
//

import MediaPlayer
import AVFoundation
import UIKit
import os.log

class NowPlayingManager: NSObject {
    static let shared = NowPlayingManager()
    
    private let logger = Logger(subsystem: "SimpleClock", category: "NowPlaying")
    private let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    private let commandCenter = MPRemoteCommandCenter.shared()
    
    // 委托
    weak var delegate: NowPlayingManagerDelegate?
    
    // 当前播放状态
    private var isPlaying = false
    private var currentTrackIndex = 0
    private var elapsedTime: TimeInterval = 0
    private var totalDuration: TimeInterval = 0
    
    // 音乐列表（可以根据需要扩展）
    private let musicTracks = [
        "piano_01"  // 目前只有一首，可以添加更多
    ]
    
    private override init() {
        super.init()
        setupRemoteCommandCenter()
        logger.info("🎵 NowPlayingManager初始化完成")
    }
    
    /// 设置远程控制命令
    private func setupRemoteCommandCenter() {
        // 播放命令
        commandCenter.playCommand.addTarget { [weak self] event in
            self?.logger.info("🎵 收到播放命令")
            self?.delegate?.nowPlayingManagerDidReceivePlayCommand()
            return .success
        }
        
        // 暂停命令
        commandCenter.pauseCommand.addTarget { [weak self] event in
            self?.logger.info("🎵 收到暂停命令")
            self?.delegate?.nowPlayingManagerDidReceivePauseCommand()
            return .success
        }
        
        // 播放/暂停切换命令
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] event in
            self?.logger.info("🎵 收到播放/暂停切换命令")
            self?.delegate?.nowPlayingManagerDidReceiveToggleCommand()
            return .success
        }
        
        // 上一首命令
        commandCenter.previousTrackCommand.addTarget { [weak self] event in
            self?.logger.info("🎵 收到上一首命令")
            self?.handlePreviousTrack()
            return .success
        }
        
        // 下一首命令
        commandCenter.nextTrackCommand.addTarget { [weak self] event in
            self?.logger.info("🎵 收到下一首命令")
            self?.handleNextTrack()
            return .success
        }
        
        // 启用需要的控制
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.isEnabled = true
        
        logger.info("🎵 远程控制命令设置完成")
    }
    
    /// 更新锁屏媒体信息
    func updateNowPlayingInfo(
        title: String = "SimpleClock计时器",
        artist: String = "计时进行中",
        albumTitle: String = "SimpleClock",
        isPlaying: Bool = true,
        elapsedTime: TimeInterval = 0,
        totalDuration: TimeInterval = 0
    ) {
        self.isPlaying = isPlaying
        self.elapsedTime = elapsedTime
        self.totalDuration = totalDuration
        
        var nowPlayingInfo = [String: Any]()
        
        nowPlayingInfo[MPMediaItemPropertyTitle] = title
        nowPlayingInfo[MPMediaItemPropertyArtist] = artist
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = albumTitle
        
        // 播放时间信息
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsedTime
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = totalDuration
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        
        // 媒体类型
        nowPlayingInfo[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue
        
        // 可以添加专辑封面
        if let image = UIImage(systemName: "timer") {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in
                return image
            }
        }
        
        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
        
        logger.info("🎵 更新锁屏媒体信息: \(title), 播放状态: \(isPlaying)")
    }
    
    /// 清除锁屏媒体信息
    func clearNowPlayingInfo() {
        nowPlayingInfoCenter.nowPlayingInfo = nil
        logger.info("🎵 清除锁屏媒体信息")
    }
    
    /// 处理上一首音乐
    private func handlePreviousTrack() {
        currentTrackIndex = max(0, currentTrackIndex - 1)
        switchToTrack(at: currentTrackIndex)
        delegate?.nowPlayingManagerDidReceivePreviousTrackCommand()
    }
    
    /// 处理下一首音乐
    private func handleNextTrack() {
        currentTrackIndex = min(musicTracks.count - 1, currentTrackIndex + 1)
        switchToTrack(at: currentTrackIndex)
        delegate?.nowPlayingManagerDidReceiveNextTrackCommand()
    }
    
    /// 切换到指定音乐
    private func switchToTrack(at index: Int) {
        guard index >= 0 && index < musicTracks.count else { return }
        
        let trackName = musicTracks[index]
        logger.info("🎵 切换到音乐: \(trackName)")
        
        // 通知委托切换音乐
        delegate?.nowPlayingManagerDidSwitchToTrack(trackName)
    }
    
    /// 获取当前音乐名称
    func getCurrentTrackName() -> String {
        guard currentTrackIndex >= 0 && currentTrackIndex < musicTracks.count else {
            return "piano_01"
        }
        return musicTracks[currentTrackIndex]
    }
    
    /// 启用锁屏控制
    func enableNowPlayingControls() {
        updateNowPlayingInfo()
        logger.info("🎵 启用锁屏媒体控制")
    }
    
    /// 禁用锁屏控制
    func disableNowPlayingControls() {
        clearNowPlayingInfo()
        logger.info("🎵 禁用锁屏媒体控制")
    }
}

// MARK: - NowPlayingManagerDelegate
protocol NowPlayingManagerDelegate: AnyObject {
    /// 收到播放命令
    func nowPlayingManagerDidReceivePlayCommand()
    
    /// 收到暂停命令
    func nowPlayingManagerDidReceivePauseCommand()
    
    /// 收到播放/暂停切换命令
    func nowPlayingManagerDidReceiveToggleCommand()
    
    /// 收到上一首命令
    func nowPlayingManagerDidReceivePreviousTrackCommand()
    
    /// 收到下一首命令
    func nowPlayingManagerDidReceiveNextTrackCommand()
    
    /// 切换到指定音乐
    func nowPlayingManagerDidSwitchToTrack(_ trackName: String)
}