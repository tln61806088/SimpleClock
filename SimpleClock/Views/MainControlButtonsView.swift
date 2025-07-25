import SwiftUI

/// 主要操作按钮区域
/// 第一行：时间播报、开始计时/暂停计时
/// 第二行：剩余时间、结束计时
/// 第三行：语音识别按钮（大圆形）
struct MainControlButtonsView: View {
    
    @ObservedObject var viewModel: TimerViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // 第一行按钮
            HStack(spacing: 16) {
                // 时间播报按钮
                ControlButton(
                    title: "时间播报",
                    systemImage: "clock.fill",
                    backgroundColor: .gray
                ) {
                    handleTimeAnnouncement()
                }
                
                // 开始计时/暂停计时按钮
                ControlButton(
                    title: viewModel.isRunning ? "暂停计时" : "开始计时",
                    systemImage: viewModel.isRunning ? "pause.fill" : "play.fill",
                    backgroundColor: .gray
                ) {
                    handleStartPauseTimer()
                }
            }
            
            // 第二行按钮
            HStack(spacing: 16) {
                // 剩余时间按钮
                ControlButton(
                    title: "剩余时间",
                    systemImage: "timer",
                    backgroundColor: .gray
                ) {
                    handleRemainingTime()
                }
                
                // 结束计时按钮
                ControlButton(
                    title: "结束计时",
                    systemImage: "stop.fill",
                    backgroundColor: .gray
                ) {
                    handleEndTimer()
                }
            }
            
            // 第三行：语音识别按钮占位
            // 实际的VoiceRecognitionButton将在主界面中单独放置
        }
    }
    
    // MARK: - 按钮操作处理
    
    /// 处理时间播报
    private func handleTimeAnnouncement() {
        HapticHelper.shared.lightImpact()
        SpeechHelper.shared.speakCurrentTime()
    }
    
    /// 处理开始/暂停计时
    private func handleStartPauseTimer() {
        HapticHelper.shared.lightImpact()
        
        if viewModel.isRunning {
            viewModel.pauseTimer()
            SpeechHelper.shared.speakTimerAction("暂停计时")
        } else {
            viewModel.startTimer()
            SpeechHelper.shared.speakTimerAction("开始计时")
        }
    }
    
    /// 处理剩余时间播报
    private func handleRemainingTime() {
        HapticHelper.shared.lightImpact()
        
        if viewModel.remainingSeconds == 0 && !viewModel.isRunning {
            // 未开始计时时，播报设置的计时时长
            let message = "当前尚未开始计时，设置的计时时长为\(viewModel.settings.duration)分钟"
            SpeechHelper.shared.speak(message)
        } else {
            // 已开始计时，播报剩余时间
            SpeechHelper.shared.speakRemainingTime(remainingSeconds: viewModel.remainingSeconds)
        }
    }
    
    /// 处理结束计时
    private func handleEndTimer() {
        HapticHelper.shared.lightImpact()
        viewModel.stopTimer()
        SpeechHelper.shared.speakTimerAction("结束计时")
    }
}

/// 统一的控制按钮样式
struct ControlButton: View {
    let title: String
    let systemImage: String
    let backgroundColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 80, maxHeight: 80)
            .background(backgroundColor)
            .cornerRadius(12)
        }
        .accessibilityLabel(title)
        .accessibilityHint("双击执行\(title)操作")
        .accessibilityAddTraits(.isButton)
    }
}

#if DEBUG
struct MainControlButtonsView_Previews: PreviewProvider {
    static var previews: some View {
        MainControlButtonsView(viewModel: TimerViewModel())
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
#endif