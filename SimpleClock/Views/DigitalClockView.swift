import SwiftUI

struct DigitalClockView: View {
    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // 计时器相关参数（暂时保留但不使用）
    var timerViewModel: TimerViewModel? = nil
    var isCompactMode: Bool = false
    
    var body: some View {
        // 暂时只显示正常时钟，不处理倒计时模式
        HStack(spacing: 8) {
            // 时
            Text(hourString)
                .font(.system(size: 60, weight: .medium, design: .monospaced))
                .foregroundColor(.primary)
            
            // 冒号
            Text(":")
                .font(.system(size: 40, weight: .medium, design: .monospaced))
                .foregroundColor(.primary)
            
            // 分
            Text(minuteString)
                .font(.system(size: 60, weight: .medium, design: .monospaced))
                .foregroundColor(.primary)
            
            // 冒号
            Text(":")
                .font(.system(size: 40, weight: .medium, design: .monospaced))
                .foregroundColor(.primary)
            
            // 秒
            Text(secondString)
                .font(.system(size: 60, weight: .medium, design: .monospaced))
                .foregroundColor(.primary)
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
        // 冒号不闪烁，始终显示
        return true
    }
    
    private var accessibilityTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return "当前时间：" + formatter.string(from: currentTime)
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