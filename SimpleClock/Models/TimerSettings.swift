import Foundation

/// 计时器设置数据模型
struct TimerSettings: Equatable {
    
    /// 计时时长（分钟）
    var duration: Int
    
    /// 提醒间隔（分钟）
    var interval: Int
    
    /// 默认设置
    static let `default` = TimerSettings(duration: 60, interval: 5)
    
    /// 从用户偏好加载设置，如果没有则使用默认值
    static var userPreferred: TimerSettings {
        let duration = UserDefaults.standard.object(forKey: "UserPreferredDuration") as? Int ?? 60
        let interval = UserDefaults.standard.object(forKey: "UserPreferredInterval") as? Int ?? 5
        return TimerSettings(duration: duration, interval: interval)
    }
    
    /// 保存用户偏好设置
    func saveAsUserPreferred() {
        UserDefaults.standard.set(duration, forKey: "UserPreferredDuration")
        UserDefaults.standard.set(interval, forKey: "UserPreferredInterval")
    }
    
    /// 可选的计时时长范围（1-720分钟，即12小时）
    static let durationRange = 1...720
    
    /// 可选的提醒间隔选项（分钟）
    static let intervalOptions = [0, 1, 5, 10, 15, 30, 60, 90]
    
    /// 初始化
    /// - Parameters:
    ///   - duration: 计时时长（分钟），范围1-720
    ///   - interval: 提醒间隔（分钟），支持0-720的任意值
    init(duration: Int, interval: Int) {
        self.duration = max(1, min(720, duration))
        // 支持任意间隔时间，范围0-720分钟
        self.interval = max(0, min(720, interval))
    }
    
    /// 验证设置是否有效
    var isValid: Bool {
        return TimerSettings.durationRange.contains(duration) && 
               interval >= 0 && interval <= 720
    }
    
    /// 计时时长的显示文本
    var durationText: String {
        return "\(duration)分钟"
    }
    
    /// 提醒间隔的显示文本
    var intervalText: String {
        return interval == 0 ? "不提醒" : "\(interval)分钟"
    }
}