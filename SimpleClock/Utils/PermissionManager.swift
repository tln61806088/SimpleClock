import Foundation
import UIKit
import AVFoundation
import UserNotifications
import Speech

/// 权限管理器 - 申请应用所需的最高权限
class PermissionManager: NSObject {
    
    /// 单例实例
    static let shared = PermissionManager()
    
    // 后台任务标识符
    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = .invalid
    
    private override init() {
        super.init()
        setupBackgroundTaskHandling()
    }
    
    /// 申请所有必要权限
    func requestAllPermissions() {
        print("开始申请所有必要权限...")
        
        // 1. 申请麦克风权限
        requestMicrophonePermission()
        
        // 2. 申请语音识别权限
        requestSpeechRecognitionPermission()
        
        // 3. 申请通知权限
        requestNotificationPermission()
        
        // 4. 配置最高优先级音频会话
        configureHighestPriorityAudioSession()
        
        // 5. 申请后台应用刷新权限
        requestBackgroundAppRefresh()
        
        print("权限申请完成")
    }
    
    /// 申请麦克风权限
    private func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    print("✅ 麦克风权限已获得")
                } else {
                    print("❌ 麦克风权限被拒绝")
                    self.showPermissionAlert(
                        title: "需要麦克风权限",
                        message: "SimpleClock需要使用麦克风进行语音识别。请在设置中允许麦克风访问以获得最佳体验。"
                    )
                }
            }
        }
    }
    
    /// 申请语音识别权限
    private func requestSpeechRecognitionPermission() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    print("✅ 语音识别权限已获得")
                case .denied:
                    print("❌ 语音识别权限被拒绝")
                    self.showPermissionAlert(
                        title: "需要语音识别权限", 
                        message: "SimpleClock需要语音识别功能来理解您的语音指令。请在设置中允许语音识别以获得完整功能。"
                    )
                case .restricted, .notDetermined:
                    print("⚠️ 语音识别权限受限或未确定")
                @unknown default:
                    print("⚠️ 语音识别权限状态未知")
                }
            }
        }
    }
    
    /// 申请通知权限
    private func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge, .criticalAlert]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("✅ 通知权限已获得（包括紧急通知）")
                } else {
                    print("❌ 通知权限被拒绝")
                    if let error = error {
                        print("通知权限错误: \(error.localizedDescription)")
                    }
                    self.showPermissionAlert(
                        title: "需要通知权限",
                        message: "SimpleClock需要发送通知来提醒您计时进度。请在设置中允许通知以确保不错过重要提醒。"
                    )
                }
            }
        }
    }
    
    /// 配置最高优先级音频会话
    private func configureHighestPriorityAudioSession() {
        do {
            // 使用AudioSessionManager统一管理音频会话，避免冲突
            AudioSessionManager.shared.activateAudioSession()
            print("✅ 使用统一音频会话管理")
        } catch {
            print("❌ 音频会话激活失败: \(error.localizedDescription)")
        }
    }
    
    /// 申请后台应用刷新权限
    private func requestBackgroundAppRefresh() {
        // 检查当前后台应用刷新状态
        let backgroundRefreshStatus = UIApplication.shared.backgroundRefreshStatus
        
        switch backgroundRefreshStatus {
        case .available:
            print("✅ 后台应用刷新可用")
        case .denied:
            print("❌ 后台应用刷新被拒绝")
            showPermissionAlert(
                title: "需要后台应用刷新权限",
                message: "为了确保SimpleClock在后台正常工作，请在设置 > 通用 > 后台App刷新中启用此应用的后台刷新功能。"
            )
        case .restricted:
            print("⚠️ 后台应用刷新受限")
        @unknown default:
            print("⚠️ 后台应用刷新状态未知")
        }
    }
    
    /// 开始后台任务以保持应用活跃
    func beginBackgroundTask() {
        // 结束之前的后台任务
        if backgroundTaskIdentifier != .invalid {
            endBackgroundTask()
        }
        
        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "SimpleClock-Timer") {
            // 后台任务即将到期时的处理
            print("⚠️ 后台任务即将到期，正在清理...")
            self.endBackgroundTask()
        }
        
        if backgroundTaskIdentifier != .invalid {
            print("✅ 后台任务已开始，标识符: \(backgroundTaskIdentifier.rawValue)")
        } else {
            print("❌ 无法开始后台任务")
        }
    }
    
    /// 结束后台任务
    func endBackgroundTask() {
        if backgroundTaskIdentifier != .invalid {
            print("🔚 结束后台任务，标识符: \(backgroundTaskIdentifier.rawValue)")
            UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
            backgroundTaskIdentifier = .invalid
        }
    }
    
    /// 设置后台任务处理
    private func setupBackgroundTaskHandling() {
        // 监听应用进入后台
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        // 监听应用将要进入前台
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc private func appDidEnterBackground() {
        print("📱 应用进入后台，开始后台任务")
        beginBackgroundTask()
        
        // 重新配置音频会话以确保后台播放
        configureHighestPriorityAudioSession()
    }
    
    @objc private func appWillEnterForeground() {
        print("📱 应用将要进入前台")
        // 不需要立即结束后台任务，让其自然过期或在适当时机结束
        
        // 重新配置音频会话
        configureHighestPriorityAudioSession()
    }
    
    /// 显示权限申请提示
    private func showPermissionAlert(title: String, message: String) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            print("无法获取当前窗口")
            return
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "前往设置", style: .default) { _ in
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        })
        
        alert.addAction(UIAlertAction(title: "稍后", style: .cancel))
        
        window.rootViewController?.present(alert, animated: true)
    }
    
    /// 检查所有权限状态
    func checkAllPermissions() -> [String: Bool] {
        var permissions: [String: Bool] = [:]
        
        // 麦克风权限
        permissions["microphone"] = AVAudioSession.sharedInstance().recordPermission == .granted
        
        // 语音识别权限
        permissions["speechRecognition"] = SFSpeechRecognizer.authorizationStatus() == .authorized
        
        // 后台刷新权限
        permissions["backgroundRefresh"] = UIApplication.shared.backgroundRefreshStatus == .available
        
        return permissions
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        endBackgroundTask()
    }
}