import Foundation

/// 计时器设置数据模型
struct TimerSettings: Equatable {
    
    /// 计时时长（分钟）
    var duration: Int
    
    /// 提醒间隔（分钟）
    var interval: Int
    
    /// 默认设置
    static let `default` = TimerSettings(duration: 90, interval: 5)
    
    /// 可选的计时时长范围（1-180分钟）
    static let durationRange = 1...180
    
    /// 可选的提醒间隔选项（分钟）
    static let intervalOptions = [0, 1, 5, 10, 15, 30, 60, 90]
    
    /// 初始化
    /// - Parameters:
    ///   - duration: 计时时长（分钟），范围1-180
    ///   - interval: 提醒间隔（分钟），必须在intervalOptions中
    init(duration: Int, interval: Int) {
        self.duration = max(1, min(180, duration))
        self.interval = TimerSettings.intervalOptions.contains(interval) ? interval : 5
    }
    
    /// 验证设置是否有效
    var isValid: Bool {
        return TimerSettings.durationRange.contains(duration) && 
               TimerSettings.intervalOptions.contains(interval)
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