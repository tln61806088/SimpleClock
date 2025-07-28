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
            HStack(spacing: 0) {
                // 时
                TimeDigitView(text: hourString, size: 72)
                
                // 冒号（带闪烁动画）
                TimeDigitView(text: ":", size: 50)
                    .opacity(shouldShowColon ? 1.0 : 0.3)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: currentTime)
                    .padding(.horizontal, 2)
                
                // 分
                TimeDigitView(text: minuteString, size: 72)
                
                // 冒号（带闪烁动画）
                TimeDigitView(text: ":", size: 50)
                    .opacity(shouldShowColon ? 1.0 : 0.3)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: currentTime)
                    .padding(.horizontal, 2)
                
                // 秒
                TimeDigitView(text: secondString, size: 72)
            }
            .shadow(color: Color(red: 0.1, green: 0.2, blue: 0.5).opacity(0.4), radius: 12, x: 0, y: 6)
            .shadow(color: Color.purple.opacity(0.3), radius: 6, x: 0, y: 3)
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
            print("🕐 hourString: 倒计时模式 - remainingSeconds=\(viewModel.remainingSeconds), hours=\(hours), result='\(result)'")
            return result
        } else {
            // 显示当前时间
            let hour = Calendar.current.component(.hour, from: currentTime)
            let result = String(format: "%02d", hour)
            print("🕐 hourString: 时钟模式 - currentTime=\(currentTime), hour=\(hour), result='\(result)'")
            return result
        }
    }
    
    private var minuteString: String {
        if let viewModel = timerViewModel, viewModel.isRunning || viewModel.remainingSeconds > 0 {
            // 显示倒计时时间
            let totalMinutes = viewModel.remainingSeconds / 60
            let minutes = totalMinutes % 60
            let result = String(format: "%02d", minutes)
            print("🕐 minuteString: 倒计时模式 - remainingSeconds=\(viewModel.remainingSeconds), minutes=\(minutes), result='\(result)'")
            return result
        } else {
            // 显示当前时间
            let minute = Calendar.current.component(.minute, from: currentTime)
            let result = String(format: "%02d", minute)
            print("🕐 minuteString: 时钟模式 - currentTime=\(currentTime), minute=\(minute), result='\(result)'")
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
    let text: String
    let size: CGFloat
    
    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .ultraLight, design: .monospaced))
            .foregroundColor(.clear)
            .overlay(
                Text(text)
                    .font(.system(size: size, weight: .ultraLight, design: .monospaced))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.1, green: 0.2, blue: 0.5),
                                Color.purple,
                                Color(red: 0.1, green: 0.2, blue: 0.5)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(color: Color(red: 0.1, green: 0.2, blue: 0.5).opacity(0.3), radius: 8, x: 0, y: 4)
            .shadow(color: Color.purple.opacity(0.2), radius: 4, x: 0, y: 2)
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