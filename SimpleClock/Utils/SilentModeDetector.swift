//
//  SilentModeDetector.swift
//  SimpleClock
//
//  简化的静音开关检测器 - 使用可靠的系统音量检测方法
//

import AVFoundation
import UIKit
import Combine
import os.log

/// 静音模式检测器 - 使用简单可靠的方法检测静音开关
class SilentModeDetector: ObservableObject {
    
    /// 单例实例
    static let shared = SilentModeDetector()
    
    /// 当前是否处于静音状态
    @Published private(set) var isSilentMode = false
    
    private let audioSession = AVAudioSession.sharedInstance()
    private let logger = Logger(subsystem: "SimpleClock", category: "SilentModeDetector")
    
    // 检测定时器 - 降低频率
    private var detectionTimer: Timer?
    
    // 防抖动 - 避免频繁状态切换
    private var lastDetectedSilent = false
    private var stableStateCount = 0
    private let stableThreshold = 2  // 需要连续2次相同结果才更新状态
    
    private init() {
        // 初始检测
        detectSilentModeSimple()
        
        // 启动低频率定时检测
        startPeriodicDetection()
        
        // 监听重要的音频事件
        setupNotifications()
    }
    
    /// 使用简单可靠的方法检测静音状态
    private func detectSilentModeSimple() {
        // 方法1：检查系统音量（最可靠的方法）
        let systemVolume = audioSession.outputVolume
        
        // 方法2：检查是否有音频输出路由
        let currentRoute = audioSession.currentRoute
        let hasAudioOutput = !currentRoute.outputs.isEmpty
        
        // 只有当系统音量为0时才认为是静音
        // 不再使用复杂的音频播放检测，因为会干扰正常播放
        let detectedSilent = (systemVolume == 0.0)
        
        logger.info("静音检测 - 系统音量: \(systemVolume), 有音频输出: \(hasAudioOutput), 检测结果: \(detectedSilent ? "静音" : "非静音")")
        
        // 防抖动处理
        if detectedSilent == lastDetectedSilent {
            stableStateCount += 1
        } else {
            stableStateCount = 0
            lastDetectedSilent = detectedSilent
        }
        
        // 只有状态稳定时才更新
        if stableStateCount >= stableThreshold {
            updateSilentMode(detectedSilent)
        }
    }
    
    /// 更新静音模式状态
    private func updateSilentMode(_ newSilentMode: Bool) {
        DispatchQueue.main.async {
            if self.isSilentMode != newSilentMode {
                self.isSilentMode = newSilentMode
                self.logger.info("✅ 静音状态确认变化: \(newSilentMode ? "静音" : "非静音")")
                
                // 发送状态变化通知
                NotificationCenter.default.post(
                    name: .silentModeChanged,
                    object: nil,
                    userInfo: ["isSilent": newSilentMode]
                )
            }
        }
    }
    
    /// 开始周期性检测（降低频率）
    private func startPeriodicDetection() {
        // 改为每2秒检测一次，减少频率
        detectionTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.detectSilentModeSimple()
        }
    }
    
    /// 设置通知监听（只监听重要事件）
    private func setupNotifications() {
        // 监听应用激活（用户可能在设置中改变了静音状态）
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        // 监听音频会话中断（可能与静音开关相关）
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(audioInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }
    
    @objc private func appDidBecomeActive() {
        logger.info("应用激活，立即检测静音状态")
        // 重置防抖动计数，立即检测
        stableStateCount = 0
        detectSilentModeSimple()
    }
    
    @objc private func audioInterruption(notification: Notification) {
        // 音频中断时也检测一次
        logger.info("音频中断，检测静音状态")
        detectSilentModeSimple()
    }
    
    /// 立即检测静音状态（供外部调用）
    func checkSilentModeNow() {
        stableStateCount = 0  // 重置防抖动
        detectSilentModeSimple()
    }
    
    deinit {
        detectionTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - 通知名称扩展
extension Notification.Name {
    static let silentModeChanged = Notification.Name("SilentModeChanged")
}