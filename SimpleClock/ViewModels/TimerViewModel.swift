import Foundation
import Combine
import UserNotifications
import UIKit
import MediaPlayer
import os.log

/// 计时器视图模型，管理计时状态和提醒逻辑，支持后台运行
class TimerViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// 计时器设置
    @Published var settings = TimerSettings.default
    
    /// 计时器是否正在运行
    @Published var isRunning = false
    
    /// 剩余秒数
    @Published var remainingSeconds = 0
    
    // MARK: - Private Properties
    
    private var timer: Timer?
    private var startTime: Date?
    private var pausedTime: TimeInterval = 0
    private var lastReminderMinute: Int = -1
    private let logger = Logger(subsystem: "SimpleClock", category: "TimerViewModel")
    // 使用lazy初始化避免主线程警告
    private lazy var audioSessionManager = AudioSessionManager.shared
    private let continuousAudioPlayer = ContinuousAudioPlayer.shared
    private let nowPlayingManager = NowPlayingManager.shared
    
    // 应用生命周期相关
    private var appDidEnterBackgroundObserver: NSObjectProtocol?
    private var appWillEnterForegroundObserver: NSObjectProtocol?
    
    // MARK: - Initialization
    
    init() {
        // 请求通知权限
        requestNotificationPermission()
        
        // 初始状态remainingSeconds为0，不显示倒计时
        remainingSeconds = 0
        
        // 设置锁屏媒体控制回调
        setupLockScreenControls()
        
        // 设置NowPlayingManager委托
        nowPlayingManager.delegate = self
        
        // 设置应用生命周期监听
        setupAppLifecycleObservers()
        
        // 设置锁屏控制通知监听
        setupLockScreenNotifications()
        
        // 预初始化ContinuousAudioPlayer以确保日志正常工作
        _ = continuousAudioPlayer
        
        // 注意：不再初始显示音乐播放信息
        // 锁屏信息将在计时器启动时设置
        
        // 初始化时激活音频会话
        audioSessionManager.activateAudioSession()
    }
    
    deinit {
        stopTimer()
        LockScreenMediaHelper.shared.stopTimerDisplay()
        
        // 移除生命周期观察者
        if let observer = appDidEnterBackgroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = appWillEnterForegroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Private Setup Methods
    
    /// 设置锁屏媒体控制
    private func setupLockScreenControls() {
        LockScreenMediaHelper.shared.setControlCallbacks(
            play: { [weak self] in
                DispatchQueue.main.async {
                    if self?.isRunning == false {
                        self?.startTimer()
                    }
                }
            },
            pause: { [weak self] in
                DispatchQueue.main.async {
                    if self?.isRunning == true {
                        self?.pauseTimer()
                    }
                }
            },
            stop: { [weak self] in
                DispatchQueue.main.async {
                    self?.stopTimer()
                }
            }
        )
    }
    
    /// 设置应用生命周期观察者
    private func setupAppLifecycleObservers() {
        appDidEnterBackgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppDidEnterBackground()
        }
        
        appWillEnterForegroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppWillEnterForeground()
        }
    }
    
    /// 处理应用进入后台
    private func handleAppDidEnterBackground() {
        logger.info("应用进入后台，确保计时器和音频会话正常运行")
        
        // 只在音频会话未激活时才激活
        if !audioSessionManager.isAudioSessionActive {
            audioSessionManager.activateAudioSession()
        }
        
        // 后台任务由PermissionManager统一管理，不需要在这里重复开始
    }
    
    /// 处理应用回到前台
    private func handleAppWillEnterForeground() {
        logger.info("应用回到前台，同步计时器状态")
        
        // 只在音频会话未激活时才激活
        if !audioSessionManager.isAudioSessionActive {
            audioSessionManager.activateAudioSession()
        }
        
        // 如果计时器应该在运行，同步实际状态
        if isRunning, let startTime = startTime {
            let elapsed = Date().timeIntervalSince(startTime)
            let totalDuration = TimeInterval(settings.duration * 60)
            let remaining = totalDuration - elapsed
            
            if remaining <= 0 {
                // 计时已经结束，更新状态
                logger.info("计时已在后台结束，更新状态")
                remainingSeconds = 0
                stopTimer()
                handleTimerCompletion()
            } else {
                // 更新剩余时间
                remainingSeconds = Int(remaining)
                logger.info("同步剩余时间：\(self.remainingSeconds)秒")
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// 开始计时
    func startTimer() {
        guard !isRunning else { return }
        
        if startTime == nil {
            // 第一次启动
            startTime = Date()
            remainingSeconds = settings.duration * 60
            lastReminderMinute = -1
        } else {
            // 从暂停状态恢复
            let pausedDuration = pausedTime
            startTime = Date().addingTimeInterval(-pausedDuration)
        }
        
        isRunning = true
        pausedTime = 0
        
        // 开始计时时启动音乐播放以维持后台音频会话
        logger.info("🔄 计时开始，启动音乐播放")
        continuousAudioPlayer.startContinuousPlayback()
        
        // 启动定时器
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
        
        // 更新锁屏媒体信息为计时状态
        updateNowPlayingInfo()
        
        // 安排本地通知
        scheduleNotifications()
    }
    
    /// 暂停计时
    func pauseTimer() {
        guard isRunning else { return }
        
        isRunning = false
        timer?.invalidate()
        timer = nil
        
        // 计时暂停时，音乐继续播放以维持后台会话
        // 不停止音乐播放，这样锁屏控制依然可用
        
        // 记录暂停时的经过时间
        if let startTime = startTime {
            pausedTime = Date().timeIntervalSince(startTime)
        }
        
        // 更新锁屏媒体信息为暂停状态
        updateNowPlayingInfo()
        
        // 取消所有通知
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    /// 停止计时
    func stopTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        
        // 计时结束时停止音乐播放
        continuousAudioPlayer.stopContinuousPlayback()
        
        startTime = nil
        pausedTime = 0
        lastReminderMinute = -1
        
        // 结束计时后，将剩余时间重置为0，恢复正常时钟显示
        remainingSeconds = 0
        
        // 清除锁屏媒体信息
        nowPlayingManager.clearNowPlayingInfo()
        
        // 取消所有通知
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    /// 重置计时器设置
    func updateSettings(_ newSettings: TimerSettings) {
        settings = newSettings
        
        // 设置更新时不自动显示剩余时间，保持为0直到用户点击开始
        if !isRunning {
            remainingSeconds = 0
        }
    }
    
    // MARK: - Private Methods
    
    /// 更新计时器
    private func updateTimer() {
        guard let startTime = startTime else { return }
        
        let elapsed = Date().timeIntervalSince(startTime)
        let totalDuration = TimeInterval(settings.duration * 60)
        let remaining = totalDuration - elapsed
        
        if remaining <= 0 {
            // 计时结束
            remainingSeconds = 0
            stopTimer()
            handleTimerCompletion()
        } else {
            remainingSeconds = Int(remaining)
            
            // 更新锁屏媒体信息
            updateNowPlayingInfo()
            
            checkForReminders()
            
            // 每30秒检查一次持续音频播放状态
            if Int(elapsed) % 30 == 0 {
                checkContinuousAudioStatus()
            }
        }
    }
    
    /// 检查持续音频播放状态
    private func checkContinuousAudioStatus() {
        if isRunning && !continuousAudioPlayer.isContinuouslyPlaying {
            logger.warning("⚠️ 检测到持续音频停止播放，尝试重启")
            continuousAudioPlayer.forceRestartPlayback()
        }
    }
    
    /// 检查是否需要提醒
    private func checkForReminders() {
        // 向上取整分钟数，与播报逻辑保持一致
        let remainingMinutes = (remainingSeconds + 59) / 60
        
        // 间隔提醒（只有当间隔不为0时才提醒）
        if settings.interval > 0 && remainingMinutes > 0 && remainingMinutes % settings.interval == 0 && lastReminderMinute != remainingMinutes {
            lastReminderMinute = remainingMinutes
            let message = "剩余时间\(remainingMinutes)分钟"
            SpeechHelper.shared.speak(message)
        }
        
        // 特殊提醒：距离结束2分钟时的提醒（除了"不提醒"和"1分钟"间隔）
        if remainingMinutes == 2 && settings.interval != 0 && settings.interval != 1 && lastReminderMinute != remainingMinutes {
            lastReminderMinute = remainingMinutes
            let message = "剩余2分钟，计时即将结束"
            SpeechHelper.shared.speak(message)
        }
        
        // 1分钟间隔的情况：最后2分钟每分钟提醒
        if settings.interval == 1 && remainingMinutes <= 2 && remainingMinutes > 0 && lastReminderMinute != remainingMinutes {
            lastReminderMinute = remainingMinutes
            let message = "剩余\(remainingMinutes)分钟"
            SpeechHelper.shared.speak(message)
        }
    }
    
    /// 处理计时完成
    private func handleTimerCompletion() {
        HapticHelper.shared.lightImpact()
        SpeechHelper.shared.speak("计时结束")
        
        // 发送完成通知
        sendCompletionNotification()
    }
    
    /// 更新剩余秒数（用于非运行状态）
    private func updateRemainingSeconds() {
        remainingSeconds = settings.duration * 60
    }
    
    /// 请求通知权限
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("通知权限请求失败: \(error)")
            }
        }
    }
    
    /// 安排本地通知
    private func scheduleNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        guard let startTime = startTime else { return }
        
        let totalDuration = TimeInterval(settings.duration * 60)
        let endTime = startTime.addingTimeInterval(totalDuration)
        
        // 间隔提醒通知
        let intervalMinutes = settings.interval
        var nextReminderTime = startTime.addingTimeInterval(TimeInterval(intervalMinutes * 60))
        
        while nextReminderTime < endTime {
            let remainingTime = endTime.timeIntervalSince(nextReminderTime)
            let remainingMinutes = Int(remainingTime / 60)
            
            if remainingMinutes > 2 {
                scheduleNotification(
                    at: nextReminderTime,
                    title: "计时提醒",
                    body: "剩余时间\(remainingMinutes)分钟",
                    identifier: "reminder_\(remainingMinutes)"
                )
            }
            
            nextReminderTime = nextReminderTime.addingTimeInterval(TimeInterval(intervalMinutes * 60))
        }
        
        // 最后2分钟每分钟提醒
        for minute in 1...2 {
            let reminderTime = endTime.addingTimeInterval(TimeInterval(-minute * 60))
            if reminderTime > Date() {
                scheduleNotification(
                    at: reminderTime,
                    title: "计时提醒",
                    body: "剩余\(minute)分钟",
                    identifier: "final_\(minute)"
                )
            }
        }
        
        // 计时结束通知
        scheduleNotification(
            at: endTime,
            title: "计时结束",
            body: "您设置的\(settings.duration)分钟计时已完成",
            identifier: "completion"
        )
    }
    
    /// 安排单个通知
    private func scheduleNotification(at date: Date, title: String, body: String, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("通知安排失败: \(error)")
            }
        }
    }
    
    /// 发送完成通知
    private func sendCompletionNotification() {
        let content = UNMutableNotificationContent()
        content.title = "计时结束"
        content.body = "您设置的\(settings.duration)分钟计时已完成"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "immediate_completion", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    /// 设置锁屏控制通知监听
    private func setupLockScreenNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLockScreenPlayCommand),
            name: .lockScreenPlayCommand,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLockScreenPauseCommand),
            name: .lockScreenPauseCommand,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLockScreenToggleCommand),
            name: .lockScreenToggleCommand,
            object: nil
        )
        
        logger.info("🎵 设置锁屏控制通知监听完成")
    }
    
    @objc private func handleLockScreenPlayCommand() {
        logger.info("🎵 处理锁屏播放命令")
        DispatchQueue.main.async {
            if !self.isRunning {
                self.startTimer()
            }
        }
    }
    
    @objc private func handleLockScreenPauseCommand() {
        logger.info("🎵 处理锁屏暂停命令")
        DispatchQueue.main.async {
            if self.isRunning {
                self.pauseTimer()
            }
        }
    }
    
    @objc private func handleLockScreenToggleCommand() {
        logger.info("🎵 处理锁屏切换命令")
        DispatchQueue.main.async {
            if self.isRunning {
                self.pauseTimer()
            } else {
                self.startTimer()
            }
        }
    }
    
    /// 更新锁屏媒体信息
    private func updateNowPlayingInfo() {
        // 只有在计时运行或暂停时才显示计时器信息
        if startTime != nil {
            let title: String
            let artist: String
            
            if isRunning {
                let minutes = remainingSeconds / 60
                let seconds = remainingSeconds % 60
                title = "SimpleClock计时器"
                artist = String(format: "剩余: %02d:%02d", minutes, seconds)
            } else {
                title = "SimpleClock计时器"
                artist = "计时已暂停"
            }
            
            // 直接更新MPNowPlayingInfoCenter
            var nowPlayingInfo = [String: Any]()
            
            nowPlayingInfo[MPMediaItemPropertyTitle] = title
            nowPlayingInfo[MPMediaItemPropertyArtist] = artist
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = "SimpleClock"
            
            // 播放状态 - 音乐始终在播放，这里显示计时状态
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0  // 音乐一直播放
            nowPlayingInfo[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue
            
            // 时间信息
            let elapsedTime = pausedTime > 0 ? pausedTime : 
                             (startTime != nil ? Date().timeIntervalSince(startTime!) : 0)
            let totalDuration = TimeInterval(settings.duration * 60)
            
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsedTime
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = totalDuration
            
            // 添加专辑封面
            if let image = UIImage(systemName: "timer") {
                nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in
                    return image
                }
            }
            
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            logger.info("🎵 更新锁屏媒体信息: \(title)")
        }
        // 注意：没有计时任务时，不设置任何锁屏信息
        // 这样锁屏就不会显示播放控件
    }
}

// MARK: - NowPlayingManagerDelegate
extension TimerViewModel: NowPlayingManagerDelegate {
    
    func nowPlayingManagerDidReceivePlayCommand() {
        logger.info("🎵 锁屏播放命令：开始/恢复计时")
        if !isRunning {
            startTimer()
        }
    }
    
    func nowPlayingManagerDidReceivePauseCommand() {
        logger.info("🎵 锁屏暂停命令：暂停计时")
        if isRunning {
            pauseTimer()
        }
    }
    
    func nowPlayingManagerDidReceiveToggleCommand() {
        logger.info("🎵 锁屏切换命令：播放/暂停计时")
        if isRunning {
            pauseTimer()
        } else {
            startTimer()
        }
    }
    
    func nowPlayingManagerDidReceivePreviousTrackCommand() {
        logger.info("🎵 锁屏上一首命令：降低音量")
        // 可以实现降低音量或其他功能
    }
    
    func nowPlayingManagerDidReceiveNextTrackCommand() {
        logger.info("🎵 锁屏下一首命令：提高音量")
        // 可以实现提高音量或其他功能
    }
    
    func nowPlayingManagerDidSwitchToTrack(_ trackName: String) {
        logger.info("🎵 锁屏切换音乐：\(trackName)")
        // 这里可以通知ContinuousAudioPlayer切换音乐文件
    }
}