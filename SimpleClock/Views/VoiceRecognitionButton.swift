import SwiftUI

/// 语音指令枚举
enum VoiceCommand: Equatable {
    case startTimer
    case pauseTimer
    case resumeTimer
    case stopTimer
    case speakTime
    case speakRemainingTime
    case setTimer(duration: Int)
    case setInterval(interval: Int)
    case setTimerWithInterval(duration: Int, interval: Int)
    case noSpeechDetected
    case unrecognized(text: String)
}

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
        
        // 暂停后台音乐播放，避免干扰语音识别
        print("暂停后台音乐，开始语音识别")
        ContinuousAudioPlayer.shared.stopContinuousPlayback()
        
        // 轻微震动反馈
        print("触发开始录音震动")
        HapticHelper.shared.voiceRecognitionImpact()
        
        // 震动后稍微延迟再开始录音，确保用户感受到震动
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            // 开始语音识别
            print("开始语音识别录音")
            SpeechRecognitionHelper.shared.startRecording { _ in
                // 录音过程中不处理结果，等手动停止或超时后处理
            }
        }
        
        // 启动5秒计时器，自动停止录音
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
            
            // 再等待0.3秒后处理识别结果，给语音识别更多处理时间
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if let recognizedText = SpeechRecognitionHelper.shared.getLastRecognizedText(), 
                   !recognizedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                   recognizedText != "未检测到语音" && recognizedText != "识别失败" {
                    print("✅ 语音识别成功: \(recognizedText)")
                    // 清空识别结果，避免重复使用
                    SpeechRecognitionHelper.shared.clearLastRecognizedText()
                    self.handleVoiceRecognitionResult(recognizedText)
                } else {
                    let debugText = SpeechRecognitionHelper.shared.getLastRecognizedText() ?? "nil"
                    print("❌ 语音识别失败，当前结果: \(debugText)")
                    // 清空无效结果
                    SpeechRecognitionHelper.shared.clearLastRecognizedText()
                    // 没有识别结果时也要恢复后台音频
                    self.handleVoiceRecognitionResult("未检测到语音")
                }
            }
        }
    }
    
    /// 处理语音识别结果 - 使用苹果框架进行智能指令识别
    private func handleVoiceRecognitionResult(_ result: String) {
        print("开始处理语音指令: \(result)")
        print("当前计时器状态 - isRunning: \(viewModel.isRunning), remainingSeconds: \(viewModel.remainingSeconds)")
        
        // 使用苹果的Natural Language框架进行指令识别
        let command = intelligentCommandRecognition(from: result)
        print("智能识别到的指令: \(command)")
        
        // 对于常用指令，不播报"识别到指令"，直接执行
        let skipRecognitionAnnouncement: [VoiceCommand] = [
            .startTimer, .pauseTimer, .resumeTimer, .stopTimer, 
            .speakTime, .speakRemainingTime, .noSpeechDetected
        ]
        
        if skipRecognitionAnnouncement.contains(command) {
            // 常用指令直接执行，不播报识别结果
            executeCommand(command, originalText: result)
        } else {
            // 其他指令（如计时设置）播报识别结果
            let recognitionMessage = "识别到：\(result)"
            SpeechHelper.shared.speak(recognitionMessage)
            
            // 等待播报完成后再执行相应操作
            let recognitionSpeechDuration = Double(recognitionMessage.count) * 0.15 + 1.0
            DispatchQueue.main.asyncAfter(deadline: .now() + recognitionSpeechDuration) {
                self.executeCommand(command, originalText: result)
            }
        }
    }
    
    /// 智能指令识别 - 使用苹果Natural Language框架
    private func intelligentCommandRecognition(from text: String) -> VoiceCommand {
        let lowercaseText = text.lowercased().replacingOccurrences(of: " ", with: "")
        
        // 优先检查SpeechRecognitionHelper已归一化的指令格式
        if text.hasPrefix("计时") && text.contains("分钟间隔") && text.hasSuffix("分钟") {
            // "计时X分钟间隔Y分钟" 格式
            if let duration = extractDurationFromText(text), let interval = extractIntervalFromText(text) {
                return .setTimerWithInterval(duration: duration, interval: interval)
            }
        }
        
        if text.hasPrefix("计时") && text.hasSuffix("分钟") && !text.contains("间隔") {
            // "计时X分钟" 格式
            if let duration = extractDurationFromText(text) {
                return .setTimer(duration: duration)
            }
        }
        
        if text.hasPrefix("间隔") && text.hasSuffix("分钟") {
            // "间隔X分钟" 格式
            if let interval = extractIntervalFromText(text) {
                return .setInterval(interval: interval)
            }
        }
        
        // 基础指令识别
        if text == "开始计时" || (containsAny(lowercaseText, keywords: ["开始", "启动", "开启"]) && containsAny(lowercaseText, keywords: ["计时", "定时"])) {
            return .startTimer
        }
        
        if text == "暂停计时" || (containsAny(lowercaseText, keywords: ["暂停", "停止", "暂缓"]) && containsAny(lowercaseText, keywords: ["计时", "定时"])) {
            return .pauseTimer
        }
        
        if text == "恢复计时" || (containsAny(lowercaseText, keywords: ["恢复", "继续", "重新开始"]) && containsAny(lowercaseText, keywords: ["计时", "定时"])) {
            return .resumeTimer
        }
        
        if text == "结束计时" || (containsAny(lowercaseText, keywords: ["结束", "停止", "终止"]) && (containsAny(lowercaseText, keywords: ["计时", "定时"]) || lowercaseText.count <= 3)) {
            return .stopTimer
        }
        
        if text == "时间播报" || (containsAny(lowercaseText, keywords: ["时间", "几点", "现在"]) && containsAny(lowercaseText, keywords: ["播报", "报告", "说"])) {
            return .speakTime
        }
        
        if text == "剩余时间" || (containsAny(lowercaseText, keywords: ["剩余", "还有", "剩下"]) && containsAny(lowercaseText, keywords: ["时间", "多久"])) {
            return .speakRemainingTime
        }
        
        if text.isEmpty || text == "未检测到语音" {
            return .noSpeechDetected
        }
        
        return .unrecognized(text: text)
    }
    
    /// 检查文本是否包含任何关键词
    private func containsAny(_ text: String, keywords: [String]) -> Bool {
        return keywords.contains { text.contains($0) }
    }
    
    /// 从文本中提取计时时长
    private func extractDurationFromText(_ text: String) -> Int? {
        // 使用简单的数字提取逻辑
        let numbers = extractNumbers(from: text)
        for number in numbers {
            if TimerSettings.durationRange.contains(number) && text.contains("分钟") {
                return number
            }
        }
        return nil
    }
    
    /// 从文本中提取间隔时间
    private func extractIntervalFromText(_ text: String) -> Int? {
        if text.contains("间隔") {
            let numbers = extractNumbers(from: text)
            for number in numbers {
                if TimerSettings.intervalOptions.contains(number) {
                    return number
                }
            }
        }
        return nil
    }
    
    /// 从文本中提取所有数字
    private func extractNumbers(from text: String) -> [Int] {
        var numbers: [Int] = []
        
        // 提取阿拉伯数字
        let regex = try? NSRegularExpression(pattern: "\\d+", options: [])
        let range = NSRange(location: 0, length: text.utf16.count)
        regex?.enumerateMatches(in: text, options: [], range: range) { match, _, _ in
            if let match = match,
               let swiftRange = Range(match.range, in: text),
               let number = Int(String(text[swiftRange])) {
                numbers.append(number)
            }
        }
        
        // 提取中文数字
        let chineseNumbers = extractChineseNumbers(from: text)
        numbers.append(contentsOf: chineseNumbers)
        
        return numbers
    }
    
    /// 提取中文数字
    private func extractChineseNumbers(from text: String) -> [Int] {
        let chineseToArabic: [String: Int] = [
            "一": 1, "二": 2, "三": 3, "四": 4, "五": 5,
            "六": 6, "七": 7, "八": 8, "九": 9, "十": 10,
            "十一": 11, "十二": 12, "十三": 13, "十四": 14, "十五": 15,
            "十六": 16, "十七": 17, "十八": 18, "十九": 19, "二十": 20,
            "三十": 30, "四十": 40, "五十": 50, "六十": 60,
            "七十": 70, "八十": 80, "九十": 90, "一百": 100
        ]
        
        var numbers: [Int] = []
        for (chinese, arabic) in chineseToArabic {
            if text.contains(chinese) {
                numbers.append(arabic)
            }
        }
        return numbers
    }
    
    /// 执行语音指令
    private func executeCommand(_ command: VoiceCommand, originalText: String) {
        switch command {
        case .startTimer:
            // 开始计时：使用当前界面显示的设置
            if !viewModel.isRunning {
                print("语音指令：开始计时")
                viewModel.startTimer()
                speakConfirmationOnly("开始计时")
            } else {
                speakConfirmationOnly("计时器已在运行")
            }
            
        case .pauseTimer:
            // 暂停计时
            if viewModel.isRunning {
                print("语音指令：暂停计时")
                viewModel.pauseTimer()
                speakConfirmationOnly("暂停计时")
            } else {
                speakConfirmationOnly("计时器未运行")
            }
            
        case .resumeTimer:
            // 恢复计时
            if !viewModel.isRunning && viewModel.remainingSeconds > 0 {
                print("语音指令：恢复计时")
                viewModel.startTimer()
                speakConfirmationOnly("恢复计时")
            } else {
                speakConfirmationOnly("无法恢复计时")
            }
            
        case .stopTimer:
            // 结束计时
            print("语音指令：结束计时")
            viewModel.stopTimer()
            speakConfirmationOnly("结束计时")
            
        case .speakTime:
            // 时间播报
            print("语音指令：时间播报")
            speakConfirmationOnly("") // 不需要确认，直接播报
            SpeechHelper.shared.speakCurrentTime()
            // 播报完成后恢复后台音频
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                self.resumeBackgroundAudioIfNeeded()
            }
            
        case .speakRemainingTime:
            // 剩余时间播报
            print("语音指令：剩余时间")
            if viewModel.remainingSeconds == 0 && !viewModel.isRunning {
                let message = "设置的计时时长为\(viewModel.settings.duration)分钟"
                speakConfirmationOnly(message)
            } else {
                speakConfirmationOnly("")
                SpeechHelper.shared.speakRemainingTime(remainingSeconds: viewModel.remainingSeconds)
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    self.resumeBackgroundAudioIfNeeded()
                }
            }
            
        case .setTimer(let duration):
            print("语音指令：设置计时时长为\(duration)分钟并开始")
            // 先停止当前计时器（如果正在运行）
            if viewModel.isRunning {
                viewModel.stopTimer()
            }
            var newSettings = viewModel.settings
            newSettings.duration = duration
            viewModel.updateSettings(newSettings)
            viewModel.startTimer()
            speakConfirmationOnly("开始计时\(duration)分钟")
            
        case .setInterval(let interval):
            print("语音指令：设置提醒间隔为\(interval)分钟")
            var newSettings = viewModel.settings
            newSettings.interval = interval
            viewModel.updateSettings(newSettings)
            speakConfirmationOnly("设置提醒间隔为\(interval)分钟")
            
        case .setTimerWithInterval(let duration, let interval):
            print("语音指令：设置计时\(duration)分钟，间隔\(interval)分钟并开始")
            // 先停止当前计时器（如果正在运行）
            if viewModel.isRunning {
                viewModel.stopTimer()
            }
            var newSettings = viewModel.settings
            newSettings.duration = duration
            newSettings.interval = interval
            viewModel.updateSettings(newSettings)
            viewModel.startTimer()
            speakConfirmationOnly("开始计时\(duration)分钟，间隔\(interval)分钟")
            
        case .noSpeechDetected:
            speakConfirmationOnly("请点击按钮后再说话")
            
        case .unrecognized(let text):
            // 未识别的指令，直接播报原文
            speakConfirmationOnly(text)
        }
    }
    
    /// 只播报确认信息，不执行操作
    private func speakConfirmationOnly(_ message: String) {
        if !message.isEmpty {
            SpeechHelper.shared.speak(message)
            
            // 等待播报完成后恢复后台音频
            let estimatedSpeechDuration = Double(message.count) * 0.15 + 1.0
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
        // 只有在计时器运行时才恢复后台音乐
        if viewModel.isRunning {
            print("恢复后台音乐")
            ContinuousAudioPlayer.shared.startContinuousPlayback()
        } else {
            print("计时器未运行，不恢复后台音乐")
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