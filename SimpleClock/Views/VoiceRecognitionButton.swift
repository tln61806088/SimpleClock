import SwiftUI

/// 语音识别按钮
/// 大圆形按钮，按住开始录音，松开后进行语音识别
struct VoiceRecognitionButton: View {
    
    @ObservedObject var viewModel: TimerViewModel
    @State private var isRecording = false
    @State private var recordingAnimation = false
    
    var body: some View {
        VStack(spacing: 8) {
            // 主按钮 - 改为长方形
            ZStack {
                // 背景长方形
                RoundedRectangle(cornerRadius: 12)
                    .fill(isRecording ? Color.gray.opacity(0.8) : Color.gray)
                    .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 120)
                
                // 录音动画波纹 - 改为长方形
                if isRecording {
                    ForEach(0..<3, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.6), lineWidth: 2)
                            .scaleEffect(recordingAnimation ? 1.05 : 0.95)
                            .opacity(recordingAnimation ? 0.0 : 0.8)
                            .animation(
                                .easeOut(duration: 1.0)
                                .repeatForever(autoreverses: false)
                                .delay(Double(index) * 0.2),
                                value: recordingAnimation
                            )
                    }
                }
                
                // 图标和文字
                HStack(spacing: 16) {
                    Image(systemName: isRecording ? "waveform" : "mic.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text(isRecording ? "录音中" : "语音识别")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
            }
            .onLongPressGesture(
                minimumDuration: 0.1,
                maximumDistance: 50,
                pressing: { pressing in
                    handlePressStateChange(pressing)
                },
                perform: {
                    // 长按完成时的处理（可选）
                }
            )
            
            Text("按住说话")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("语音识别按钮")
        .accessibilityHint("按住说话进行语音识别控制")
        .accessibilityAddTraits(.isButton)
    }
    
    /// 处理按压状态变化
    private func handlePressStateChange(_ pressing: Bool) {
        if pressing {
            // 开始录音
            startRecording()
        } else {
            // 结束录音
            stopRecording()
        }
    }
    
    /// 开始录音
    private func startRecording() {
        guard !isRecording else { return }
        
        isRecording = true
        recordingAnimation = true
        
        // 轻微震动反馈
        HapticHelper.shared.voiceRecognitionImpact()
        
        // 开始语音识别（但不立即处理结果）
        SpeechRecognitionHelper.shared.startRecording { _ in
            // 录音过程中不处理结果，等松手后处理
        }
    }
    
    /// 停止录音
    private func stopRecording() {
        guard isRecording else { return }
        
        isRecording = false
        recordingAnimation = false
        
        // 轻微震动反馈
        HapticHelper.shared.voiceRecognitionImpact()
        
        // 停止语音识别并处理最终结果
        SpeechRecognitionHelper.shared.stopRecording()
        
        // 获取识别结果并处理
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let recognizedText = SpeechRecognitionHelper.shared.getLastRecognizedText() {
                self.handleVoiceRecognitionResult(recognizedText)
            }
        }
    }
    
    /// 处理语音识别结果
    private func handleVoiceRecognitionResult(_ result: String) {
        // 根据识别结果执行相应操作
        switch result {
        case "开始计时":
            if !viewModel.isRunning {
                viewModel.startTimer()
                SpeechHelper.shared.speakVoiceRecognitionFeedback("开始计时")
            } else {
                SpeechHelper.shared.speakVoiceRecognitionFeedback("计时器已在运行")
            }
            
        case "暂停计时":
            if viewModel.isRunning {
                viewModel.pauseTimer()
                SpeechHelper.shared.speakVoiceRecognitionFeedback("暂停计时")
            } else {
                SpeechHelper.shared.speakVoiceRecognitionFeedback("计时器未运行")
            }
            
        case "恢复计时":
            if !viewModel.isRunning && viewModel.remainingSeconds > 0 {
                viewModel.startTimer()
                SpeechHelper.shared.speakVoiceRecognitionFeedback("恢复计时")
            } else {
                SpeechHelper.shared.speakVoiceRecognitionFeedback("无法恢复计时")
            }
            
        case "结束计时":
            viewModel.stopTimer()
            SpeechHelper.shared.speakVoiceRecognitionFeedback("结束计时")
            
        case "时间播报":
            SpeechHelper.shared.speakCurrentTime()
            
        case "剩余时间":
            if viewModel.remainingSeconds == 0 && !viewModel.isRunning {
                // 未开始计时时，播报设置的计时时长
                let message = "当前尚未开始计时，设置的计时时长为\(viewModel.settings.duration)分钟"
                SpeechHelper.shared.speak(message)
            } else {
                // 已开始计时，播报剩余时间
                SpeechHelper.shared.speakRemainingTime(remainingSeconds: viewModel.remainingSeconds)
            }
            
        default:
            if result.hasPrefix("计时") && result.hasSuffix("分钟") {
                // 处理计时设置指令
                handleTimerDurationCommand(result)
            } else if result.hasPrefix("间隔") && result.hasSuffix("分钟") {
                // 处理间隔设置指令
                handleIntervalCommand(result)
            } else {
                SpeechHelper.shared.speakVoiceRecognitionFeedback(result)
            }
        }
    }
    
    /// 处理计时时长设置指令
    private func handleTimerDurationCommand(_ command: String) {
        // 从"计时xx分钟"中提取数字
        let numberString = command.replacingOccurrences(of: "计时", with: "").replacingOccurrences(of: "分钟", with: "")
        if let duration = Int(numberString), TimerSettings.durationRange.contains(duration) {
            var newSettings = viewModel.settings
            newSettings.duration = duration
            viewModel.updateSettings(newSettings)
            SpeechHelper.shared.speakVoiceRecognitionFeedback("设置计时时长为\(duration)分钟")
        } else {
            SpeechHelper.shared.speakVoiceRecognitionFeedback("无效的计时时长")
        }
    }
    
    /// 处理间隔设置指令
    private func handleIntervalCommand(_ command: String) {
        // 从"间隔xx分钟"中提取数字
        let numberString = command.replacingOccurrences(of: "间隔", with: "").replacingOccurrences(of: "分钟", with: "")
        if let interval = Int(numberString), TimerSettings.intervalOptions.contains(interval) {
            var newSettings = viewModel.settings
            newSettings.interval = interval
            viewModel.updateSettings(newSettings)
            SpeechHelper.shared.speakVoiceRecognitionFeedback("设置提醒间隔为\(interval)分钟")
        } else {
            SpeechHelper.shared.speakVoiceRecognitionFeedback("无效的提醒间隔")
        }
    }
}

#if DEBUG
struct VoiceRecognitionButton_Previews: PreviewProvider {
    static var previews: some View {
        VoiceRecognitionButton(viewModel: TimerViewModel())
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
#endif