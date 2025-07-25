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
        // 延迟请求权限，给用户更好的体验
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // 使用权限管理器申请所有必要权限
            PermissionManager.shared.requestAllPermissions()
        }
    }
}
