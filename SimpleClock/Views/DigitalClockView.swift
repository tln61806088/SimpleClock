import SwiftUI

struct DigitalClockView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // 计时器相关参数（暂时保留但不使用）
    var timerViewModel: TimerViewModel? = nil
    var isCompactMode: Bool = false
    
    var body: some View {
        VStack(spacing: 16) {
            // 主要时钟显示
            HStack(spacing: 0) {
                // 时
                TimeDigitView(text: hourString, size: DesignSystem.Sizes.clockDigit)
                
                // 冒号（带闪烁动画）
                TimeDigitView(text: ":", size: DesignSystem.Sizes.colon)
                    .opacity(shouldShowColon ? 1.0 : 0.3)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: currentTime)
                    .padding(.horizontal, DesignSystem.Spacing.clockDigitSpacing)
                
                // 分
                TimeDigitView(text: minuteString, size: DesignSystem.Sizes.clockDigit)
                
                // 冒号（带闪烁动画）
                TimeDigitView(text: ":", size: DesignSystem.Sizes.colon)
                    .opacity(shouldShowColon ? 1.0 : 0.3)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: currentTime)
                    .padding(.horizontal, DesignSystem.Spacing.clockDigitSpacing)
                
                // 秒
                TimeDigitView(text: secondString, size: DesignSystem.Sizes.clockDigit)
            }
            .shadow(color: DesignSystem.Shadows.largePrimaryShadow.color, 
                   radius: DesignSystem.Shadows.largePrimaryShadow.radius,
                   x: DesignSystem.Shadows.largePrimaryShadow.x,
                   y: DesignSystem.Shadows.largePrimaryShadow.y)
            .shadow(color: DesignSystem.Shadows.largeSecondaryShadow.color,
                   radius: DesignSystem.Shadows.largeSecondaryShadow.radius,
                   x: DesignSystem.Shadows.largeSecondaryShadow.x,
                   y: DesignSystem.Shadows.largeSecondaryShadow.y)
        }
        .onReceive(timer) { input in
            currentTime = input
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityTimeString))
    }
    
    // 计算显示的时间字符串
    private var hourString: String {
        if let viewModel = timerViewModel, viewModel.isRunning || viewModel.remainingSeconds > 0 {
            // 显示倒计时时间
            let totalMinutes = viewModel.remainingSeconds / 60
            let hours = totalMinutes / 60
            let result = String(format: "%02d", hours)
            // print("🕐 hourString: 倒计时模式 - remainingSeconds=\(viewModel.remainingSeconds), hours=\(hours), result='\(result)'")
            return result
        } else {
            // 显示当前时间
            let hour = Calendar.current.component(.hour, from: currentTime)
            let result = String(format: "%02d", hour)
            // print("🕐 hourString: 时钟模式 - currentTime=\(currentTime), hour=\(hour), result='\(result)'")
            return result
        }
    }
    
    private var minuteString: String {
        if let viewModel = timerViewModel, viewModel.isRunning || viewModel.remainingSeconds > 0 {
            // 显示倒计时时间
            let totalMinutes = viewModel.remainingSeconds / 60
            let minutes = totalMinutes % 60
            let result = String(format: "%02d", minutes)
            // print("🕐 minuteString: 倒计时模式 - remainingSeconds=\(viewModel.remainingSeconds), minutes=\(minutes), result='\(result)'")
            return result
        } else {
            // 显示当前时间
            let minute = Calendar.current.component(.minute, from: currentTime)
            let result = String(format: "%02d", minute)
            // print("🕐 minuteString: 时钟模式 - currentTime=\(currentTime), minute=\(minute), result='\(result)'")
            return result
        }
    }
    
    private var secondString: String {
        if let viewModel = timerViewModel, viewModel.isRunning || viewModel.remainingSeconds > 0 {
            // 显示倒计时时间
            let seconds = viewModel.remainingSeconds % 60
            return String(format: "%02d", seconds)
        } else {
            // 显示当前时间
            let second = Calendar.current.component(.second, from: currentTime)
            return String(format: "%02d", second)
        }
    }
    
    private var shouldShowColon: Bool {
        // 冒号闪烁效果
        let second = Calendar.current.component(.second, from: currentTime)
        return second % 2 == 0
    }
    
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
}

/// 时间数字显示组件，避免重复调用字符串计算
struct TimeDigitView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    let text: String
    let size: CGFloat
    
    var body: some View {
        Text(text)
            .font(DesignSystem.Fonts.clockDigit(size: size))
            .foregroundColor(.clear)
            .overlay(
                Text(text)
                    .font(DesignSystem.Fonts.clockDigit(size: size))
                    .foregroundStyle(themeManager.currentTheme.primaryGradient)
            )
            .shadow(color: DesignSystem.Shadows.clockDigitShadow.color,
                   radius: DesignSystem.Shadows.clockDigitShadow.radius,
                   x: DesignSystem.Shadows.clockDigitShadow.x,
                   y: DesignSystem.Shadows.clockDigitShadow.y)
            .shadow(color: DesignSystem.Shadows.clockDigitSecondaryShadow.color,
                   radius: DesignSystem.Shadows.clockDigitSecondaryShadow.radius,
                   x: DesignSystem.Shadows.clockDigitSecondaryShadow.x,
                   y: DesignSystem.Shadows.clockDigitSecondaryShadow.y)
            .fixedSize()
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