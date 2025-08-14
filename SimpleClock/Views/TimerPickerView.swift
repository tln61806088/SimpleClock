import SwiftUI

/// 计时器设置选择器视图
/// 左侧：计时时长选择器（1-720分钟，即12小时）
/// 右侧：提醒间隔选择器（1,5,10,15,30,60,90分钟）
struct TimerPickerView: View {
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @Binding var settings: TimerSettings
    let isEnabled: Bool  // 新增：控制选择器是否可用
    
    @State private var selectedDuration: Int
    @State private var selectedInterval: Int
    @State private var lastSpokenDuration: Int = -1
    @State private var lastSpokenInterval: Int = -1
    @State private var speakTimer: Timer?
    
    // 用于强制刷新滚轮宽度的触发器
    @State private var pickerWidthRefreshTrigger = false
    
    init(settings: Binding<TimerSettings>, isEnabled: Bool = true) {
        self._settings = settings
        self.isEnabled = isEnabled
        self._selectedDuration = State(initialValue: settings.wrappedValue.duration)
        self._selectedInterval = State(initialValue: settings.wrappedValue.interval)
    }
    
    var body: some View {
        VStack(spacing: 4) {
                // 选择器区域 - 完全居中
                HStack(spacing: DesignSystem.Spacing.pickerSpacing) {
                    // 左侧：计时时长选择器
                    VStack(alignment: .center, spacing: DesignSystem.Spacing.small + 4) {
                        HStack(spacing: DesignSystem.Spacing.labelSpacing) {
                            Image(systemName: "clock.fill")
                                .font(DesignSystem.Fonts.labelText(size: DesignSystem.Sizes.labelIcon))
                                .foregroundStyle(themeManager.currentTheme.primaryGradient)
                                .shadow(color: DesignSystem.Shadows.primaryShadow.color,
                                       radius: DesignSystem.Shadows.primaryShadow.radius,
                                       x: DesignSystem.Shadows.primaryShadow.x,
                                       y: DesignSystem.Shadows.primaryShadow.y)
                                .shadow(color: DesignSystem.Shadows.secondaryShadow.color,
                                       radius: DesignSystem.Shadows.secondaryShadow.radius,
                                       x: DesignSystem.Shadows.secondaryShadow.x,
                                       y: DesignSystem.Shadows.secondaryShadow.y)
                            
                            Text("计时时长")
                                .font(DesignSystem.Fonts.labelText(size: DesignSystem.Sizes.labelText))
                                .foregroundStyle(themeManager.currentTheme.primaryGradient)
                                .shadow(color: DesignSystem.Shadows.primaryShadow.color,
                                       radius: DesignSystem.Shadows.primaryShadow.radius,
                                       x: DesignSystem.Shadows.primaryShadow.x,
                                       y: DesignSystem.Shadows.primaryShadow.y)
                                .shadow(color: DesignSystem.Shadows.secondaryShadow.color,
                                       radius: DesignSystem.Shadows.secondaryShadow.radius,
                                       x: DesignSystem.Shadows.secondaryShadow.x,
                                       y: DesignSystem.Shadows.secondaryShadow.y)
                        }
                        
                        Picker("计时时长", selection: $selectedDuration) {
                            ForEach(Array(TimerSettings.durationRange), id: \.self) { duration in
                                Text("\(duration)分钟")
                                    .tag(duration)
                                    .font(DesignSystem.Fonts.pickerText(size: DesignSystem.Sizes.pickerText))
                                    .foregroundStyle(themeManager.currentTheme.primaryGradient)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: calculatePickerWidth(refreshTrigger: pickerWidthRefreshTrigger), height: 100)
                        .disabled(!isEnabled)
                        .opacity(isEnabled ? 1.0 : 0.6)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.pickerBackground)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        )
                        .onChange(of: selectedDuration) { newValue in
                            if isEnabled {
                                handleDurationChange(newValue)
                            }
                        }
                        .accessibilityLabel("计时时长选择器")
                        .accessibilityHint("滑动选择计时时长，范围1到720分钟")
                        .accessibilityIdentifier("timerDurationPicker")
                    }
                    
                    // 右侧：提醒间隔选择器
                    VStack(alignment: .center, spacing: DesignSystem.Spacing.small + 4) {
                        HStack(spacing: DesignSystem.Spacing.labelSpacing) {
                            Image(systemName: "bell.fill")
                                .font(DesignSystem.Fonts.labelText(size: DesignSystem.Sizes.labelIcon))
                                .foregroundStyle(themeManager.currentTheme.primaryGradient)
                                .shadow(color: DesignSystem.Shadows.primaryShadow.color,
                                       radius: DesignSystem.Shadows.primaryShadow.radius,
                                       x: DesignSystem.Shadows.primaryShadow.x,
                                       y: DesignSystem.Shadows.primaryShadow.y)
                                .shadow(color: DesignSystem.Shadows.secondaryShadow.color,
                                       radius: DesignSystem.Shadows.secondaryShadow.radius,
                                       x: DesignSystem.Shadows.secondaryShadow.x,
                                       y: DesignSystem.Shadows.secondaryShadow.y)
                            
                            Text("提醒间隔")
                                .font(DesignSystem.Fonts.labelText(size: DesignSystem.Sizes.labelText))
                                .foregroundStyle(themeManager.currentTheme.primaryGradient)
                                .shadow(color: DesignSystem.Shadows.primaryShadow.color,
                                       radius: DesignSystem.Shadows.primaryShadow.radius,
                                       x: DesignSystem.Shadows.primaryShadow.x,
                                       y: DesignSystem.Shadows.primaryShadow.y)
                                .shadow(color: DesignSystem.Shadows.secondaryShadow.color,
                                       radius: DesignSystem.Shadows.secondaryShadow.radius,
                                       x: DesignSystem.Shadows.secondaryShadow.x,
                                       y: DesignSystem.Shadows.secondaryShadow.y)
                        }
                        
                        Picker("提醒间隔", selection: $selectedInterval) {
                            ForEach(TimerSettings.intervalOptions, id: \.self) { interval in
                                Text(interval == 0 ? "不提醒" : "\(interval)分钟")
                                    .tag(interval)
                                    .font(DesignSystem.Fonts.pickerText(size: DesignSystem.Sizes.pickerText))
                                    .foregroundStyle(themeManager.currentTheme.primaryGradient)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: calculatePickerWidth(refreshTrigger: pickerWidthRefreshTrigger), height: 100)
                        .disabled(!isEnabled)
                        .opacity(isEnabled ? 1.0 : 0.6)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.pickerBackground)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        )
                        .onChange(of: selectedInterval) { newValue in
                            if isEnabled {
                                handleIntervalChange(newValue)
                            }
                        }
                        .accessibilityLabel("提醒间隔选择器")
                        .accessibilityHint("滑动选择提醒间隔")
                        .accessibilityIdentifier("timerIntervalPicker")
                    }
                }
                .frame(maxWidth: .infinity) // 确保HStack使用全宽
                .multilineTextAlignment(.center) // 确保文本居中对齐
            }
            .frame(maxWidth: .infinity, alignment: .center) // VStack使用全宽并居中对齐
            .clipped() // 防止内容溢出
        .onAppear {
            // 初始化时播报当前设置
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                // 语音播报内容："计时[X]分钟，[间隔文本]" (第141行)
                //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                SpeechHelper.shared.speakTimerSettings(duration: selectedDuration, interval: selectedInterval)
            }
        }
        .onChange(of: settings) { newSettings in
            // 当settings发生变化时，同步更新滚轮显示
            selectedDuration = newSettings.duration
            selectedInterval = newSettings.interval
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            // 设备方向变化时强制刷新滚轮宽度
            pickerWidthRefreshTrigger.toggle()
        }
        .onDisappear {
            // 清理定时器
            speakTimer?.invalidate()
            speakTimer = nil
        }
    }
    
    /// 计算Picker宽度，与下方按钮宽度对齐
    private func calculatePickerWidth(refreshTrigger: Bool = false) -> CGFloat {
        // 获取屏幕宽度和设备信息
        let screenBounds = UIScreen.main.bounds
        let screenWidth = screenBounds.width
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        let isLandscape = screenBounds.width > screenBounds.height
        
        let horizontalPadding = (DesignSystem.Spacing.medium + 4) * 2 // 左右边距
        let pickerSpacing = DesignSystem.Spacing.pickerSpacing // 两个滚轮之间的间距
        
        // 可用宽度 = 屏幕宽度 - 左右边距
        let availableWidth = screenWidth - horizontalPadding
        
        // iPad横屏模式下，滚轮宽度需要与按钮宽度精确匹配
        if isIPad && isLandscape {
            // 在横屏模式下，按钮之间有DesignSystem.Spacing.buttonSpacing间距
            let buttonSpacing = DesignSystem.Spacing.buttonSpacing
            // 计算单个按钮的实际宽度：(可用宽度 - 按钮间距) / 2
            let buttonWidth = (availableWidth - buttonSpacing) / 2
            // 滚轮宽度与按钮宽度保持一致
            return buttonWidth
        } else {
            // iPhone和iPad竖屏模式保持原有逻辑
            // 每个滚轮的宽度 = (可用宽度 - 滚轮间距) / 2
            let pickerWidth = (availableWidth - pickerSpacing) / 2
            return pickerWidth
        }
    }
    
    /// 处理计时时长变化
    private func handleDurationChange(_ newDuration: Int) {
        // 更新设置
        settings.duration = newDuration
        
        // 提供震动反馈（当为5的倍数时）
        if newDuration % 5 == 0 {
            HapticHelper.shared.pickerImpact()
        }
        
        // 延迟语音播报（避免频繁播报）
        speakTimer?.invalidate()
        
        // 使用DispatchQueue替代Timer，避免强引用问题
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // 使用统一的播报函数，确保术语一致性
            SpeechHelper.shared.speakTimerSettings(duration: newDuration, interval: selectedInterval)
            lastSpokenDuration = newDuration
        }
    }
    
    /// 处理提醒间隔变化
    private func handleIntervalChange(_ newInterval: Int) {
        // 更新设置
        settings.interval = newInterval
        
        // 提供震动反馈
        HapticHelper.shared.pickerImpact()
        
        // 延迟语音播报（避免频繁播报）
        speakTimer?.invalidate()
        
        // 使用DispatchQueue替代Timer，避免强引用问题
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // 使用统一的播报函数，确保术语一致性
            SpeechHelper.shared.speakTimerSettings(duration: selectedDuration, interval: newInterval)
            lastSpokenInterval = newInterval
        }
    }
}

#if DEBUG
struct TimerPickerView_Previews: PreviewProvider {
    static var previews: some View {
        TimerPickerView(settings: .constant(TimerSettings.default))
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
#endif