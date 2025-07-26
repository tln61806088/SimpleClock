//
//  SimpleClockApp.swift
//  SimpleClock
//
//  Created by 孙凡 on 2025/7/24.
//

import SwiftUI
import UserNotifications
import Speech

@main
struct SimpleClockApp: App {
    
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
        
        // 延迟请求权限，给用户更好的体验
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // 请求通知权限
            self.requestNotificationPermission()
            
            // 注意：不再自动启动音乐播放
            // 音乐播放将在计时器启动时开始
        }
    }
    
    /// 请求通知权限
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("通知权限请求失败: \(error.localizedDescription)")
            } else {
                print("通知权限请求结果: \(granted ? "已授权" : "被拒绝")")
            }
        }
    }
}
