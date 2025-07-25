import AVFoundation
import UIKit

/// 语音播报工具类，专为无障碍用户设计
class SpeechHelper: NSObject, @unchecked Sendable {
    
    /// 单例实例
    static let shared = SpeechHelper()
    
    private let synthesizer = AVSpeechSynthesizer()
    private var isCurrentlySpeaking = false
    
    private override init() {
        super.init()
        synthesizer.delegate = self
        
        // 配置音频会话 - 简化配置避免参数错误
        configureAudioSession()
        
        // 设置音频中断监听
        setupAudioInterruptionHandling()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc private func appWillEnterForeground() {
        configureAudioSession()
    }
    
    /// 设置音频中断处理
    private func setupAudioInterruptionHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }
    
    /// 处理音频中断（来电、其他应用等）
    @objc private func handleAudioInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            print("🔇 音频会话被中断（来电、其他应用等）")
            // 中断开始时暂停语音播报
            if isCurrentlySpeaking {
                synthesizer.pauseSpeaking(at: .immediate)
                print("暂停当前语音播报")
            }
            
        case .ended:
            print("🔊 音频中断结束，准备恢复")
            
            // 检查中断结束的选项
            if let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                
                if options.contains(.shouldResume) {
                    print("系统建议恢复音频播放")
                    
                    // 重新配置和激活音频会话
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.configureAudioSession()
                        
                        // 恢复语音播报
                        if self.synthesizer.isPaused {
                            self.synthesizer.continueSpeaking()
                            print("恢复语音播报")
                        }
                    }
                } else {
                    print("系统不建议自动恢复，用户需手动操作")
                }
            }
            
        @unknown default:
            print("未知的音频中断类型")
        }
    }
    
    /// 处理音频路由变化（蓝牙连接/断开、耳机插拔等）
    @objc private func handleRouteChange(_ notification: Notification) {
        guard let info = notification.userInfo,
              let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        switch reason {
        case .newDeviceAvailable:
            print("🎧 新音频设备可用（蓝牙、耳机等）")
            
        case .oldDeviceUnavailable:
            print("🎧 音频设备断开")
            // 设备断开时暂停播报，避免切换到扬声器时音量过大
            if isCurrentlySpeaking {
                synthesizer.pauseSpeaking(at: .immediate)
                print("因设备断开暂停语音播报")
            }
            
        case .categoryChange:
            print("🔄 音频类别发生变化")
            // 重新配置音频会话以确保设置正确
            configureAudioSession()
            
        case .override:
            print("🔄 音频会话被系统覆盖")
            
        case .wakeFromSleep:
            print("🌅 从睡眠中唤醒")
            configureAudioSession()
            
        case .noSuitableRouteForCategory:
            print("⚠️ 当前类别没有合适的音频路由")
            
        case .routeConfigurationChange:
            print("🔄 音频路由配置变化")
            
        case .unknown:
            print("⚠️ 未知原因的音频路由变化")
            
        @unknown default:
            print("未知的音频路由变化原因")
        }
    }
    
    /// 检测设备是否处于静音状态
    private func isSilentModeEnabled() -> Bool {
        // 通过音频会话检测静音状态
        let audioSession = AVAudioSession.sharedInstance()
        
        // 检查音频会话的输出音量
        if audioSession.outputVolume == 0.0 {
            return true
        }
        
        // 检查中断状态（可能由于静音开关导致）
        if audioSession.secondaryAudioShouldBeSilencedHint {
            return true
        }
        
        return false
    }
    
    /// 播报文本内容
    /// - Parameter text: 要播报的文本
    /// - Parameter rate: 语速，默认为正常速度
    /// - Parameter volume: 音量，默认为1.0
    func speak(_ text: String, rate: Float = AVSpeechUtteranceDefaultSpeechRate, volume: Float = 1.0) {
        // 检查静音状态
        if isSilentModeEnabled() {
            print("设备处于静音状态，跳过语音播报: \(text)")
            return
        }
        
        // 如果正在播报，先停止当前播报
        if isCurrentlySpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        // 每次播报都激活音频会话，确保本app音频优先
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(true, options: [.notifyOthersOnDeactivation])
            print("音频会话重新激活成功")
        } catch {
            print("重新激活音频会话失败: \(error.localizedDescription)")
            // 即使激活失败也继续尝试播报
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = rate
        utterance.volume = volume
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        
        print("开始语音播报: \(text)")
        synthesizer.speak(utterance)
    }
    
    /// 播报当前时间
    func speakCurrentTime() {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        
        // 根据小时确定时间段
        let period: String
        switch hour {
        case 0..<6:
            period = "凌晨"     // 0:00-5:59
        case 6..<12:
            period = "上午"     // 6:00-11:59
        case 12..<18:
            period = "下午"     // 12:00-17:59
        case 18..<24:
            period = "晚上"     // 18:00-23:59
        default:
            period = "凌晨"     // 默认值（不应该达到）
        }
        
        // 格式化时间播报：当前时间下午14点43分
        let timeString = "当前时间\(period)\(hour)点\(minute)分"
        speak(timeString)
    }
    
    /// 播报计时器设置
    /// - Parameters:
    ///   - duration: 计时时长（分钟）
    ///   - interval: 提醒间隔（分钟）
    func speakTimerSettings(duration: Int, interval: Int) {
        let text = "计时时长\(duration)分钟，提醒间隔\(interval)分钟"
        speak(text)
    }
    
    /// 播报剩余时间
    /// - Parameter remainingSeconds: 剩余秒数
    func speakRemainingTime(remainingSeconds: Int) {
        let hours = remainingSeconds / 3600
        let remainingSecondsAfterHours = remainingSeconds % 3600
        // 向上取整分钟数，如果有任何秒数都算作1分钟
        let minutes = (remainingSecondsAfterHours + 59) / 60
        
        var text = "剩余时间"
        if hours > 0 {
            text += "\(hours)小时"
        }
        if minutes > 0 || hours == 0 {
            text += "\(minutes)分钟"
        }
        
        speak(text)
    }
    
    /// 播报计时器状态变化
    /// - Parameter action: 操作类型（开始、暂停、恢复、结束）
    func speakTimerAction(_ action: String) {
        speak(action)
    }
    
    /// 播报语音识别结果反馈
    /// - Parameter feedback: 反馈内容
    func speakVoiceRecognitionFeedback(_ feedback: String) {
        speak(feedback)
    }
    
    /// 停止当前播报
    func stopSpeaking() {
        if isCurrentlySpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
    
    // MARK: - Private Methods
    
    /// 配置音频会话
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // 配置最高优先级的音频会话 - 不与其他应用混合，独占音频
            if #available(iOS 16.0, *) {
                // iOS 16+ 使用spoken audio模式，独占音频会话
                do {
                    try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers, .allowBluetooth, .allowBluetoothA2DP, .allowAirPlay])
                    print("使用最高优先级 spokenAudio 模式配置成功")
                } catch {
                    // 如果spoken audio模式失败，使用独占播放模式
                    try audioSession.setCategory(.playback, options: [.duckOthers, .allowBluetooth, .allowBluetoothA2DP, .allowAirPlay])
                    print("降级使用独占 playback 模式配置")
                }
            } else {
                // iOS 15.6+ 使用独占播放模式
                try audioSession.setCategory(.playback, options: [.duckOthers, .allowBluetooth, .allowBluetoothA2DP, .allowAirPlay])
                print("使用独占 playback 模式配置（iOS 15.6+）")
            }
            
            // 立即激活音频会话，使用 notifyOthersOnDeactivation 确保其他应用能恢复
            try audioSession.setActive(true, options: [.notifyOthersOnDeactivation])
            print("音频会话配置成功 - 独占模式，最高优先级后台播报")
            
        } catch {
            print("音频会话配置失败: \(error.localizedDescription)")
            // 继续初始化，语音合成可能仍然工作
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension SpeechHelper: AVSpeechSynthesizerDelegate {
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        isCurrentlySpeaking = true
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isCurrentlySpeaking = false
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isCurrentlySpeaking = false
    }
}