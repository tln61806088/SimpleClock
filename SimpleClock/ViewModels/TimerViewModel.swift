import Foundation
import Combine
import UserNotifications

/// 计时器视图模型，管理计时状态和提醒逻辑
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
    
    // MARK: - Initialization
    
    init() {
        // 请求通知权限
        requestNotificationPermission()
        
        // 初始状态remainingSeconds为0，不显示倒计时
        remainingSeconds = 0
    }
    
    deinit {
        stopTimer()
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
        
        // 启动定时器
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
        
        // 安排本地通知
        scheduleNotifications()
    }
    
    /// 暂停计时
    func pauseTimer() {
        guard isRunning else { return }
        
        isRunning = false
        timer?.invalidate()
        timer = nil
        
        // 记录暂停时的经过时间
        if let startTime = startTime {
            pausedTime = Date().timeIntervalSince(startTime)
        }
        
        // 取消所有通知
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    /// 停止计时
    func stopTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        
        startTime = nil
        pausedTime = 0
        lastReminderMinute = -1
        
        // 结束计时后，将剩余时间重置为0，恢复正常时钟显示
        remainingSeconds = 0
        
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
            checkForReminders()
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
        
        // 最后2分钟每分钟提醒
        if remainingMinutes <= 2 && remainingMinutes > 0 && lastReminderMinute != remainingMinutes {
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