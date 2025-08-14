import UIKit
import AudioToolbox

/// 震动反馈工具类，专为无障碍用户设计
class HapticHelper {
    
    /// 单例实例
    static let shared = HapticHelper()
    
    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    private init() {
        // 预准备震动生成器以减少延迟
        lightGenerator.prepare()
        mediumGenerator.prepare()
    }
    
    /// 提供轻微震动反馈
    /// 用于按钮点击、滚轮停止等操作
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
    
    /// 提供中等强度震动反馈
    /// 用于语音识别开始/结束等重要操作
    func mediumImpact() {
        print("HapticHelper: 触发中等震动")
        
        // 强制在主线程上立即执行震动操作
        if Thread.isMainThread {
            triggerMediumImpactDirectly()
        } else {
            DispatchQueue.main.sync {
                triggerMediumImpactDirectly()
            }
        }
    }
    
    /// 直接触发中等强度震动，确保成功执行
    private func triggerMediumImpactDirectly() {
        // 方法1：使用预准备的生成器
        mediumGenerator.prepare()
        mediumGenerator.impactOccurred()
        
        // 方法2：创建新的生成器实例作为备用
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            let backupGenerator = UIImpactFeedbackGenerator(style: .medium)
            backupGenerator.prepare()
            backupGenerator.impactOccurred()
        }
        
        // 方法3：使用系统级震动作为最后保障
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
    }
    
    /// 为滚轮选择器提供震动反馈
    /// 当用户滚动到5分钟倍数时触发
    func pickerImpact() {
        lightImpact()
    }
    
    /// 为语音识别开始提供震动反馈
    /// 点击开始录音时使用强化震动，确保在计时任务时也能正常工作
    func voiceRecognitionStartImpact() {
        print("HapticHelper: 语音识别开始震动 - 强化模式")
        forceVibration()
    }
    
    /// 为语音识别结束提供震动反馈
    /// 停止录音时使用强化震动，确保在计时任务时也能正常工作
    func voiceRecognitionEndImpact() {
        print("HapticHelper: 语音识别结束震动 - 强化模式")
        forceVibration()
    }
    
    /// 为语音识别完成提供震动反馈
    /// 识别出结果并开始执行时使用强化震动，确保在计时任务时也能正常工作
    func voiceRecognitionCompleteImpact() {
        print("HapticHelper: 语音识别完成震动 - 强化模式")
        forceVibration()
    }
    
    /// 强制震动 - 多重保障确保在任何情况下都能震动
    private func forceVibration() {
        // 强制在主线程上立即执行
        if Thread.isMainThread {
            executeForceVibration()
        } else {
            DispatchQueue.main.sync {
                executeForceVibration()
            }
        }
    }
    
    /// 执行强制震动的具体实现
    private func executeForceVibration() {
        // 方法1：立即使用预准备的生成器
        mediumGenerator.prepare()
        mediumGenerator.impactOccurred()
        
        // 方法2：立即创建新的生成器
        let immediateGenerator = UIImpactFeedbackGenerator(style: .medium)
        immediateGenerator.prepare()
        immediateGenerator.impactOccurred()
        
        // 方法3：系统级震动保障
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        
        // 方法4：延迟备用震动，防止第一次失效
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            let delayedGenerator = UIImpactFeedbackGenerator(style: .heavy)
            delayedGenerator.prepare()
            delayedGenerator.impactOccurred()
        }
    }
    
    /// 为选择操作提供震动反馈
    /// 用于颜色主题选择等选择操作
    func selectionImpact() {
        print("HapticHelper: 触发选择震动")
        
        DispatchQueue.main.async {
            let generator = UISelectionFeedbackGenerator()
            generator.prepare()
            generator.selectionChanged()
        }
    }
    
    /// 兼容旧版本的语音识别震动方法
    func voiceRecognitionImpact() {
        mediumImpact()
    }
}