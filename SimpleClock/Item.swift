//
//  Item.swift
//  SimpleClock
//
//  Created by 孙凡 on 2025/7/24.
//

import Foundation

// 简单的数据模型，不依赖SwiftData以保证iOS 15.5兼容性
final class Item: ObservableObject, Identifiable {
    let id = UUID()
    @Published var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
