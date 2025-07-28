import SwiftUI

/// 主要操作按钮区域
/// 第一行：时间播报、开始计时/暂停计时
/// 第二行：剩余时间、结束计时
/// 第三行：语音识别按钮（大圆形）
struct MainControlButtonsView: View {
    
    @ObservedObject var viewModel: TimerViewModel
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .center, spacing: 16) {
                // 第一行按钮
                HStack(spacing: 16) {
                    // 时间播报按钮
                    ControlButton(
                        title: "时间播报",
                        systemImage: "clock.fill",
                        backgroundColor: .gray,
                        buttonHeight: calculateButtonHeight(for: geometry),
                        isMainButton: true
                    ) {
                        handleTimeAnnouncement()
                    }
                    
                    // 开始计时/暂停计时按钮
                    ControlButton(
                        title: viewModel.isRunning ? "暂停计时" : "开始计时",
                        systemImage: viewModel.isRunning ? "pause.fill" : "play.fill",
                        backgroundColor: .gray,
                        buttonHeight: calculateButtonHeight(for: geometry),
                        isMainButton: true
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
                        backgroundColor: .gray,
                        buttonHeight: calculateButtonHeight(for: geometry),
                        isMainButton: true
                    ) {
                        handleRemainingTime()
                    }
                    
                    // 结束计时按钮
                    ControlButton(
                        title: "结束计时",
                        systemImage: "stop.fill",
                        backgroundColor: .gray,
                        buttonHeight: calculateButtonHeight(for: geometry),
                        isMainButton: true
                    ) {
                        handleEndTimer()
                    }
                }
                
                // 第三行：语音识别按钮
                VoiceRecognitionButton(viewModel: viewModel)
            }
            .padding(.top, 16)
        }
    }
    
    /// 根据设备尺寸计算按钮高度
    /// 主控制按钮高度 = 语音识别按钮高度的1/2
    private func calculateButtonHeight(for geometry: GeometryProxy) -> CGFloat {
        let voiceButtonHeight: CGFloat = 180
        return voiceButtonHeight / 2 // 90像素
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
    let buttonHeight: CGFloat
    let isMainButton: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    init(title: String, systemImage: String, backgroundColor: Color, action: @escaping () -> Void) {
        // 向后兼容的初始化器（用于语音识别按钮等）
        self.title = title
        self.systemImage = systemImage
        self.backgroundColor = backgroundColor
        self.buttonHeight = 80
        self.isMainButton = false
        self.action = action
    }
    
    init(title: String, systemImage: String, backgroundColor: Color, buttonHeight: CGFloat, isMainButton: Bool, action: @escaping () -> Void) {
        // 新的初始化器，支持自定义高度
        self.title = title
        self.systemImage = systemImage
        self.backgroundColor = backgroundColor
        self.buttonHeight = buttonHeight
        self.isMainButton = isMainButton
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: isMainButton ? 24 : 24, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.white, .white.opacity(0.9)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                
                Text(title)
                    .font(.system(size: isMainButton ? 16 : 14, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.white, .white.opacity(0.9)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
            }
            .frame(maxWidth: .infinity, minHeight: buttonHeight, maxHeight: buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                getGradientColors().0,
                                getGradientColors().1
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        .white.opacity(0.3),
                                        .clear
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .accessibilityLabel(title)
        .accessibilityHint("双击执行\(title)操作")
        .accessibilityAddTraits(.isButton)
    }
    
    /// 根据按钮类型获取渐变色
    private func getGradientColors() -> (Color, Color) {
        switch title {
        case "时间播报":
            return (Color.blue, Color.blue.opacity(0.8))
        case "开始计时", "暂停计时":
            return (Color.green, Color.green.opacity(0.8))
        case "剩余时间":
            return (Color.orange, Color.orange.opacity(0.8))
        case "结束计时":
            return (Color.red, Color.red.opacity(0.8))
        default:
            return (Color.gray, Color.gray.opacity(0.8))
        }
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