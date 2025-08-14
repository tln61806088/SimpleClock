import SwiftUI

struct DigitalClockView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var currentTime = Date()
    // Timer优化：使用TimerViewModel的统一Timer，通过NotificationCenter通知更新
    
    // 性能优化：分级重绘缓存，只有变化时才更新
    @State private var cachedHour = ""
    @State private var cachedMinute = ""
    @State private var cachedSecond = ""
    
    // 计时器相关参数
    var timerViewModel: TimerViewModel? = nil
    var isCompactMode: Bool = false
    var isAccessibilityMode: Bool = true // 默认为无障碍模式
    
    var body: some View {
        VStack(spacing: 16) {
            // 主要时钟显示
            HStack(spacing: 0) {
                // 时（使用缓存，减少重绘）
                TimeDigitView(text: cachedHour, size: DesignSystem.Sizes.clockDigit, isAccessibilityMode: isAccessibilityMode)
                
                // 冒号（固定显示）
                TimeDigitView(text: ":", size: DesignSystem.Sizes.colon, isAccessibilityMode: isAccessibilityMode)
                    .padding(.horizontal, DesignSystem.Spacing.clockDigitSpacing)
                
                // 分（使用缓存，减少重绘）
                TimeDigitView(text: cachedMinute, size: DesignSystem.Sizes.clockDigit, isAccessibilityMode: isAccessibilityMode)
                
                // 冒号（固定显示）
                TimeDigitView(text: ":", size: DesignSystem.Sizes.colon, isAccessibilityMode: isAccessibilityMode)
                    .padding(.horizontal, DesignSystem.Spacing.clockDigitSpacing)
                
                // 秒（使用缓存，减少重绘）
                TimeDigitView(text: cachedSecond, size: DesignSystem.Sizes.clockDigit, isAccessibilityMode: isAccessibilityMode)
            }

        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            currentTime = Date()
            updateCachedStringsSelectively()
        }
        .onAppear {
            updateCachedStringsSelectively()
        }
        .onChange(of: timerViewModel?.remainingSeconds) { _ in
            // 监听计时器剩余时间变化，立即更新缓存
            updateCachedStringsSelectively()
        }
        .onChange(of: timerViewModel?.isRunning) { _ in
            // 监听计时器运行状态变化，立即更新缓存
            updateCachedStringsSelectively()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityTimeString))
        .accessibilityIdentifier("digitalClock")
    }
    
    // 原有的计算属性已迁移到缓存方法中，显著提升性能
    
    /// 判断是否处于计时模式
    private var isInTimerMode: Bool {
        if let viewModel = timerViewModel {
            return viewModel.isRunning || viewModel.remainingSeconds > 0
        }
        return false
    }
    
    private var accessibilityTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return "当前时间：" + formatter.string(from: currentTime)
    }
    
    // MARK: - 性能优化：智能分级重绘
    
    /// 智能更新缓存：只有变化时才更新，大幅减少UI重绘
    private func updateCachedStringsSelectively() {
        let newHour = calculateHourString()
        let newMinute = calculateMinuteString()
        let newSecond = calculateSecondString()
        
        // 分级更新：只有真正变化时才更新@State，触发UI重绘
        if cachedHour != newHour {
            cachedHour = newHour
        }
        if cachedMinute != newMinute {
            cachedMinute = newMinute
        }
        if cachedSecond != newSecond {
            cachedSecond = newSecond
        }
    }
    
    /// 计算小时字符串（避免重复计算）
    private func calculateHourString() -> String {
        if let viewModel = timerViewModel, viewModel.isRunning || viewModel.remainingSeconds > 0 {
            let totalMinutes = viewModel.remainingSeconds / 60
            let hours = totalMinutes / 60
            return String(format: "%02d", hours)
        } else {
            let hour = Calendar.current.component(.hour, from: currentTime)
            return String(format: "%02d", hour)
        }
    }
    
    /// 计算分钟字符串（避免重复计算）
    private func calculateMinuteString() -> String {
        if let viewModel = timerViewModel, viewModel.isRunning || viewModel.remainingSeconds > 0 {
            let totalMinutes = viewModel.remainingSeconds / 60
            let minutes = totalMinutes % 60
            return String(format: "%02d", minutes)
        } else {
            let minute = Calendar.current.component(.minute, from: currentTime)
            return String(format: "%02d", minute)
        }
    }
    
    /// 计算秒钟字符串（避免重复计算）
    private func calculateSecondString() -> String {
        if let viewModel = timerViewModel, viewModel.isRunning || viewModel.remainingSeconds > 0 {
            let seconds = viewModel.remainingSeconds % 60
            return String(format: "%02d", seconds)
        } else {
            let second = Calendar.current.component(.second, from: currentTime)
            return String(format: "%02d", second)
        }
    }
}

/// 时间数字显示组件，避免重复调用字符串计算
struct TimeDigitView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    let text: String
    let size: CGFloat
    let isAccessibilityMode: Bool
    
    var body: some View {
        if isAccessibilityMode {
            // 无障碍模式：简洁样式，无阴影
            Text(text)
                .font(DesignSystem.Fonts.clockDigit(size: size))
                .foregroundColor(.clear)
                .overlay(
                    Text(text)
                        .font(DesignSystem.Fonts.clockDigit(size: size))
                        .foregroundStyle(themeManager.currentTheme.primaryGradient)
                )
                .fixedSize()
        } else {
            // 普通模式：丰富样式，有阴影和字体效果
            Text(text)
                .font(DesignSystem.Fonts.clockDigit(size: size))
                .foregroundColor(.clear)
                .overlay(
                    Text(text)
                        .font(DesignSystem.Fonts.clockDigit(size: size))
                        .foregroundStyle(themeManager.currentTheme.primaryGradient)
                        .shadow(color: DesignSystem.Shadows.primaryShadow.color,
                               radius: DesignSystem.Shadows.primaryShadow.radius,
                               x: DesignSystem.Shadows.primaryShadow.x,
                               y: DesignSystem.Shadows.primaryShadow.y)
                        .shadow(color: DesignSystem.Shadows.secondaryShadow.color,
                               radius: DesignSystem.Shadows.secondaryShadow.radius,
                               x: DesignSystem.Shadows.secondaryShadow.x,
                               y: DesignSystem.Shadows.secondaryShadow.y)
                )
                .fixedSize()
        }
    }
}

#if DEBUG
struct DigitalClockView_Previews: PreviewProvider {
    static var previews: some View {
        DigitalClockView()
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
#endif