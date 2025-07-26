import Foundation
import MediaPlayer
import AVFoundation

/// 锁屏媒体控制助手
/// 在锁屏界面显示计时器信息，类似音乐播放器
class LockScreenMediaHelper: NSObject {
    
    /// 单例实例
    static let shared = LockScreenMediaHelper()
    
    private let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    private let commandCenter = MPRemoteCommandCenter.shared()
    
    // 计时器回调
    private var playCallback: (() -> Void)?
    private var pauseCallback: (() -> Void)?
    private var stopCallback: (() -> Void)?
    
    // 媒体控制权维持定时器
    private var mediaControlTimer: Timer?
    
    private override init() {
        super.init()
        setupRemoteCommands()
        configureAudioSession()
    }
    
    /// 设置远程控制命令
    private func setupRemoteCommands() {
        // 播放命令 - 对应开始/恢复计时
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.playCallback?()
            return .success
        }
        
        // 暂停命令 - 对应暂停计时
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pauseCallback?()
            return .success
        }
        
        // 停止命令 - 对应结束计时
        commandCenter.stopCommand.isEnabled = true
        commandCenter.stopCommand.addTarget { [weak self] _ in
            self?.stopCallback?()
            return .success
        }
        
        // 禁用不需要的命令
        commandCenter.nextTrackCommand.isEnabled = false
        commandCenter.previousTrackCommand.isEnabled = false
        commandCenter.seekForwardCommand.isEnabled = false
        commandCenter.seekBackwardCommand.isEnabled = false
    }
    
    /// 设置控制回调
    func setControlCallbacks(
        play: @escaping () -> Void,
        pause: @escaping () -> Void,
        stop: @escaping () -> Void
    ) {
        playCallback = play
        pauseCallback = pause
        stopCallback = stop
    }
    
    /// 更新锁屏显示信息
    /// - Parameters:
    ///   - title: 标题（如"SimpleClock 计时器"）
    ///   - remainingTime: 剩余时间描述（如"剩余 3分15秒"）
    ///   - totalDuration: 总时长（秒）
    ///   - elapsedTime: 已过时间（秒）
    ///   - isRunning: 是否正在运行
    func updateNowPlayingInfo(
        title: String = "SimpleClock 计时器",
        remainingTime: String,
        totalDuration: TimeInterval,
        elapsedTime: TimeInterval,
        isRunning: Bool
    ) {
        var nowPlayingInfo: [String: Any] = [:]
        
        // 基本信息
        nowPlayingInfo[MPMediaItemPropertyTitle] = title
        nowPlayingInfo[MPMediaItemPropertyArtist] = remainingTime
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = "计时器"
        
        // 时间信息
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = totalDuration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsedTime
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isRunning ? 1.0 : 0.0
        
        // 媒体类型
        nowPlayingInfo[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue
        
        // 设置到系统
        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
        
        // 不再每次更新时重新激活音频会话，避免与AudioSessionManager冲突
        // 由AudioSessionManager统一管理音频会话生命周期
        
        print("锁屏媒体信息更新: \(title) - \(remainingTime)")
    }
    
    /// 清除锁屏显示信息
    func clearNowPlayingInfo() {
        nowPlayingInfoCenter.nowPlayingInfo = nil
        print("清除锁屏媒体信息")
    }
    
    /// 格式化时间为可读字符串
    /// - Parameter seconds: 秒数
    /// - Returns: 格式化的时间字符串
    func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        
        if minutes > 0 {
            return "剩余 \(minutes)分\(remainingSeconds)秒"
        } else {
            return "剩余 \(remainingSeconds)秒"
        }
    }
    
    /// 开始显示计时器信息
    /// - Parameters:
    ///   - duration: 总时长（分钟）
    ///   - remainingSeconds: 剩余秒数
    ///   - isRunning: 是否正在运行
    func startTimerDisplay(duration: Int, remainingSeconds: Int, isRunning: Bool) {
        let totalDuration = TimeInterval(duration * 60)
        let elapsedTime = totalDuration - TimeInterval(remainingSeconds)
        let remainingTimeText = formatTime(remainingSeconds)
        
        // 不再强制抢占媒体控制权，使用AudioSessionManager统一管理
        
        updateNowPlayingInfo(
            remainingTime: remainingTimeText,
            totalDuration: totalDuration,
            elapsedTime: elapsedTime,
            isRunning: isRunning
        )
        
        // 启动定时器维持媒体控制权
        startMediaControlMaintenance()
    }
    
    /// 停止显示计时器信息
    func stopTimerDisplay() {
        // 停止媒体控制权维持定时器
        stopMediaControlMaintenance()
        clearNowPlayingInfo()
    }
    
    /// 不再独立配置音频会话，由AudioSessionManager统一管理
    private func configureAudioSession() {
        // LockScreenMediaHelper不再管理音频会话
        // 所有音频会话配置和激活由AudioSessionManager统一处理
        print("锁屏媒体控制 - 使用AudioSessionManager统一音频会话管理")
    }
    
    // 已删除强制抢占媒体控制权函数，使用AudioSessionManager统一管理音频会话
    
    /// 启动媒体控制权维持定时器
    private func startMediaControlMaintenance() {
        // 停止之前的定时器
        stopMediaControlMaintenance()
        
        // 每5秒重新声明一次媒体控制权
        mediaControlTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            self.maintainMediaControl()
        }
    }
    
    /// 停止媒体控制权维持定时器
    private func stopMediaControlMaintenance() {
        mediaControlTimer?.invalidate()
        mediaControlTimer = nil
    }
    
    /// 维持媒体控制权
    private func maintainMediaControl() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setActive(true, options: [.notifyOthersOnDeactivation])
            print("维持媒体控制权成功")
        } catch {
            print("维持媒体控制权失败: \(error.localizedDescription)")
        }
    }
}