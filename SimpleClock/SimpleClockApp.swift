//
//  SimpleClockApp.swift
//  SimpleClock
//
//  Created by 孙凡 on 2025/7/24.
//

import SwiftUI
import UserNotifications
import Speech
import BackgroundTasks

// 应用代理类，处理方向控制
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        // iPad支持竖屏和横屏，iPhone只支持竖屏
        if UIDevice.current.userInterfaceIdiom == .pad {
            return [.portrait, .landscapeLeft, .landscapeRight]
        } else {
            return .portrait
        }
    }
}

@main
struct SimpleClockApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .onAppear {
                    requestAllPermissions()
                }
        }
    }
    
    /// 请求应用所需的所有权限
    private func requestAllPermissions() {
        // 立即激活音频会话（遵循iOS最佳实践）
        AudioSessionManager.shared.activateAudioSession()
        
        // 注册后台任务
        registerBackgroundTasks()
        
        // 立即请求所有权限，不延迟
        // 1. 请求通知权限
        requestNotificationPermission()
        
        // 2. 请求语音识别权限
        requestSpeechRecognitionPermission()
        
        // 3. 请求麦克风权限  
        requestMicrophonePermission()
        
        // 4. 检查并提示后台运行权限
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.checkBackgroundAppRefreshPermission()
        }
        
        // 注意：不再自动启动音乐播放
        // 音乐播放将在计时器启动时开始
    }
    
    /// 注册后台任务
    private func registerBackgroundTasks() {
        // 注册音频播放后台任务
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.sunfan.SimpleClock.audio-playback", using: nil) { task in
            self.handleAudioPlaybackTask(task: task as! BGProcessingTask)
        }
        
        // 注册应用刷新后台任务  
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.sunfan.SimpleClock.background-refresh", using: nil) { task in
            self.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
        }
    }
    
    /// 处理音频播放后台任务
    private func handleAudioPlaybackTask(task: BGProcessingTask) {
        // 确保音频会话保持活跃
        AudioSessionManager.shared.activateAudioSession()
        
        // 检查并恢复音频播放
        ContinuousAudioPlayer.shared.ensureBackgroundPlayback()
        
        task.setTaskCompleted(success: true)
    }
    
    /// 处理后台刷新任务
    private func handleBackgroundRefresh(task: BGAppRefreshTask) {
        // 确保计时器状态正确
        task.setTaskCompleted(success: true)
    }
    
    /// 请求通知权限
    private func requestNotificationPermission() {
        // 首先注册通知类别（支持自定义图标和操作）
        setupNotificationCategories()
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ 通知权限请求失败: \(error.localizedDescription)")
                } else {
                    print("📱 通知权限请求结果: \(granted ? "✅ 已授权" : "❌ 被拒绝")")
                    if !granted {
                        self.showPermissionAlert(title: "通知权限", message: "为了在后台提醒您计时结束，请在设置中开启通知权限")
                    }
                }
            }
        }
    }
    
    /// 设置通知类别和图标
    private func setupNotificationCategories() {
        let center = UNUserNotificationCenter.current()
        
        // 定义通知操作
        let stopAction = UNNotificationAction(
            identifier: "STOP_TIMER",
            title: "停止计时",
            options: [.foreground]
        )
        
        let extendAction = UNNotificationAction(
            identifier: "EXTEND_TIMER",
            title: "延长5分钟",
            options: []
        )
        
        // 创建计时提醒类别
        let timerCategory = UNNotificationCategory(
            identifier: "TIMER_NOTIFICATION",
            actions: [stopAction, extendAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        // 创建计时完成类别
        let completionCategory = UNNotificationCategory(
            identifier: "TIMER_COMPLETION",
            actions: [stopAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        // 注册类别
        center.setNotificationCategories([timerCategory, completionCategory])
        
        print("📱 通知类别设置完成 - 支持自定义操作和图标")
    }
    
    /// 请求语音识别权限
    private func requestSpeechRecognitionPermission() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    print("🎤 语音识别权限：✅ 已授权")
                case .denied:
                    print("🎤 语音识别权限：❌ 被拒绝")
                    self.showPermissionAlert(title: "语音识别权限", message: "为了使用语音指令控制计时器，请在设置中开启语音识别权限")
                case .restricted:
                    print("🎤 语音识别权限：⚠️ 受限制")
                case .notDetermined:
                    print("🎤 语音识别权限：❓ 未确定")
                @unknown default:
                    print("🎤 语音识别权限：❓ 未知状态")
                }
            }
        }
    }
    
    /// 请求麦克风权限
    private func requestMicrophonePermission() {
        Task {
            let granted = await AudioSessionManager.shared.requestRecordPermission()
            DispatchQueue.main.async {
                print("🎙️ 麦克风权限：\(granted ? "✅ 已授权" : "❌ 被拒绝")")
                if !granted {
                    self.showPermissionAlert(title: "麦克风权限", message: "为了使用语音识别功能，请在设置中开启麦克风权限")
                }
            }
        }
    }
    
    /// 检查后台App刷新权限
    private func checkBackgroundAppRefreshPermission() {
        let backgroundRefreshStatus = UIApplication.shared.backgroundRefreshStatus
        
        switch backgroundRefreshStatus {
        case .available:
            print("🔄 后台App刷新：✅ 已开启")
        case .denied:
            print("🔄 后台App刷新：❌ 被拒绝")
            showBackgroundPermissionAlert()
        case .restricted:
            print("🔄 后台App刷新：⚠️ 受限制")
            showBackgroundPermissionAlert()
        @unknown default:
            print("🔄 后台App刷新：❓ 未知状态")
        }
    }
    
    /// 显示后台权限提示
    private func showBackgroundPermissionAlert() {
        print("⚠️ 重要提示：后台App刷新权限")
        print("📱 为了确保计时器在后台正常工作，请开启后台App刷新：")
        print("📍 步骤 1：打开 设置 > 通用 > 后台App刷新")
        print("📍 步骤 2：确保 后台App刷新 总开关已开启")
        print("📍 步骤 3：找到 SimpleClock 并开启")
        print("🎵 这样音乐播放和计时器就能在后台正常工作了！")
    }
    
    /// 显示权限提示对话框
    private func showPermissionAlert(title: String, message: String) {
        // 这里可以添加更复杂的UI提示，暂时使用print
        print("⚠️ 权限提示 - \(title): \(message)")
        print("📱 请前往：设置 > SimpleClock > 开启相应权限")
    }
}
