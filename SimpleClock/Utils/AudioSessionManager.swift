//
//  AudioSessionManager.swift
//  SimpleClock
//
//  专门管理后台音频播放的AVAudioSession配置
//  支持语音播报在后台继续工作，就像地图导航应用一样
//

import AVFoundation
import UIKit
import os.log

class AudioSessionManager: ObservableObject {
    static let shared = AudioSessionManager()
    
    private let logger = Logger(subsystem: "SimpleClock", category: "AudioSession")
    private var audioSession: AVAudioSession
    
    // 音频会话状态
    @Published var isAudioSessionActive = false
    @Published var currentCategory: AVAudioSession.Category = .playback
    
    private init() {
        self.audioSession = AVAudioSession.sharedInstance()
        setupAudioSession()
        setupNotifications()
    }
    
    /// 配置音频会话以支持后台播放
    private func setupAudioSession() {
        do {
            // 重要：根据iOS最佳实践，使用.playback类别支持后台播放和锁屏控制
            try audioSession.setCategory(
                .playback,  // 播放类别，支持后台播放
                mode: .default,  // 使用默认模式，适合音乐播放和锁屏控制
                options: [
                    .allowAirPlay,  // 允许AirPlay
                    .allowBluetoothA2DP  // 允许蓝牙音频
                ]
            )
            
            currentCategory = .playback
            logger.info("音频会话配置成功：类别=播放，模式=默认（支持锁屏控制和AirPlay）")
            
        } catch {
            logger.error("配置音频会话失败: \(error.localizedDescription)")
        }
    }
    
    /// 激活音频会话
    func activateAudioSession() {
        do {
            try audioSession.setActive(true, options: [])
            isAudioSessionActive = true
            logger.info("音频会话激活成功")
        } catch {
            logger.error("激活音频会话失败: \(error.localizedDescription)")
            isAudioSessionActive = false
        }
    }
    
    /// 停用音频会话
    func deactivateAudioSession() {
        do {
            // 使用 notifyOthersOnDeactivation 选项，通知其他应用恢复音频
            try audioSession.setActive(false, options: [.notifyOthersOnDeactivation])
            isAudioSessionActive = false
            logger.info("音频会话停用成功")
        } catch {
            logger.error("停用音频会话失败: \(error.localizedDescription)")
        }
    }
    
    /// 请求录音权限（用于语音识别）
    func requestRecordPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            audioSession.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    /// 临时激活录音模式（语音识别时使用）
    func enableRecordingMode() {
        do {
            // 临时切换到播放和录音模式，用于语音识别
            try audioSession.setCategory(
                .playAndRecord,
                mode: .spokenAudio,  // 语音识别时使用spokenAudio模式
                options: [
                    .duckOthers,
                    .allowBluetooth,    // 允许蓝牙设备
                    .allowBluetoothA2DP // 允许蓝牙音频
                ]
            )
            currentCategory = .playAndRecord
            logger.info("切换到录音模式（语音识别）")
        } catch {
            logger.error("切换到录音模式失败: \(error.localizedDescription)")
        }
    }
    
    /// 恢复播放模式
    func restorePlaybackMode() {
        setupAudioSession()
    }
    
    /// 处理音频中断
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioInterruption),
            name: AVAudioSession.interruptionNotification,
            object: audioSession
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: audioSession
        )
        
        // 监听应用生命周期
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func handleAudioInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            logger.info("🎵 音频中断开始 - 音频会话将暂停")
            // 音频中断开始，标记会话状态但不主动停用
            isAudioSessionActive = false
            
        case .ended:
            logger.info("🎵 音频中断结束 - 检查是否应该恢复播放")
            // 音频中断结束，检查是否应该恢复
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    logger.info("🎵 系统建议恢复播放，重新激活音频会话")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.activateAudioSession()
                        NotificationCenter.default.post(name: .audioSessionResumed, object: nil)
                    }
                } else {
                    logger.info("🎵 系统不建议恢复播放，等待手动恢复")
                }
            } else {
                // 没有恢复选项，延迟尝试恢复
                logger.info("🎵 没有恢复选项，延迟尝试重新激活音频会话")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.activateAudioSession()
                    NotificationCenter.default.post(name: .audioSessionResumed, object: nil)
                }
            }
            
        @unknown default:
            logger.warning("🎵 未知的音频中断类型")
        }
    }
    
    @objc private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        switch reason {
        case .oldDeviceUnavailable:
            logger.info("音频设备断开（如拔出耳机）")
            // 耳机拔出等情况，可能需要暂停播放
            
        case .newDeviceAvailable:
            logger.info("新音频设备可用（如插入耳机）")
            
        default:
            logger.info("音频路由改变：\(reason.rawValue)")
        }
    }
    
    @objc private func handleAppWillResignActive() {
        logger.info("应用即将进入后台")
        // 确保音频会话在后台保持活跃
        // 注意：进入后台时不要重新配置音频会话，这会导致-50错误
        // 只确保会话保持活跃
        if !isAudioSessionActive {
            activateAudioSession()
        }
        logger.info("🎵 后台音频会话保持活跃")
    }
    
    @objc private func handleAppDidBecomeActive() {
        logger.info("应用恢复活跃状态")
        // 确保音频会话正常工作
        if !isAudioSessionActive {
            activateAudioSession()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let audioSessionResumed = Notification.Name("audioSessionResumed")
}

// MARK: - 背景任务支持
extension AudioSessionManager {
    /// 开始后台任务（在长时间语音播报前调用）
    func beginBackgroundTask() -> UIBackgroundTaskIdentifier {
        let taskId = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.logger.warning("后台任务即将超时")
        }
        
        if taskId != .invalid {
            logger.info("后台任务开始：\(taskId.rawValue)")
        }
        
        return taskId
    }
    
    /// 结束后台任务
    func endBackgroundTask(_ taskId: UIBackgroundTaskIdentifier) {
        if taskId != .invalid {
            UIApplication.shared.endBackgroundTask(taskId)
            logger.info("后台任务结束：\(taskId.rawValue)")
        }
    }
}