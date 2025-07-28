import SwiftUI

/// 计时器设置选择器视图
/// 左侧：计时时长选择器（1-720分钟，即12小时）
/// 右侧：提醒间隔选择器（1,5,10,15,30,60,90分钟）
struct TimerPickerView: View {
    
    @Binding var settings: TimerSettings
    let isEnabled: Bool  // 新增：控制选择器是否可用
    
    @State private var selectedDuration: Int
    @State private var selectedInterval: Int
    @State private var lastSpokenDuration: Int = -1
    @State private var lastSpokenInterval: Int = -1
    @State private var speakTimer: Timer?
    
    init(settings: Binding<TimerSettings>, isEnabled: Bool = true) {
        self._settings = settings
        self.isEnabled = isEnabled
        self._selectedDuration = State(initialValue: settings.wrappedValue.duration)
        self._selectedInterval = State(initialValue: settings.wrappedValue.interval)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // 选择器区域
            HStack(spacing: 32) {
                // 左侧：计时时长选择器
                VStack(alignment: .center, spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 14, weight: .ultraLight, design: .monospaced))
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
                            .shadow(color: Color(red: 0.1, green: 0.2, blue: 0.5).opacity(0.3), radius: 4, x: 0, y: 2)
                            .shadow(color: Color.purple.opacity(0.2), radius: 2, x: 0, y: 1)
                        
                        Text("计时时长")
                            .font(.system(size: 16, weight: .ultraLight, design: .monospaced))
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
                            .shadow(color: Color(red: 0.1, green: 0.2, blue: 0.5).opacity(0.3), radius: 4, x: 0, y: 2)
                            .shadow(color: Color.purple.opacity(0.2), radius: 2, x: 0, y: 1)
                    }
                    
                    Picker("计时时长", selection: $selectedDuration) {
                        ForEach(Array(TimerSettings.durationRange), id: \.self) { duration in
                            Text("\(duration)分钟")
                                .tag(duration)
                                .font(.system(size: 18, weight: .ultraLight, design: .monospaced))
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
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 100)
                    .disabled(!isEnabled)
                    .opacity(isEnabled ? 1.0 : 0.6)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
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
                }
                
                // 右侧：提醒间隔选择器
                VStack(alignment: .center, spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 14, weight: .ultraLight, design: .monospaced))
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
                            .shadow(color: Color(red: 0.1, green: 0.2, blue: 0.5).opacity(0.3), radius: 4, x: 0, y: 2)
                            .shadow(color: Color.purple.opacity(0.2), radius: 2, x: 0, y: 1)
                        
                        Text("提醒间隔")
                            .font(.system(size: 16, weight: .ultraLight, design: .monospaced))
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
                            .shadow(color: Color(red: 0.1, green: 0.2, blue: 0.5).opacity(0.3), radius: 4, x: 0, y: 2)
                            .shadow(color: Color.purple.opacity(0.2), radius: 2, x: 0, y: 1)
                    }
                    
                    Picker("提醒间隔", selection: $selectedInterval) {
                        ForEach(TimerSettings.intervalOptions, id: \.self) { interval in
                            Text(interval == 0 ? "不提醒" : "\(interval)分钟")
                                .tag(interval)
                                .font(.system(size: 18, weight: .ultraLight, design: .monospaced))
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
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 100)
                    .disabled(!isEnabled)
                    .opacity(isEnabled ? 1.0 : 0.6)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
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
                }
            }
        }
        .onAppear {
            // 初始化时播报当前设置
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                SpeechHelper.shared.speakTimerSettings(duration: selectedDuration, interval: selectedInterval)
            }
        }
        .onDisappear {
            // 清理定时器
            speakTimer?.invalidate()
            speakTimer = nil
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
        speakTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            // 播报完整的计时设置信息
            let intervalText = selectedInterval == 0 ? "不提醒" : "\(selectedInterval)分钟"
            SpeechHelper.shared.speak("计时\(newDuration)分钟，间隔\(intervalText)")
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
        speakTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            // 播报完整的计时设置信息
            let intervalText = newInterval == 0 ? "不提醒" : "\(newInterval)分钟"
            SpeechHelper.shared.speak("计时\(selectedDuration)分钟，间隔\(intervalText)")
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