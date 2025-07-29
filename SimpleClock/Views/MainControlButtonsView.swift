import SwiftUI

/// 主要操作按钮区域
/// 第一行：时间播报、开始计时/暂停计时
/// 第二行：剩余时长、结束计时
/// 第三行：语音识别按钮（大圆形）
struct MainControlButtonsView: View {
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject var viewModel: TimerViewModel
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .center, spacing: DesignSystem.Spacing.buttonSpacing) {
                // 第一行按钮
                HStack(spacing: DesignSystem.Spacing.buttonSpacing) {
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
                        title: viewModel.isRunning ? "暂停计时" : (viewModel.isPaused ? "恢复计时" : "开始计时"),
                        systemImage: viewModel.isRunning ? "pause.fill" : (viewModel.isPaused ? "play.fill" : "play.fill"),
                        backgroundColor: .gray,
                        buttonHeight: calculateButtonHeight(for: geometry),
                        isMainButton: true
                    ) {
                        handleStartPauseTimer()
                    }
                }
                
                // 第二行按钮
                HStack(spacing: DesignSystem.Spacing.buttonSpacing) {
                    // 剩余时长按钮
                    ControlButton(
                        title: "剩余时长",
                        systemImage: "timer.circle.fill",
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
            .padding(.top, DesignSystem.Spacing.buttonSpacing)
        }
    }
    
    /// 根据设备尺寸计算按钮高度
    /// 主控制按钮高度 = 语音识别按钮高度的1/1.75
    private func calculateButtonHeight(for geometry: GeometryProxy) -> CGFloat {
        return DesignSystem.Sizes.mainButtonHeight
    }
    
    // MARK: - 按钮操作处理
    
    /// 处理时间播报
    private func handleTimeAnnouncement() {
        HapticHelper.shared.lightImpact()
        //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        // 语音播报内容："当前时间[时间段][小时]点[分钟]分" (第83行)
        //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        SpeechHelper.shared.speakCurrentTime()
    }
    
    /// 处理开始/暂停计时
    private func handleStartPauseTimer() {
        HapticHelper.shared.lightImpact()
        
        if viewModel.isRunning {
            viewModel.pauseTimer()
            //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            // 语音播报内容："暂停计时" (第92行)
            //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            SpeechHelper.shared.speakTimerAction("暂停计时")
        } else if viewModel.isPaused {
            // 恢复计时
            viewModel.startTimer()
            //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            // 语音播报内容："恢复计时"
            //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            SpeechHelper.shared.speakTimerAction("恢复计时")
        } else {
            // 全新开始计时
            viewModel.startTimer()
            // 播报开始计时和剩余时长，使用连贯的播报
            let hours = viewModel.remainingSeconds / 3600
            let remainingSecondsAfterHours = viewModel.remainingSeconds % 3600
            let minutes = (remainingSecondsAfterHours + 59) / 60
            
            var message = "开始计时， 剩余时长"
            if hours > 0 {
                message += "\(hours)小时"
                if minutes > 0 {
                    message += "\(minutes)分钟"
                }
            } else {
                message += "\(minutes)分钟"
            }
            
            // 添加间隔信息
            message += "，间隔"
            let interval = viewModel.settings.interval
            if interval == 0 {
                message += "不提醒"
            } else if interval < 60 {
                message += "\(interval)分钟"
            } else if interval == 60 {
                message += "1小时"
            } else {
                let intervalHours = interval / 60
                let intervalMinutes = interval % 60
                message += "\(intervalHours)小时"
                if intervalMinutes > 0 {
                    message += "\(intervalMinutes)分钟"
                }
            }
            
            //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            // 语音播报内容：统一为连续播报，与语音识别保持一致
            //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            SpeechHelper.shared.speak(message)
        }
    }
    
    /// 处理剩余时长播报
    private func handleRemainingTime() {
        HapticHelper.shared.lightImpact()
        
        if viewModel.remainingSeconds > 0 {
            // 有计时任务运行时，播报剩余时间
            //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            // 语音播报内容："剩余时长[X]小时[X]分钟" (第136行)
            //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            SpeechHelper.shared.speakRemainingTime(remainingSeconds: viewModel.remainingSeconds)
        } else {
            // 无计时任务时，播报状态
            let message = "当前无计时任务"
            //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            // 语音播报内容："当前无计时任务" (第140行)
            //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            SpeechHelper.shared.speak(message)
        }
    }
    
    /// 处理结束计时
    private func handleEndTimer() {
        HapticHelper.shared.lightImpact()
        viewModel.stopTimer()
        //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        // 语音播报内容："结束计时" (第148行)
        //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        SpeechHelper.shared.speakTimerAction("结束计时")
    }
}

/// 统一的控制按钮样式
struct ControlButton: View {
    @ObservedObject private var themeManager = ThemeManager.shared
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
            VStack(spacing: DesignSystem.Spacing.iconTextSpacing) {
                Image(systemName: systemImage)
                    .font(DesignSystem.Fonts.buttonIcon(size: DesignSystem.Sizes.buttonIcon))
                    .foregroundStyle(themeManager.currentTheme.primaryGradient)
                    .shadow(color: DesignSystem.Shadows.primaryShadow.color,
                           radius: DesignSystem.Shadows.primaryShadow.radius,
                           x: DesignSystem.Shadows.primaryShadow.x,
                           y: DesignSystem.Shadows.primaryShadow.y)
                    .shadow(color: DesignSystem.Shadows.secondaryShadow.color,
                           radius: DesignSystem.Shadows.secondaryShadow.radius,
                           x: DesignSystem.Shadows.secondaryShadow.x,
                           y: DesignSystem.Shadows.secondaryShadow.y)
                
                Text(title)
                    .font(DesignSystem.Fonts.buttonText(size: DesignSystem.Sizes.buttonText))
                    .foregroundStyle(themeManager.currentTheme.primaryGradient)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .shadow(color: DesignSystem.Shadows.primaryShadow.color,
                           radius: DesignSystem.Shadows.primaryShadow.radius,
                           x: DesignSystem.Shadows.primaryShadow.x,
                           y: DesignSystem.Shadows.primaryShadow.y)
                    .shadow(color: DesignSystem.Shadows.secondaryShadow.color,
                           radius: DesignSystem.Shadows.secondaryShadow.radius,
                           x: DesignSystem.Shadows.secondaryShadow.x,
                           y: DesignSystem.Shadows.secondaryShadow.y)
            }
            .frame(maxWidth: .infinity, minHeight: buttonHeight, maxHeight: buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                    .stroke(themeManager.currentTheme.primaryGradient, 
                           lineWidth: DesignSystem.Borders.primaryBorder.lineWidth)
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
