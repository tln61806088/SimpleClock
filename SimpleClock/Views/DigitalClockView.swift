import SwiftUI

struct DigitalClockView: View {
    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // 计时器相关参数（暂时保留但不使用）
    var timerViewModel: TimerViewModel? = nil
    var isCompactMode: Bool = false
    
    var body: some View {
        VStack(spacing: 16) {
            // 主要时钟显示
            HStack(spacing: 4) {
                // 时
                TimeDigitView(text: hourString, size: 72)
                
                // 冒号（带闪烁动画）
                TimeDigitView(text: ":", size: 50)
                    .opacity(shouldShowColon ? 1.0 : 0.3)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: currentTime)
                
                // 分
                TimeDigitView(text: minuteString, size: 72)
                
                // 冒号（带闪烁动画）
                TimeDigitView(text: ":", size: 50)
                    .opacity(shouldShowColon ? 1.0 : 0.3)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: currentTime)
                
                // 秒
                TimeDigitView(text: secondString, size: 72)
            }
            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            
            // 状态指示器
            HStack(spacing: 8) {
                Circle()
                    .fill(isInTimerMode ? Color.orange : Color.green)
                    .frame(width: 8, height: 8)
                    .scaleEffect(isInTimerMode ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isInTimerMode)
                
                Text(isInTimerMode ? "计时模式" : "时钟模式")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(.systemBackground),
                            Color(.systemBackground).opacity(0.95)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
        )
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
            let hours = viewModel.remainingSeconds / 3600
            return String(format: "%02d", hours)
        } else {
            // 显示当前时间
            let hour = Calendar.current.component(.hour, from: currentTime)
            return String(format: "%02d", hour)
        }
    }
    
    private var minuteString: String {
        if let viewModel = timerViewModel, viewModel.isRunning || viewModel.remainingSeconds > 0 {
            // 显示倒计时时间
            let minutes = (viewModel.remainingSeconds % 3600) / 60
            return String(format: "%02d", minutes)
        } else {
            // 显示当前时间
            let minute = Calendar.current.component(.minute, from: currentTime)
            return String(format: "%02d", minute)
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
    let text: String
    let size: CGFloat
    
    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .light, design: .monospaced))
            .foregroundColor(.clear)
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [.blue, .purple]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .mask(
                    Text(text)
                        .font(.system(size: size, weight: .light, design: .monospaced))
                )
            )
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