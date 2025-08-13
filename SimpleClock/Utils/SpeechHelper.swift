//
//  SpeechHelper.swift
//  SimpleClock
//
//  更新支持后台音频播放的语音播报工具类
//

import AVFoundation
import UIKit
import os.log

/// 语音播报工具类，专为无障碍用户设计，支持后台音频播放
class SpeechHelper: NSObject, @unchecked Sendable {
    
    /// 单例实例
    static let shared = SpeechHelper()
    
    private let synthesizer = AVSpeechSynthesizer()
    private var isCurrentlySpeaking = false
    private var isHighPrioritySpeaking = false  // 高优先级播报标记
    private var speechCompletionHandler: (() -> Void)?
    private let logger = Logger(subsystem: "SimpleClock", category: "SpeechHelper")
    
    // 移除后台任务管理，由PermissionManager统一处理
    // 使用lazy初始化避免主线程警告
    private lazy var audioSessionManager = AudioSessionManager.shared
    
    private override init() {
        super.init()
        synthesizer.delegate = self
        
        // 使用AudioSessionManager进行音频会话管理
        setupAudioSessionManager()
        
        // 设置应用生命周期监听
        setupAppLifecycleHandling()
        
        // 启动静音状态监听器
        _ = SilentModeDetector.shared
        
        // 监听静音状态变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(silentModeChanged),
            name: .silentModeChanged,
            object: nil
        )
    }
    
    /// 使用AudioSessionManager配置音频会话
    private func setupAudioSessionManager() {
        // 激活音频会话以支持后台播放
        audioSessionManager.activateAudioSession()
        logger.info("使用AudioSessionManager配置音频会话")
    }
    
    /// 设置应用生命周期处理
    private func setupAppLifecycleHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterBackground),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func appWillEnterBackground() {
        logger.info("应用进入后台，确保音频会话保持活跃")
        // 只在音频会话未激活时才激活
        if !audioSessionManager.isAudioSessionActive {
            audioSessionManager.activateAudioSession()
        }
        
        // 不需要手动管理后台任务，音频类别已支持后台播放
    }
    
    @objc private func appWillEnterForeground() {
        logger.info("应用回到前台")
        // 只在音频会话未激活时才激活
        if !audioSessionManager.isAudioSessionActive {
            audioSessionManager.activateAudioSession()
        }
        
        // 不需要手动管理后台任务
    }
    
    // 已移除后台任务管理函数，由PermissionManager统一处理
    
    // 静音状态缓存，避免频繁检测
    private var lastSilentCheckTime: Date = Date.distantPast
    private var cachedSilentMode: Bool = false
    private let silentCheckCooldown: TimeInterval = 2.0  // 2秒内不重复检测
    
    /// 检测设备是否处于静音状态（缓存机制避免频繁检测）
    private func isSilentModeEnabled() -> Bool {
        let now = Date()
        
        // 如果距离上次检测不超过2秒，使用缓存结果
        if now.timeIntervalSince(lastSilentCheckTime) < silentCheckCooldown {
            return cachedSilentMode
        }
        
        // 执行检测并更新缓存
        SilentModeDetector.shared.checkSilentModeNow()
        cachedSilentMode = SilentModeDetector.shared.isSilentMode
        lastSilentCheckTime = now
        
        return cachedSilentMode
    }
    
    /// 为锁屏状态配置音频会话
    private func configureAudioSessionForLockScreen() {
        // 使用AudioSessionManager统一管理，临时切换到语音模式
        AudioSessionManager.shared.enableSpeechMode()
        logger.info("🔒 锁屏TTS使用统一音频会话管理")
    }
    
    /// 播报文本内容 - 支持锁屏状态下的后台播放
    /// - Parameter text: 要播报的文本
    /// - Parameter rate: 语速，默认为正常速度
    /// - Parameter volume: 音量，默认为1.0
    func speak(_ text: String, rate: Float = AVSpeechUtteranceDefaultSpeechRate, volume: Float = 1.0) {
        // 检查静音状态
        if isSilentModeEnabled() {
            logger.info("设备处于静音状态（动态检测），跳过语音播报: \(text)")
            return
        }
        
        // 如果正在播报，先停止当前播报
        if isCurrentlySpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        // 强制配置音频会话以支持锁屏TTS
        configureAudioSessionForLockScreen()
        
        // 只在音频会话未激活时才激活（避免重复激活导致卡顿）
        if !audioSessionManager.isAudioSessionActive {
            audioSessionManager.activateAudioSession()
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = rate
        utterance.volume = volume
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        
        logger.info("开始语音播报: \(text)")
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
        let intervalText = interval == 0 ? "不提醒" : "间隔\(interval)分钟"
        let text = "计时\(duration)分钟，\(intervalText)"
        speak(text)
    }
    
    /// 播报剩余时长
    /// - Parameter remainingSeconds: 剩余秒数
    func speakRemainingTime(remainingSeconds: Int) {
        let hours = remainingSeconds / 3600
        let remainingSecondsAfterHours = remainingSeconds % 3600
        // 向上取整分钟数，如果有任何秒数都算作1分钟
        let minutes = (remainingSecondsAfterHours + 59) / 60
        
        var text = "剩余时长"
        if hours > 0 {
            text += "\(hours)小时"
            if minutes > 0 {
                text += "\(minutes)分钟"
            }
        } else {
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
    
    @objc private func silentModeChanged(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let isSilent = userInfo["isSilent"] as? Bool else {
            return
        }
        
        logger.info("静音状态变化通知: \(isSilent ? "静音" : "非静音")")
        
        // 立即更新缓存状态
        cachedSilentMode = isSilent
        lastSilentCheckTime = Date()
        
        if isSilent && isCurrentlySpeaking {
            // 切换到静音时，停止当前播报
            logger.info("切换到静音模式，停止当前语音播报")
            synthesizer.stopSpeaking(at: .immediate)
        }
        // 如果从静音切换到非静音，不需要特殊处理，下次播报时会自动检测
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension SpeechHelper: AVSpeechSynthesizerDelegate {
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        isCurrentlySpeaking = true
        logger.info("语音播报开始")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isCurrentlySpeaking = false
        logger.info("语音播报完成")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isCurrentlySpeaking = false
        logger.info("语音播报取消")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        logger.info("语音播报暂停")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        logger.info("语音播报恢复")
    }
}