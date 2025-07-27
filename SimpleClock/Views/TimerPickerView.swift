import SwiftUI

/// 计时器设置选择器视图
/// 左侧：计时时长选择器（1-180分钟）
/// 右侧：提醒间隔选择器（1,5,10,15,30,60,90分钟）
struct TimerPickerView: View {
    
    @Binding var settings: TimerSettings
    
    @State private var selectedDuration: Int
    @State private var selectedInterval: Int
    @State private var lastSpokenDuration: Int = -1
    @State private var lastSpokenInterval: Int = -1
    @State private var speakTimer: Timer?
    
    init(settings: Binding<TimerSettings>) {
        self._settings = settings
        self._selectedDuration = State(initialValue: settings.wrappedValue.duration)
        self._selectedInterval = State(initialValue: settings.wrappedValue.interval)
    }
    
    var body: some View {
        HStack(spacing: 40) {
            // 左侧：计时时长选择器
            VStack(alignment: .center, spacing: 8) {
                Text("计时时长")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Picker("计时时长", selection: $selectedDuration) {
                    ForEach(Array(TimerSettings.durationRange), id: \.self) { duration in
                        Text("\(duration)分钟")
                            .tag(duration)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 120)
                .onChange(of: selectedDuration) { newValue in
                    handleDurationChange(newValue)
                }
                .accessibilityLabel("计时时长选择器")
                .accessibilityHint("滑动选择计时时长，范围1到180分钟")
            }
            
            // 右侧：提醒间隔选择器
            VStack(alignment: .center, spacing: 8) {
                Text("提醒间隔")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Picker("提醒间隔", selection: $selectedInterval) {
                    ForEach(TimerSettings.intervalOptions, id: \.self) { interval in
                        Text(interval == 0 ? "不提醒" : "\(interval)分钟")
                            .tag(interval)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 120)
                .onChange(of: selectedInterval) { newValue in
                    handleIntervalChange(newValue)
                }
                .accessibilityLabel("提醒间隔选择器")
                .accessibilityHint("滑动选择提醒间隔")
            }
        }
        .padding(.horizontal, 16)
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