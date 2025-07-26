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
    
    /// 请求应用所需的所有权限并启动后台音频
    private func requestAllPermissions() {
        // 延迟请求权限，给用户更好的体验
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // 请求通知权限
            self.requestNotificationPermission()
            
            // 启动持续音频播放以维持后台会话
            ContinuousAudioPlayer.shared.startContinuousPlayback()
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
