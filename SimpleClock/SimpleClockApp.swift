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
                    requestPermissions()
                }
        }
    }
    
    /// 请求应用所需的权限
    private func requestPermissions() {
        // 延迟请求权限，给用户更好的体验
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.requestNotificationPermission()
        }
        
        // 语音识别权限将在用户首次使用语音功能时请求
        // 这样提供更好的用户体验和权限请求上下文
    }
    
    /// 请求通知权限
    private func requestNotificationPermission() {
        // 检查iOS版本兼容性
        if #available(iOS 16.0, *) {
            // iOS 16+ 可能有更多通知选项
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge, .provisional]) { granted, error in
                self.handleNotificationPermissionResult(granted: granted, error: error)
            }
        } else {
            // iOS 15.6+ 兼容版本
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                self.handleNotificationPermissionResult(granted: granted, error: error)
            }
        }
    }
    
    /// 处理通知权限请求结果
    private func handleNotificationPermissionResult(granted: Bool, error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                print("通知权限请求失败: \(error.localizedDescription)")
            } else {
                print("通知权限\(granted ? "已授权" : "被拒绝")")
                if !granted {
                    print("用户可以稍后在设置中启用通知以接收计时提醒")
                }
            }
        }
    }
}
