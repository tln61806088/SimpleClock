import SwiftUI

/// 应用主界面
/// 整合所有功能组件：数字时钟、计时设置、操作按钮、语音识别
struct HomeView: View {
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @StateObject private var timerViewModel = TimerViewModel()
    @StateObject private var colorThemeState = ColorThemeState()
    @State private var timerSettings = TimerSettings.userPreferred
    
    // 性能优化：缓存TimerPicker的启用状态，避免每秒重绘
    @State private var isTimerPickerEnabled = true
    
    // 性能优化：缓存渐变对象，避免每次重绘都重新创建
    @State private var cachedPrimaryGradient: LinearGradient = DesignSystem.currentTheme.primaryGradient
    @State private var cachedBackgroundGradient: LinearGradient = DesignSystem.Colors.backgroundGradient
    
    // 性能优化：缓存阴影配置，避免每次重绘都重新计算
    @State private var cachedPrimaryShadow = DesignSystem.Shadows.primaryShadow
    @State private var cachedSecondaryShadow = DesignSystem.Shadows.secondaryShadow
    
    let mainButtonHeight: CGFloat = 80
    let mainButtonSpacing: CGFloat = 16
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 主要内容
                VStack(spacing: 0) {
                    // 上方固定内容区域 - 不滚动
                    VStack(spacing: DesignSystem.Spacing.large) {
                        // 自定义导航栏
                        HStack {
                            // 临时隐藏主题选择按钮 - 免费版本暂时只提供基础黑色主题
                            // ColorThemeToggleButton()
                            //     .environmentObject(colorThemeState)
                            
                            Spacer()
                            
                            // 中央标题（使用缓存渐变）
                            Text("无障碍计时器")
                                .font(DesignSystem.Fonts.title(size: DesignSystem.Sizes.titleText))
                                .foregroundStyle(cachedPrimaryGradient)
                                .shadow(color: cachedPrimaryShadow.color,
                                       radius: cachedPrimaryShadow.radius,
                                       x: cachedPrimaryShadow.x,
                                       y: cachedPrimaryShadow.y)
                                .shadow(color: cachedSecondaryShadow.color,
                                       radius: cachedSecondaryShadow.radius,
                                       x: cachedSecondaryShadow.x,
                                       y: cachedSecondaryShadow.y)
                            
                            Spacer()
                            
                            // 移除右侧占位，因为左侧已经没有按钮了
                            // Color.clear.frame(width: DesignSystem.Sizes.labelIcon + 2, height: DesignSystem.Sizes.labelIcon + 2)
                        }
                        
                        // 时钟显示区域
                        clockDisplayArea
                    
                        // 优雅的分割线
                        HStack {
                            Rectangle()
                                .fill(DesignSystem.Colors.dividerGradient)
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 40)
                    
                        // 计时设置区域
                        TimerPickerView(settings: $timerSettings, isEnabled: isTimerPickerEnabled)
                            .onChange(of: timerSettings) { newSettings in
                                timerViewModel.updateSettings(newSettings)
                            }

                    }
                    .padding(.horizontal, DesignSystem.Spacing.medium + 4)
                    .padding(.top, DesignSystem.Spacing.small + 4)
                    
                    // 中间弹性空白区域
                    Spacer(minLength: DesignSystem.Spacing.small)
                    
                    // 底部按钮区 - 固定在底部，响应式高度
                    VStack(spacing: 0) {
                        MainControlButtonsView(viewModel: timerViewModel)
                            .frame(height: calculateButtonAreaHeight(for: geometry), alignment: .top)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.medium + 4)
.padding(.bottom, max(geometry.safeAreaInsets.bottom, 16 * DesignSystem.Sizes.scale))
                }
                .background(cachedBackgroundGradient.ignoresSafeArea())
                
                // 临时隐藏颜色选择面板 - 免费版本暂时不提供主题选择
                // ColorThemeOverlay()
                //     .environmentObject(colorThemeState)
            }
        }
        .onAppear {
            timerViewModel.updateSettings(timerSettings)
            // 初始化TimerPicker状态
            isTimerPickerEnabled = !timerViewModel.isRunning
            // 添加进入动画
            withAnimation(.easeInOut(duration: 0.8)) {
                // 可以在这里添加状态变化来驱动动画
            }
        }
        .onChange(of: timerViewModel.isRunning) { isRunning in
            // 只在计时器运行状态真正变化时更新TimerPicker启用状态
            // 避免每秒的remainingSeconds变化导致重绘
            let newEnabled = !isRunning
            if isTimerPickerEnabled != newEnabled {
                isTimerPickerEnabled = newEnabled
            }
        }
        .onChange(of: themeManager.currentTheme) { newTheme in
            // 只在主题真正变化时更新缓存的渐变和阴影对象
            cachedPrimaryGradient = newTheme.primaryGradient
            cachedBackgroundGradient = DesignSystem.Colors.backgroundGradient
            cachedPrimaryShadow = DesignSystem.Shadows.primaryShadow
            cachedSecondaryShadow = DesignSystem.Shadows.secondaryShadow
        }
    }
    
/// 计算按钮区域高度，根据设备尺寸自动适应
    private func calculateButtonAreaHeight(for geometry: GeometryProxy) -> CGFloat {
        // 使用DesignSystem中定义的高度（已自动等比例缩放）
        let voiceButtonHeight = DesignSystem.Sizes.voiceButtonHeight * 0.75 // 与MainControlButtonsView一致
        let mainButtonHeight = DesignSystem.Sizes.voiceButtonHeight * 0.75   // 与MainControlButtonsView一致
        
        // 计算动态顶部间距（与MainControlButtonsView保持一致）
        let dynamicTopPadding = calculateDynamicTopPadding(screenHeight: geometry.size.height)
        
        // 按钮间距
        let buttonSpacing = DesignSystem.Spacing.buttonSpacing
        
        // 总高度 = 动态顶部间距 + 两个主按钮 + 一个语音按钮 + 按钮之间的间距
        let totalHeight = dynamicTopPadding + (mainButtonHeight * 2) + voiceButtonHeight + (buttonSpacing * 2)
        
        return totalHeight
    }
    
    /// 根据屏幕高度动态计算顶部间距（与MainControlButtonsView保持一致）
    private func calculateDynamicTopPadding(screenHeight: CGFloat) -> CGFloat {
        let baseSpacing = DesignSystem.Spacing.buttonSpacing
        
        if screenHeight <= 667 { // iPhone 6s/SE 等小屏幕
            return baseSpacing
        } else if screenHeight <= 736 { // iPhone 6 Plus等中屏幕
            return baseSpacing + DesignSystem.Spacing.small // 增加8点
        } else if screenHeight <= 812 { // iPhone X等中大屏幕
            return baseSpacing + DesignSystem.Spacing.small + 4 // 增加12点
        } else { // 大屏幕设备 (iPhone 15 Pro等)
            return baseSpacing + DesignSystem.Spacing.medium // 增加16点
        }
    }
    
    // 时钟显示区域
    @ViewBuilder
    private var clockDisplayArea: some View {
        // 暂时只显示正常时钟，作为单独的显示区域
        VStack(spacing: 16) {
            HStack {
                Spacer()
                DigitalClockView(timerViewModel: timerViewModel)
                Spacer()
            }
        }
    }
}

/// 计时器状态显示视图
struct TimerStatusView: View {
    
    @ObservedObject var viewModel: TimerViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            // 剩余时间显示
            HStack {
                Image(systemName: "timer")
                    .foregroundColor(.blue)
                
                Text("剩余时间：\(formattedRemainingTime)")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // 状态指示器
                HStack(spacing: 4) {
                    Circle()
                        .fill(viewModel.isRunning ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    
                    Text(viewModel.isRunning ? "运行中" : "已暂停")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 进度条
            ProgressView(value: progress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: viewModel.isRunning ? .blue : .orange))
                .scaleEffect(x: 1, y: 2, anchor: .center)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2, x: 0, y: 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("计时器状态")
        .accessibilityValue("\(formattedRemainingTime)，\(viewModel.isRunning ? "运行中" : "已暂停")")
        .accessibilityIdentifier("timerStatus")
    }
    
    /// 格式化剩余时间显示
    private var formattedRemainingTime: String {
        let hours = viewModel.remainingSeconds / 3600
        let minutes = (viewModel.remainingSeconds % 3600) / 60
        let seconds = viewModel.remainingSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    /// 计算进度值
    private var progress: Double {
        guard viewModel.settings.duration > 0 else { return 0 }
        let totalSeconds = Double(viewModel.settings.duration * 60)
        let remainingSeconds = Double(viewModel.remainingSeconds)
        return (totalSeconds - remainingSeconds) / totalSeconds
    }
}