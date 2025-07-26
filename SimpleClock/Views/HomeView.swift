import SwiftUI

/// 应用主界面
/// 整合所有功能组件：数字时钟、计时设置、操作按钮、语音识别
struct HomeView: View {
    
    @StateObject private var timerViewModel = TimerViewModel()
    @State private var timerSettings = TimerSettings.default
    
    let mainButtonHeight: CGFloat = 80
    let mainButtonSpacing: CGFloat = 16
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 24) {
                        // 时钟显示区域
                        clockDisplayArea
                    
                        Divider()
                    
                        // 计时设置区域
                        TimerPickerView(settings: $timerSettings)
                            .onChange(of: timerSettings) { newSettings in
                                timerViewModel.updateSettings(newSettings)
                            }
                    
                        Divider()
                        
                        // 已移除背景音乐控制，改用持续微弱音频维持后台
                    
                        // 底部按钮区
                        VStack {
                            Spacer(minLength: 0)
                            MainControlButtonsView(viewModel: timerViewModel)
                            Spacer()
                            VoiceRecognitionButton(viewModel: timerViewModel)
                            Spacer(minLength: geometry.safeAreaInsets.bottom)
                        }
                        .frame(height: geometry.size.height * 0.5)
                        .padding(.horizontal, 0)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                }
                .navigationTitle("SimpleClock")
                .navigationBarTitleDisplayMode(.inline)
                .background(Color(.systemGroupedBackground))
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            timerViewModel.updateSettings(timerSettings)
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
    }
    
    /// 格式化剩余时间显示
    private var formattedRemainingTime: String {
        let hours = viewModel.remainingSeconds / 3600
        let minutes = (viewModel.remainingSeconds % 3600) / 60
        let seconds = viewModel.remainingSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    /// 计算进度（0.0 到 1.0）
    private var progress: Double {
        let totalSeconds = Double(viewModel.settings.duration * 60)
        let remainingSeconds = Double(viewModel.remainingSeconds)
        return max(0, (totalSeconds - remainingSeconds) / totalSeconds)
    }
}

#if DEBUG
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
#endif