import AVFoundation

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
    }
    
    /// 播报文本内容
    /// - Parameter text: 要播报的文本
    /// - Parameter rate: 语速，默认为正常速度
    /// - Parameter volume: 音量，默认为1.0
    func speak(_ text: String, rate: Float = AVSpeechUtteranceDefaultSpeechRate, volume: Float = 1.0) {
        // 如果正在播报，先停止当前播报
        if isCurrentlySpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = rate
        utterance.volume = volume
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        
        synthesizer.speak(utterance)
    }
    
    /// 播报当前时间
    func speakCurrentTime() {
        let formatter = DateFormatter()
        formatter.dateFormat = "H时m分s秒"
        let timeString = "当前时间" + formatter.string(from: Date())
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
            
            // 使用简单的配置，避免参数错误
            if #available(iOS 16.0, *) {
                // iOS 16+ 尝试使用spoken audio模式
                do {
                    try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
                } catch {
                    // 如果spoken audio模式失败，降级到基础模式
                    try audioSession.setCategory(.playback, options: [.duckOthers])
                }
            } else {
                // iOS 15.6+ 使用基础配置
                try audioSession.setCategory(.playback, options: [.duckOthers])
            }
            
            // 延迟激活音频会话，避免冲突
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                do {
                    try audioSession.setActive(true, options: [])
                } catch {
                    print("音频会话激活失败: \(error.localizedDescription)")
                }
            }
            
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