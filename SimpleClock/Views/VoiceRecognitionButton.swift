import SwiftUI

/// 语音识别按钮
/// 长方形按钮，点击开始录音，再次点击或5秒后自动结束录音并进行语音识别
struct VoiceRecognitionButton: View {
    
    @ObservedObject var viewModel: TimerViewModel
    @State private var isRecording = false
    @State private var recordingAnimation = false
    @State private var recordingTimer: Timer?
    
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
            .onTapGesture {
                handleTapGesture()
            }
            
            Text(isRecording ? "录音中，点击结束" : "点击说话")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("语音识别按钮")
        .accessibilityHint("点击开始语音识别，再次点击结束")
        .accessibilityAddTraits(.isButton)
    }
    
    /// 处理点击手势
    private func handleTapGesture() {
        if isRecording {
            // 正在录音，点击结束
            stopRecording()
        } else {
            // 未在录音，点击开始
            startRecording()
        }
    }
    
    /// 开始录音
    private func startRecording() {
        guard !isRecording else { return }
        
        isRecording = true
        recordingAnimation = true
        
        // 暂停后台滴答声，避免干扰语音识别
        print("暂停后台滴答声，开始语音识别")
        ContinuousAudioPlayer.shared.stopContinuousPlayback()
        
        // 轻微震动反馈
        print("触发开始录音震动")
        HapticHelper.shared.voiceRecognitionImpact()
        
        // 震动后稍微延迟再开始录音，确保用户感受到震动
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            // 开始语音识别（但不立即处理结果）
            print("开始语音识别录音")
            SpeechRecognitionHelper.shared.startRecording { _ in
                // 录音过程中不处理结果，等手动停止或超时后处理
            }
        }
        
        // 启动5秒计时器，自动停止录音（增加2秒）
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [self] _ in
            print("5秒录音时间到，自动停止录音")
            // 需要通过状态检查来避免重复调用
            if isRecording {
                stopRecording()
            }
        }
    }
    
    /// 停止录音
    private func stopRecording() {
        guard isRecording else { return }
        
        // 清理计时器
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        isRecording = false
        recordingAnimation = false
        
        // 立即震动反馈
        print("触发停止录音震动")
        HapticHelper.shared.voiceRecognitionImpact()
        
        // 延长0.5秒录音时间，确保捕获完整语音
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // 停止语音识别
            print("延长录音结束，停止语音识别")
            SpeechRecognitionHelper.shared.stopRecording()
            
            // 再等待0.1秒后处理识别结果
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let recognizedText = SpeechRecognitionHelper.shared.getLastRecognizedText() {
                    print("语音识别结果: \(recognizedText)")
                    self.handleVoiceRecognitionResult(recognizedText)
                } else {
                    print("语音识别: 没有获取到识别结果")
                    // 没有识别结果时也要恢复后台音频
                    self.resumeBackgroundAudioIfNeeded()
                }
            }
        }
    }
    
    /// 处理语音识别结果
    private func handleVoiceRecognitionResult(_ result: String) {
        print("开始处理语音指令: \(result)")
        print("当前计时器状态 - isRunning: \(viewModel.isRunning), remainingSeconds: \(viewModel.remainingSeconds)")
        
        // 根据识别结果执行相应操作，并播报详细的确认信息
        switch result {
        case "开始计时":
            print("匹配到开始计时指令")
            if !viewModel.isRunning {
                print("执行开始计时")
                let confirmMessage = "计时\(viewModel.settings.duration)分钟，间隔\(viewModel.settings.interval)分钟，开始计时"
                speakConfirmationAndExecute(confirmMessage) {
                    self.viewModel.startTimer()
                }
            } else {
                print("计时器已在运行，不执行")
                speakConfirmationOnly("计时器已在运行")
            }
            
        case "暂停计时":
            print("匹配到暂停计时指令")
            if viewModel.isRunning {
                print("执行暂停计时")
                let remainingMinutes = (viewModel.remainingSeconds + 59) / 60
                let confirmMessage = "暂停计时，剩余\(remainingMinutes)分钟，间隔\(viewModel.settings.interval)分钟"
                speakConfirmationAndExecute(confirmMessage) {
                    self.viewModel.pauseTimer()
                }
            } else {
                print("计时器未运行，不执行")
                speakConfirmationOnly("计时器未运行")
            }
            
        case "恢复计时":
            print("匹配到恢复计时指令")
            if !viewModel.isRunning && viewModel.remainingSeconds > 0 {
                print("执行恢复计时")
                let remainingMinutes = (viewModel.remainingSeconds + 59) / 60
                let confirmMessage = "恢复计时，剩余\(remainingMinutes)分钟，间隔\(viewModel.settings.interval)分钟"
                speakConfirmationAndExecute(confirmMessage) {
                    self.viewModel.startTimer()
                }
            } else {
                print("无法恢复计时 - isRunning: \(viewModel.isRunning), remainingSeconds: \(viewModel.remainingSeconds)")
                speakConfirmationOnly("无法恢复计时")
            }
            
        case "结束计时":
            print("匹配到结束计时指令")
            print("执行结束计时")
            speakConfirmationAndExecute("停止计时") {
                self.viewModel.stopTimer()
            }
            
        case "时间播报":
            speakConfirmationOnly("") // 不需要确认，直接播报时间
            SpeechHelper.shared.speakCurrentTime()
            // 播报完成后恢复后台音频
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                self.resumeBackgroundAudioIfNeeded()
            }
            
        case "剩余时间":
            if viewModel.remainingSeconds == 0 && !viewModel.isRunning {
                // 未开始计时时，播报设置的计时时长
                let message = "当前尚未开始计时，设置的计时时长为\(viewModel.settings.duration)分钟"
                speakConfirmationOnly(message)
            } else {
                // 已开始计时，播报剩余时间
                speakConfirmationOnly("") // 不需要确认，直接播报剩余时间
                SpeechHelper.shared.speakRemainingTime(remainingSeconds: viewModel.remainingSeconds)
                // 播报完成后恢复后台音频
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    self.resumeBackgroundAudioIfNeeded()
                }
            }
            
        case "未检测到语音":
            // 用户没有说话，给出友好提示
            speakConfirmationOnly("请点击按钮后再说话")
            
        default:
            print("进入default分支，未匹配到预定义指令: \(result)")
            if result.hasPrefix("计时") && result.hasSuffix("分钟") {
                print("处理计时设置指令")
                handleTimerDurationCommand(result)
            } else if result.hasPrefix("间隔") && result.hasSuffix("分钟") {
                print("处理间隔设置指令")
                handleIntervalCommand(result)
            } else {
                print("播报未识别指令")
                speakConfirmationOnly(result)
            }
        }
    }
    
    /// 播报确认信息并执行操作
    private func speakConfirmationAndExecute(_ message: String, completion: @escaping () -> Void) {
        if message.isEmpty {
            // 没有确认信息，直接执行操作
            completion()
            resumeBackgroundAudioIfNeeded()
        } else {
            // 播报确认信息
            SpeechHelper.shared.speak(message)
            
            // 等待播报完成后执行操作并恢复后台音频
            let estimatedSpeechDuration = Double(message.count) * 0.15 + 1.0 // 估算播报时长
            DispatchQueue.main.asyncAfter(deadline: .now() + estimatedSpeechDuration) {
                completion()
                self.resumeBackgroundAudioIfNeeded()
            }
        }
    }
    
    /// 只播报确认信息，不执行操作
    private func speakConfirmationOnly(_ message: String) {
        if !message.isEmpty {
            SpeechHelper.shared.speak(message)
            
            // 等待播报完成后恢复后台音频
            let estimatedSpeechDuration = Double(message.count) * 0.15 + 1.0 // 估算播报时长
            DispatchQueue.main.asyncAfter(deadline: .now() + estimatedSpeechDuration) {
                self.resumeBackgroundAudioIfNeeded()
            }
        } else {
            // 没有播报内容，立即恢复后台音频
            resumeBackgroundAudioIfNeeded()
        }
    }
    
    /// 如果需要，恢复后台音频播放
    private func resumeBackgroundAudioIfNeeded() {
        // 只有在计时器运行时才恢复后台滴答声
        if viewModel.isRunning {
            print("恢复后台滴答声")
            ContinuousAudioPlayer.shared.startContinuousPlayback()
        } else {
            print("计时器未运行，不恢复后台滴答声")
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
            speakConfirmationOnly("设置计时时长为\(duration)分钟")
        } else {
            speakConfirmationOnly("无效的计时时长")
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
            speakConfirmationOnly("设置提醒间隔为\(interval)分钟")
        } else {
            speakConfirmationOnly("无效的提醒间隔")
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