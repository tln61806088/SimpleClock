import UIKit

/// 震动反馈工具类，专为无障碍用户设计
class HapticHelper {
    
    /// 单例实例
    static let shared = HapticHelper()
    
    private let impactGenerator = UIImpactFeedbackGenerator(style: .light)
    
    private init() {
        // 预准备震动生成器以减少延迟
        impactGenerator.prepare()
    }
    
    /// 提供轻微震动反馈
    /// 用于按钮点击、滚轮停止、语音识别开始/结束等操作
    func lightImpact() {
        print("HapticHelper: 触发轻微震动")
        
        // 在主线程上执行震动操作
        DispatchQueue.main.async {
            // 创建新的震动生成器实例，避免重用问题
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()
        }
    }
    
    /// 为滚轮选择器提供震动反馈
    /// 当用户滚动到5分钟倍数时触发
    func pickerImpact() {
        lightImpact()
    }
    
    /// 为语音识别提供震动反馈
    /// 按下和松开语音识别按钮时使用
    func voiceRecognitionImpact() {
        lightImpact()
    }
}