import Foundation
import Combine
import UserNotifications
import UIKit
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
        
        // 设置应用生命周期监听
        setupAppLifecycleObservers()
        
        // 预初始化ContinuousAudioPlayer以确保日志正常工作
        _ = continuousAudioPlayer
        
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
        
        // 开始持续播放微弱音频以维持后台音频会话
        logger.info("🔄 准备启动持续音频播放")
        let player = continuousAudioPlayer
        logger.info("🔄 获取到ContinuousAudioPlayer实例: \(player)")
        player.startContinuousPlayback()
        logger.info("🔄 已调用startContinuousPlayback方法")
        
        // 启动定时器
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
        
        // 显示锁屏媒体信息
        LockScreenMediaHelper.shared.startTimerDisplay(
            duration: self.settings.duration,
            remainingSeconds: self.remainingSeconds,
            isRunning: true
        )
        
        // 安排本地通知
        scheduleNotifications()
    }
    
    /// 暂停计时
    func pauseTimer() {
        guard isRunning else { return }
        
        isRunning = false
        timer?.invalidate()
        timer = nil
        
        // 暂停持续音频播放
        continuousAudioPlayer.stopContinuousPlayback()
        
        // 记录暂停时的经过时间
        if let startTime = startTime {
            pausedTime = Date().timeIntervalSince(startTime)
        }
        
        // 更新锁屏媒体信息为暂停状态
        LockScreenMediaHelper.shared.startTimerDisplay(
            duration: self.settings.duration,
            remainingSeconds: self.remainingSeconds,
            isRunning: false
        )
        
        // 取消所有通知
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    /// 停止计时
    func stopTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        
        // 停止持续音频播放
        continuousAudioPlayer.stopContinuousPlayback()
        
        startTime = nil
        pausedTime = 0
        lastReminderMinute = -1
        
        // 结束计时后，将剩余时间重置为0，恢复正常时钟显示
        remainingSeconds = 0
        
        // 清除锁屏媒体信息
        LockScreenMediaHelper.shared.stopTimerDisplay()
        
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
            LockScreenMediaHelper.shared.startTimerDisplay(
                duration: self.settings.duration,
                remainingSeconds: self.remainingSeconds,
                isRunning: self.isRunning
            )
            
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
}