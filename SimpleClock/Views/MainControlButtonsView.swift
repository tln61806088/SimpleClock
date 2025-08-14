import SwiftUI

/// 主要操作按钮区域
/// 第一行：时间播报、开始计时/暂停计时
/// 第二行：剩余时长、结束计时
/// 第三行：语音识别按钮（大圆形）
struct MainControlButtonsView: View {
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject var viewModel: TimerViewModel
    let isAccessibilityMode: Bool
    
    // 性能优化：缓存按钮状态，避免每秒重绘
    @State private var cachedButtonTitle = "开始计时"
    @State private var cachedButtonIcon = "play.fill"
    
    // 强制刷新按钮高度的触发器
    @State private var buttonHeightRefreshTrigger = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .center, spacing: DesignSystem.Spacing.buttonSpacing) {
                if isAccessibilityMode {
                    // 无障碍模式：3个按钮（竖向排列）
                    // 开始计时/暂停计时按钮（绿色）
                    ControlButton(
                        title: cachedButtonTitle,
                        systemImage: cachedButtonIcon,
                        backgroundColor: .green,
                        buttonHeight: calculateButtonHeightForDevice(row: 1, refreshTrigger: buttonHeightRefreshTrigger),
                        isMainButton: true
                    ) {
                        handleStartPauseTimer()
                    }
                    
                    // 结束计时按钮（红色）
                    ControlButton(
                        title: "结束计时",
                        systemImage: "stop.fill",
                        backgroundColor: .red,
                        buttonHeight: calculateButtonHeightForDevice(row: 2, refreshTrigger: buttonHeightRefreshTrigger),
                        isMainButton: true
                    ) {
                        handleEndTimer()
                    }
                    
                    // 语音识别按钮（黄色）
                    VoiceRecognitionButton(viewModel: viewModel, isAccessibilityMode: isAccessibilityMode, buttonHeight: calculateButtonHeightForDevice(row: 3, refreshTrigger: buttonHeightRefreshTrigger))
                } else {
                    // 普通模式：5个按钮（2x2网格布局）
                    // 第一行按钮
                    HStack(spacing: DesignSystem.Spacing.buttonSpacing) {
                        // 时间播报按钮
                        ControlButton(
                            title: "时间播报",
                            systemImage: "clock.fill",
                            backgroundColor: .clear,
                            buttonHeight: calculateButtonHeightForDevice(row: 1, refreshTrigger: buttonHeightRefreshTrigger),
                            isMainButton: true
                        ) {
                            handleTimeAnnouncement()
                        }
                        
                        // 开始计时/暂停计时按钮（使用缓存状态）
                        ControlButton(
                            title: cachedButtonTitle,
                            systemImage: cachedButtonIcon,
                            backgroundColor: .clear,
                            buttonHeight: calculateButtonHeightForDevice(row: 1, refreshTrigger: buttonHeightRefreshTrigger),
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
                            backgroundColor: .clear,
                            buttonHeight: calculateButtonHeightForDevice(row: 2, refreshTrigger: buttonHeightRefreshTrigger),
                            isMainButton: true
                        ) {
                            handleRemainingTime()
                        }
                        
                        // 结束计时按钮
                        ControlButton(
                            title: "结束计时",
                            systemImage: "stop.fill",
                            backgroundColor: .clear,
                            buttonHeight: calculateButtonHeightForDevice(row: 2, refreshTrigger: buttonHeightRefreshTrigger),
                            isMainButton: true
                        ) {
                            handleEndTimer()
                        }
                    }
                    
                    // 第三行：语音识别按钮
                    VoiceRecognitionButton(viewModel: viewModel, isAccessibilityMode: isAccessibilityMode, buttonHeight: calculateButtonHeightForDevice(row: 3, refreshTrigger: buttonHeightRefreshTrigger))
                }
            }
            .padding(.top, calculateDynamicTopPaddingWithSpacing())
            .onAppear {
                // 初始化按钮状态
                updateButtonState()
            }
            .onChange(of: viewModel.isRunning) { _ in
                // 只在计时器运行状态变化时更新按钮
                updateButtonState()
            }
            .onChange(of: viewModel.isPaused) { _ in
                // 只在计时器暂停状态变化时更新按钮
                updateButtonState()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                // 设备方向变化时强制刷新按钮高度
                buttonHeightRefreshTrigger.toggle()
            }
            .onChange(of: isAccessibilityMode) { _ in
                // 模式切换时强制刷新按钮高度
                buttonHeightRefreshTrigger.toggle()
            }
        }
    }
    
    /// 更新按钮状态（只在必要时触发UI更新）
    private func updateButtonState() {
        let newTitle: String
        let newIcon: String
        
        if viewModel.isRunning {
            newTitle = "暂停计时"
            newIcon = "pause.fill"
        } else if viewModel.isPaused {
            newTitle = "恢复计时"
            newIcon = "play.fill"
        } else {
            newTitle = "开始计时"
            newIcon = "play.fill"
        }
        
        // 只有状态真正变化时才更新@State，触发UI重绘
        if cachedButtonTitle != newTitle {
            cachedButtonTitle = newTitle
        }
        if cachedButtonIcon != newIcon {
            cachedButtonIcon = newIcon
        }
    }
    
/// 根据屏幕高度动态计算顶部间距
    private func calculateDynamicTopPadding() -> CGFloat {
        let screenHeight = UIScreen.main.bounds.height
        let baseSpacing = DesignSystem.Spacing.buttonSpacing
        
        // 根据屏幕高度调整额外间距
        if screenHeight <= 667 { // iPhone 6s/SE 等小屏幕 - 不增加额外间距
            return baseSpacing
        } else if screenHeight <= 736 { // iPhone 6 Plus等中屏幕 - 少量增加
            return baseSpacing + DesignSystem.Spacing.small // 增加8点
        } else if screenHeight <= 812 { // iPhone X等中大屏幕
            return baseSpacing + DesignSystem.Spacing.small + 4 // 增加12点
        } else { // 大屏幕设备 (iPhone 15 Pro等)
            return baseSpacing + DesignSystem.Spacing.medium // 增加16点
        }
    }
    
    /// 根据设备尺寸计算按钮高度
    /// 主控制按钮高度 = 语音识别按钮高度的1/1.75
    private func calculateButtonHeight(for geometry: GeometryProxy) -> CGFloat {
        return DesignSystem.Sizes.mainButtonHeight
    }
    
    /// 根据屏幕高度动态计算顶部间距（包含滚轮间距）
    private func calculateDynamicTopPaddingWithSpacing() -> CGFloat {
        // 所有设备都使用最小间距，让按钮在红色背景内顶端对齐
        return 8
    }
    
    /// 根据设备类型和按钮行数计算按钮高度
    private func calculateButtonHeightForDevice(row: Int = 1, refreshTrigger: Bool = false) -> CGFloat {
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        
        if isIPad {
            // 更准确的iPad方向检测：优先使用屏幕尺寸
            let screenBounds = UIScreen.main.bounds
            let isLandscape = screenBounds.width > screenBounds.height
            
            if isLandscape {
                // iPad横向模式：第一二行1.25倍，第三行2倍
                switch row {
                case 1, 2: // 第一行、第二行：高度*1.25
                    return DesignSystem.Sizes.mainButtonHeight * 1.25
                case 3: // 第三行：2倍高度
                    return DesignSystem.Sizes.mainButtonHeight * 2.0
                default:
                    return DesignSystem.Sizes.mainButtonHeight * 1.25
                }
            } else {
                // iPad竖向模式
                switch row {
                case 1, 2: // 第一行、第二行：不调整
                    return DesignSystem.Sizes.mainButtonHeight
                case 3: // 第三行：1.5倍
                    return DesignSystem.Sizes.mainButtonHeight * 1.5
                default:
                    return DesignSystem.Sizes.mainButtonHeight
                }
            }
        } else {
            // iPhone保持原有高度，但区分主按钮和语音按钮
            switch row {
            case 3: // 第三行：语音识别按钮
                return DesignSystem.Sizes.voiceButtonHeight
            default: // 第一二行：主控制按钮
                return DesignSystem.Sizes.mainButtonHeight
            }
        }
    }
    
    // MARK: - 按钮操作处理
    
    /// 处理时间播报
    private func handleTimeAnnouncement() {
        HapticHelper.shared.lightImpact()
        SpeechHelper.shared.speakCurrentTime()
    }
    
    /// 处理剩余时长播报
    private func handleRemainingTime() {
        HapticHelper.shared.lightImpact()
        
        if viewModel.remainingSeconds > 0 {
            // 有计时任务运行时，播报剩余时间
            SpeechHelper.shared.speakRemainingTime(remainingSeconds: viewModel.remainingSeconds)
        } else {
            // 无计时任务时，播报状态
            let message = "当前无计时任务"
            SpeechHelper.shared.speak(message)
        }
    }
    
    /// 处理开始/暂停计时
    private func handleStartPauseTimer() {
        HapticHelper.shared.lightImpact()
        
        if viewModel.isRunning {
            viewModel.pauseTimer()
            //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            // 语音播报内容："暂停计时"
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
            } else if interval == 60 {
                message += "1小时"
            } else if interval < 60 {
                message += "\(interval)分钟"
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
    
    /// 处理结束计时
    private func handleEndTimer() {
        HapticHelper.shared.lightImpact()
        viewModel.stopTimer()
        //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        // 语音播报内容："结束计时"
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
                    .font(DesignSystem.Fonts.buttonText(size: DesignSystem.Sizes.voiceStateText))
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
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                            .stroke(themeManager.currentTheme.primaryGradient, 
                                   lineWidth: DesignSystem.Borders.primaryBorder.lineWidth)
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
        .accessibilityIdentifier(title == "开始计时" || title == "暂停计时" || title == "恢复计时" ? "startTimerButton" : "stopTimerButton")
    }
}

#if DEBUG
struct MainControlButtonsView_Previews: PreviewProvider {
    static var previews: some View {
        MainControlButtonsView(viewModel: TimerViewModel(), isAccessibilityMode: true)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
#endif
