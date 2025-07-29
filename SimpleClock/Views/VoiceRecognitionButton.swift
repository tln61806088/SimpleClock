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
/// 长方形按钮，点击震动并开始语音识别，UI保持不变
struct VoiceRecognitionButton: View {
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject var viewModel: TimerViewModel
    @State private var recordingTimer: Timer?
    @State private var isRecording = false
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.voiceButtonInternalSpacing) {
            // 主按钮 - 简洁边框设计
            ZStack {
                // 边框
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.voiceButton)
                    .stroke(themeManager.currentTheme.primaryGradient, lineWidth: DesignSystem.Borders.primaryBorder.lineWidth)
                    .frame(maxWidth: .infinity, minHeight: DesignSystem.Sizes.voiceButtonHeight, maxHeight: DesignSystem.Sizes.voiceButtonHeight)
                
                // 图标和文字
                VStack(spacing: DesignSystem.Spacing.voiceButtonInternalSpacing) {
                    // 语音图标 - 固定为麦克风图标
                    ZStack {
                        // 图标背景圆形边框
                        Circle()
                            .stroke(themeManager.currentTheme.primaryGradient.opacity(0.3), lineWidth: DesignSystem.Borders.thinBorder.lineWidth)
                            .frame(width: DesignSystem.Sizes.voiceIconBackground, height: DesignSystem.Sizes.voiceIconBackground)
                        
                        Image(systemName: "mic.circle.fill")
                            .font(DesignSystem.Fonts.buttonIcon(size: DesignSystem.Sizes.voiceIcon))
                            .foregroundStyle(themeManager.currentTheme.primaryGradient)
                            .shadow(color: DesignSystem.Shadows.primaryShadow.color,
                                   radius: DesignSystem.Shadows.primaryShadow.radius,
                                   x: DesignSystem.Shadows.primaryShadow.x,
                                   y: DesignSystem.Shadows.primaryShadow.y)
                            .shadow(color: DesignSystem.Shadows.secondaryShadow.color,
                                   radius: DesignSystem.Shadows.secondaryShadow.radius,
                                   x: DesignSystem.Shadows.secondaryShadow.x,
                                   y: DesignSystem.Shadows.secondaryShadow.y)
                            .scaleEffect(isRecording ? 1.5 : 1.0)
                            .animation(isRecording ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true) : .easeOut(duration: 0.2), value: isRecording)
                    }
                    
                    // 状态文字 - 固定为"语音识别"
                    Text("语音识别")
                        .font(DesignSystem.Fonts.buttonText(size: DesignSystem.Sizes.voiceStateText))
                        .foregroundStyle(themeManager.currentTheme.primaryGradient)
                        .shadow(color: DesignSystem.Shadows.primaryShadow.color,
                               radius: DesignSystem.Shadows.primaryShadow.radius,
                               x: DesignSystem.Shadows.primaryShadow.x,
                               y: DesignSystem.Shadows.primaryShadow.y)
                        .shadow(color: DesignSystem.Shadows.secondaryShadow.color,
                               radius: DesignSystem.Shadows.secondaryShadow.radius,
                               x: DesignSystem.Shadows.secondaryShadow.x,
                               y: DesignSystem.Shadows.secondaryShadow.y)
                        .multilineTextAlignment(.center)
                }
            }
            .onTapGesture {
                handleTapGesture()
            }
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                isPressed = pressing
            }, perform: {})
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("语音识别按钮")
        .accessibilityHint("点击开始语音识别")
        .accessibilityAddTraits(.isButton)
    }
    
    @State private var isPressed = false
    
    /// 处理点击手势 - 支持开始/停止录音
    private func handleTapGesture() {
        if isRecording {
            // 正在录音，点击停止
            finishVoiceRecognition()
        } else {
            // 未在录音，点击开始
            HapticHelper.shared.voiceRecognitionStartImpact()
            startVoiceRecognition()
        }
    }
    
    /// 开始语音识别 - 简化版本
    private func startVoiceRecognition() {
        // 降低后台音乐音量，但不停止播放
        ContinuousAudioPlayer.shared.setVolume(0.001)
        
        // 播报提示
        SpeechHelper.shared.speak("请说出您的计时要求")
        
        // 等待提示播报完成后开始录音和动画（约2秒）
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // 开始录音动画
            isRecording = true
            
            // 开始语音识别
            SpeechRecognitionHelper.shared.startRecording { _ in
                // 录音过程中不处理结果
            }
            
            // 5秒后自动停止并处理结果
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
                finishVoiceRecognition()
            }
        }
    }
    
    /// 完成语音识别
    private func finishVoiceRecognition() {
        // 立即停止录音动画
        isRecording = false
        
        // 清理计时器
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        // 停止录音震动反馈
        HapticHelper.shared.voiceRecognitionEndImpact()
        
        // 停止语音识别
        SpeechRecognitionHelper.shared.stopRecording()
        
        // 使用更短的延迟，避免长时间阻塞主线程
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let recognizedText = SpeechRecognitionHelper.shared.getLastRecognizedText(), 
               !recognizedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               recognizedText != "未检测到语音" && recognizedText != "识别失败" {
                
                // 识别成功震动反馈
                HapticHelper.shared.voiceRecognitionCompleteImpact()
                
                // 清空识别结果，避免重复使用
                SpeechRecognitionHelper.shared.clearLastRecognizedText()
                handleVoiceRecognitionResult(recognizedText)
            } else {
                // 清空无效结果
                SpeechRecognitionHelper.shared.clearLastRecognizedText()
                handleVoiceRecognitionResult("未检测到语音")
            }
        }
    }
    
    /// 处理语音识别结果 - 使用苹果框架进行智能指令识别
    private func handleVoiceRecognitionResult(_ result: String) {
        // 使用苹果的Natural Language框架进行指令识别
        let command = intelligentCommandRecognition(from: result)
        
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
            let recognitionSpeechDuration = Double(recognitionMessage.count) * 0.2 + 1.0
            DispatchQueue.main.asyncAfter(deadline: .now() + recognitionSpeechDuration) {
                executeCommand(command, originalText: result)
            }
        }
    }
    
    /// 智能指令识别 - 使用苹果Natural Language框架
    private func intelligentCommandRecognition(from text: String) -> VoiceCommand {
        let lowercaseText = text.lowercased().replacingOccurrences(of: " ", with: "")
        
        
        // 优先检查复合指令格式
        if text.hasPrefix("计时") && hasIntervalKeyword(in: text) {
            // "计时X小时Y分钟间隔Z分钟" 或 "计时X分钟每隔Y分钟" 或 "计时X分钟每Y分钟" 等复合格式
            let duration = extractDurationFromText(text)
            let interval = extractIntervalFromText(text)
            
            if let duration = duration, let interval = interval {
                return .setTimerWithInterval(duration: duration, interval: interval)
            }
        }
        
        if text.hasPrefix("计时") && (text.contains("分钟") || text.contains("小时")) && !hasIntervalKeyword(in: text) {
            // "计时X分钟" 或 "计时X小时" 或 "计时X小时Y分钟" 格式（不包含间隔关键词）
            if let duration = extractDurationFromText(text) {
                return .setTimer(duration: duration)
            }
        }
        
        if hasIntervalKeyword(in: text) && (text.contains("分钟") || text.contains("小时")) {
            // "间隔X分钟" 或 "每隔X分钟" 或 "每X分钟" 或 "隔X分钟" 等格式
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
    
    /// 检查文本是否包含间隔关键词
    private func hasIntervalKeyword(in text: String) -> Bool {
        // 检测各种间隔关键词
        return text.contains("间隔") ||
               text.contains("每隔") ||
               // 修复：移除对"计时"开头的限制，因为"计时x小时，间隔x分钟"也应该被识别
               (text.contains("每") && (text.contains("分钟") || text.contains("小时")))
    }
    
    /// 从文本中提取计时时长
    private func extractDurationFromText(_ text: String) -> Int? {
        var totalMinutes = 0
        // 先找到计时关键词的位置，只在计时部分查找时长
        let timerKeywords = ["计时"]
        var timerKeywordRange: Range<String.Index>?
        
        for keyword in timerKeywords {
            if let range = text.range(of: keyword) {
                timerKeywordRange = range
                break
            }
        }
        
        // 确定计时部分的文本范围（从计时关键词到间隔关键词之前）
        var timerText = text
        if let timerRange = timerKeywordRange {
            let startIndex = timerRange.upperBound
            
            // 找到间隔关键词的位置，限制搜索范围
            let intervalKeywords = ["间隔", "每隔"]  // 只匹配明确的间隔关键词
            var intervalStart: String.Index?
            
            for intervalKeyword in intervalKeywords {
                if let intervalRange = text.range(of: intervalKeyword, range: startIndex..<text.endIndex) {
                    if intervalStart == nil || intervalRange.lowerBound < intervalStart! {
                        intervalStart = intervalRange.lowerBound
                    }
                }
            }
            
            // 提取计时部分的文本
            if let intervalIndex = intervalStart {
                timerText = String(text[startIndex..<intervalIndex])
            } else {
                timerText = String(text[startIndex...])
            }
        }
        
        // 在计时部分提取时长
        if timerText.contains("小时") && timerText.contains("分钟") {
            // 提取计时部分的小时数
            if let hours = extractHoursFromTimerText(timerText) {
                totalMinutes += hours * 60
            }
            // 提取计时部分的分钟数（小时后面的分钟）
            if let minutes = extractMinutesAfterHoursInTimerText(timerText) {
                totalMinutes += minutes
            }
        }
        else if timerText.contains("小时") {
            if let hours = extractHoursFromTimerText(timerText) {
                totalMinutes = hours * 60
            }
        }
        else if timerText.contains("分钟") {
            let numbers = extractNumbers(from: timerText)
            for number in numbers {
                if number >= 1 && number <= 720 {
                    totalMinutes = number
                    break
                }
            }
        }
        
        
        // 验证总时长是否在允许范围内
        if TimerSettings.durationRange.contains(totalMinutes) {
            return totalMinutes
        }
        
        return nil
    }
    
    /// 从计时部分文本中提取小时数
    private func extractHoursFromTimerText(_ timerText: String) -> Int? {
        let numbers = extractNumbers(from: timerText)
        
        // 查找"小时"前面的数字
        for number in numbers {
            if number >= 1 && number <= 12 { // 最多12小时（720分钟）
                // 验证这个数字是否在"小时"之前
                if let hourIndex = timerText.range(of: "小时"),
                   let _ = findNumberStringBeforeIndexInText(in: timerText, beforeRange: hourIndex, targetNumber: number) {
                    return number
                }
            }
        }
        return nil
    }
    
    /// 从计时部分文本中提取小时后面的分钟数
    private func extractMinutesAfterHoursInTimerText(_ timerText: String) -> Int? {
        let numbers = extractNumbers(from: timerText)
        
        // 查找"分钟"前面的数字，但要在"小时"后面
        if let hourIndex = timerText.range(of: "小时") {
            let textAfterHour = String(timerText[hourIndex.upperBound...])
            
            for number in numbers {
                if number >= 0 && number <= 59 { // 分钟数应该小于60
                    if textAfterHour.contains("\(number)") && textAfterHour.contains("分钟") {
                        return number
                    }
                    
                    // 检查中文数字
                    let chineseToArabic: [String: Int] = [
                        "一": 1, "二": 2, "两": 2, "三": 3, "四": 4, "五": 5,
                        "六": 6, "七": 7, "八": 8, "九": 9, "十": 10,
                        "十一": 11, "十二": 12, "十三": 13, "十四": 14, "十五": 15,
                        "十六": 16, "十七": 17, "十八": 18, "十九": 19, "二十": 20,
                        "二十一": 21, "二十二": 22, "二十三": 23, "二十四": 24, "二十五": 25,
                        "二十六": 26, "二十七": 27, "二十八": 28, "二十九": 29, "三十": 30,
                        "三十一": 31, "三十二": 32, "三十三": 33, "三十四": 34, "三十五": 35,
                        "三十六": 36, "三十七": 37, "三十八": 38, "三十九": 39, "四十": 40,
                        "四十一": 41, "四十二": 42, "四十三": 43, "四十四": 44, "四十五": 45,
                        "四十六": 46, "四十七": 47, "四十八": 48, "四十九": 49, "五十": 50,
                        "五十一": 51, "五十二": 52, "五十三": 53, "五十四": 54, "五十五": 55,
                        "五十六": 56, "五十七": 57, "五十八": 58, "五十九": 59
                    ]
                    
                    for (chinese, arabic) in chineseToArabic {
                        if arabic == number && textAfterHour.contains(chinese) && textAfterHour.contains("分钟") {
                            return number
                        }
                    }
                }
            }
        }
        return nil
    }
    
    /// 在指定文本和位置前查找数字字符串
    private func findNumberStringBeforeIndexInText(in text: String, beforeRange: Range<String.Index>, targetNumber: Int) -> String? {
        let textBeforeIndex = String(text[..<beforeRange.lowerBound])
        
        // 检查阿拉伯数字
        if textBeforeIndex.contains("\(targetNumber)") {
            return "\(targetNumber)"
        }
        
        // 检查中文数字
        let chineseNumbers = ["一": 1, "二": 2, "两": 2, "三": 3, "四": 4, "五": 5,
                             "六": 6, "七": 7, "八": 8, "九": 9, "十": 10,
                             "十一": 11, "十二": 12]
        
        for (chinese, arabic) in chineseNumbers {
            if arabic == targetNumber && textBeforeIndex.contains(chinese) {
                return chinese
            }
        }
        
        return nil
    }
    
    /// 从文本中提取小时数
    private func extractHoursFromText(_ text: String) -> Int? {
        let numbers = extractNumbers(from: text)
        
        // 查找"小时"前面的数字
        for number in numbers {
            if number >= 1 && number <= 12 { // 最多12小时（720分钟）
                // 验证这个数字是否在"小时"之前
                if let hourIndex = text.range(of: "小时"),
                   let _ = findNumberStringBeforeIndex(in: text, beforeRange: hourIndex, targetNumber: number) {
                    return number
                }
            }
        }
        return nil
    }
    
    /// 提取小时后面的分钟数
    private func extractMinutesAfterHours(_ text: String) -> Int? {
        let numbers = extractNumbers(from: text)
        
        // 查找"分钟"前面的数字，但要在"小时"后面
        if let hourIndex = text.range(of: "小时") {
            let textAfterHour = String(text[hourIndex.upperBound...])
            
            for number in numbers {
                if number >= 1 && number <= 59 { // 分钟数应该小于60
                    if textAfterHour.contains("\(number)") && textAfterHour.contains("分钟") {
                        return number
                    }
                }
            }
        }
        return nil
    }
    
    /// 在指定位置前查找数字字符串
    private func findNumberStringBeforeIndex(in text: String, beforeRange: Range<String.Index>, targetNumber: Int) -> String? {
        let textBeforeIndex = String(text[..<beforeRange.lowerBound])
        
        // 检查阿拉伯数字
        if textBeforeIndex.contains("\(targetNumber)") {
            return "\(targetNumber)"
        }
        
        // 检查中文数字
        let chineseNumbers = ["一": 1, "二": 2, "两": 2, "三": 3, "四": 4, "五": 5,
                             "六": 6, "七": 7, "八": 8, "九": 9, "十": 10,
                             "十一": 11, "十二": 12]
        
        for (chinese, arabic) in chineseNumbers {
            if arabic == targetNumber && textBeforeIndex.contains(chinese) {
                return chinese
            }
        }
        
        return nil
    }
    
    /// 从文本中提取间隔时间
    private func extractIntervalFromText(_ text: String) -> Int? {
        // 检查是否包含任何间隔关键词
        let intervalKeywords = ["间隔", "每隔", "每"]  // 扩展间隔关键词，包括"每"
        let hasIntervalKeyword = intervalKeywords.contains { text.contains($0) }
        
        if hasIntervalKeyword {
            var intervalMinutes = 0
            
            // 处理小时 + 分钟的复合格式（如"间隔一小时三十分钟"、"每隔一小时三十分钟"）
            if text.contains("小时") && text.contains("分钟") {
                // 提取间隔中的小时数
                if let hours = extractIntervalHoursFromText(text) {
                    intervalMinutes += hours * 60
                }
                // 提取间隔中的分钟数（小时后面的分钟）
                if let minutes = extractIntervalMinutesAfterHours(text) {
                    intervalMinutes += minutes
                }
            }
            // 只有小时（如"间隔一小时"、"每一小时"、"隔一小时"）
            else if text.contains("小时") {
                if let hours = extractIntervalHoursFromText(text) {
                    intervalMinutes = hours * 60
                }
            }
            // 只有分钟（如"间隔三分钟"、"每隔三分钟"、"每三分钟"、"隔三分钟"）
            else if text.contains("分钟") {
                intervalMinutes = extractIntervalMinutesFromText(text) ?? 0
            }
            // 没有单位，默认按分钟处理
            else {
                intervalMinutes = extractIntervalMinutesFromText(text) ?? 0
            }
            
            // 验证间隔时间是否合理（0-720分钟）
            if intervalMinutes >= 0 && intervalMinutes <= 720 {
                return intervalMinutes
            }
        }
        return nil
    }
    
    /// 从间隔文本中提取小时数
    private func extractIntervalHoursFromText(_ text: String) -> Int? {
        let numbers = extractNumbers(from: text)
        let intervalKeywords = ["间隔", "每隔"]  // 只匹配明确的间隔关键词
        
        
        // 找到最早出现的间隔关键词
        var earliestIntervalRange: Range<String.Index>?
        for keyword in intervalKeywords {
            if let range = text.range(of: keyword) {
                if earliestIntervalRange == nil || range.lowerBound < earliestIntervalRange!.lowerBound {
                    earliestIntervalRange = range
                }
            }
        }
        
        // 在间隔关键词之后查找"小时"
        if let intervalRange = earliestIntervalRange {
            let searchText = String(text[intervalRange.upperBound...])
            
            if let hourIndex = searchText.range(of: "小时") {
                // 提取间隔关键词到小时之间的文本
                let intervalToHourText = String(searchText[..<hourIndex.lowerBound])
                
                for number in numbers {
                    if number >= 1 && number <= 12 {
                        // 检查这个数字是否在间隔到小时的文本中
                        if intervalToHourText.contains("\(number)") {
                            return number
                        }
                        
                        // 检查中文数字
                        let chineseToArabic: [String: Int] = [
                            "一": 1, "二": 2, "两": 2, "三": 3, "四": 4, "五": 5,
                            "六": 6, "七": 7, "八": 8, "九": 9, "十": 10,
                            "十一": 11, "十二": 12
                        ]
                        
                        for (chinese, arabic) in chineseToArabic {
                            if arabic == number && intervalToHourText.contains(chinese) {
                                return number
                            }
                        }
                    }
                }
            } else {
            }
        } else {
        }
        
        return nil
    }
    
    /// 提取间隔中小时后面的分钟数
    private func extractIntervalMinutesAfterHours(_ text: String) -> Int? {
        let numbers = extractNumbers(from: text)
        let intervalKeywords = ["间隔", "每隔"]  // 只匹配明确的间隔关键词
        
        
        // 找到最早出现的间隔关键词
        var earliestIntervalRange: Range<String.Index>?
        for keyword in intervalKeywords {
            if let range = text.range(of: keyword) {
                if earliestIntervalRange == nil || range.lowerBound < earliestIntervalRange!.lowerBound {
                    earliestIntervalRange = range
                }
            }
        }
        
        // 在间隔关键词之后查找"小时"和"分钟"
        if let intervalRange = earliestIntervalRange {
            let searchText = String(text[intervalRange.upperBound...])
            
            if let hourIndex = searchText.range(of: "小时"),
               let minuteIndex = searchText.range(of: "分钟") {
                // 确保分钟在小时之后
                if hourIndex.upperBound <= minuteIndex.lowerBound {
                    let minuteText = String(searchText[hourIndex.upperBound..<minuteIndex.lowerBound])
                    
                    for number in numbers {
                        if number >= 1 && number <= 59 && minuteText.contains("\(number)") {
                            return number
                        }
                    }
                } else {
                }
            } else {
            }
        } else {
        }
        
        return nil
    }
    
    /// 从间隔文本中提取分钟数
    private func extractIntervalMinutesFromText(_ text: String) -> Int? {
        let numbers = extractNumbers(from: text)
        let intervalKeywords = ["间隔", "每隔"]  // 只匹配明确的间隔关键词
        
        // 找到最早出现的间隔关键词
        var earliestIntervalIndex: String.Index?
        for keyword in intervalKeywords {
            if let range = text.range(of: keyword) {
                if earliestIntervalIndex == nil || range.lowerBound < earliestIntervalIndex! {
                    earliestIntervalIndex = range.upperBound
                }
            }
        }
        
        // 在间隔关键词之后查找数字
        if let intervalIndex = earliestIntervalIndex {
            let intervalText = String(text[intervalIndex...])
            
            for number in numbers {
                if number >= 0 && number <= 720 && intervalText.contains("\(number)") {
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
            // 基础数字
            "一": 1, "二": 2, "两": 2, "三": 3, "四": 4, "五": 5,
            "六": 6, "七": 7, "八": 8, "九": 9, "十": 10,
            "十一": 11, "十二": 12, "十三": 13, "十四": 14, "十五": 15,
            "十六": 16, "十七": 17, "十八": 18, "十九": 19, "二十": 20,
            "二十一": 21, "二十二": 22, "二十三": 23, "二十四": 24, "二十五": 25,
            "二十六": 26, "二十七": 27, "二十八": 28, "二十九": 29, "三十": 30,
            "三十一": 31, "三十二": 32, "三十三": 33, "三十四": 34, "三十五": 35,
            "三十六": 36, "三十七": 37, "三十八": 38, "三十九": 39, "四十": 40,
            "四十一": 41, "四十二": 42, "四十三": 43, "四十四": 44, "四十五": 45,
            "四十六": 46, "四十七": 47, "四十八": 48, "四十九": 49, "五十": 50,
            "五十一": 51, "五十二": 52, "五十三": 53, "五十四": 54, "五十五": 55,
            "五十六": 56, "五十七": 57, "五十八": 58, "五十九": 59, "六十": 60,
            "七十": 70, "八十": 80, "九十": 90, "一百": 100,
            // 常用大数字
            "一百二十": 120, "一百五十": 150, "一百八十": 180,
            "二百": 200, "三百": 300, "四百": 400, "五百": 500,
            "六百": 600, "七百": 700, "七百二十": 720
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
                viewModel.startTimer()
                speakConfirmationOnly("开始计时")
            } else {
                speakConfirmationOnly("计时器已在运行")
            }
            
        case .pauseTimer:
            // 暂停计时
            if viewModel.isRunning {
                viewModel.pauseTimer()
                // 暂停计时时，保持后台音乐继续播放
                speakConfirmationOnlyWithAudio("暂停计时", shouldMaintainAudio: true)
            } else {
                speakConfirmationOnly("计时器未运行")
            }
            
        case .resumeTimer:
            // 恢复计时
            if !viewModel.isRunning && viewModel.remainingSeconds > 0 {
                viewModel.startTimer()
                speakConfirmationOnly("恢复计时")
            } else {
                speakConfirmationOnly("无法恢复计时")
            }
            
        case .stopTimer:
            // 结束计时
            viewModel.stopTimer()
            speakConfirmationOnly("结束计时")
            
        case .speakTime:
            // 时间播报
            speakConfirmationOnly("") // 不需要确认，直接播报
            SpeechHelper.shared.speakCurrentTime()
            // 播报完成后恢复后台音频
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                resumeBackgroundAudioIfNeeded()
            }
            
        case .speakRemainingTime:
            // 剩余时间播报
            if viewModel.remainingSeconds == 0 && !viewModel.isRunning {
                let message = "设置的计时时长为\(viewModel.settings.duration)分钟"
                speakConfirmationOnly(message)
            } else {
                speakConfirmationOnly("")
                SpeechHelper.shared.speakRemainingTime(remainingSeconds: viewModel.remainingSeconds)
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    resumeBackgroundAudioIfNeeded()
                }
            }
            
        case .setTimer(let duration):
            // 先停止当前计时器（如果正在运行）
            if viewModel.isRunning {
                viewModel.stopTimer()
            }
            var newSettings = viewModel.settings
            newSettings.duration = duration
            viewModel.updateSettings(newSettings)
            viewModel.startTimer()
            let durationText = formatDurationText(duration)
            speakConfirmationOnly("开始计时\(durationText)")
            
        case .setInterval(let interval):
            var newSettings = viewModel.settings
            newSettings.interval = interval
            viewModel.updateSettings(newSettings)
            let intervalText = formatDurationText(interval)
            speakConfirmationOnly("设置提醒间隔为\(intervalText)")
            
        case .setTimerWithInterval(let duration, let interval):
            // 先停止当前计时器（如果正在运行）
            if viewModel.isRunning {
                viewModel.stopTimer()
            }
            var newSettings = viewModel.settings
            newSettings.duration = duration
            newSettings.interval = interval
            viewModel.updateSettings(newSettings)
            viewModel.startTimer()
            let durationText = formatDurationText(duration)
            let intervalText = formatDurationText(interval)
            speakConfirmationOnly("开始计时\(durationText)，间隔\(intervalText)")
            
        case .noSpeechDetected:
            speakConfirmationOnly("未识别到有效计时要求，请再试一次")
            
        case .unrecognized(let text):
            // 未识别的指令，提供友好的提示
            if text.isEmpty || text == "未检测到语音" || text == "识别失败" {
                speakConfirmationOnly("未识别到有效计时要求，请再试一次")
            } else {
                speakConfirmationOnly("未识别到有效计时要求，请再试一次")
            }
        }
    }
    
    /// 只播报确认信息，不执行操作
    private func speakConfirmationOnly(_ message: String) {
        if !message.isEmpty {
            // 播报前暂时降低后台音乐音量，确保语音清晰
            if ContinuousAudioPlayer.shared.isContinuouslyPlaying {
                ContinuousAudioPlayer.shared.setVolume(0.001)
            }
            
            SpeechHelper.shared.speak(message)
            
            // 等待播报完成后恢复后台音频
            let estimatedSpeechDuration: Double
            if message == "开始计时" {
                estimatedSpeechDuration = 2.1  // "开始计时"单独设置为2.1秒
            } else {
                estimatedSpeechDuration = Double(message.count) * 0.2 + 1.0  // 其他消息使用通用公式
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + estimatedSpeechDuration) {
                resumeBackgroundAudioIfNeeded()
            }
        } else {
            // 没有播报内容，立即恢复后台音频
            resumeBackgroundAudioIfNeeded()
        }
    }
    
    /// 播报确认信息，支持自定义音频维持逻辑
    private func speakConfirmationOnlyWithAudio(_ message: String, shouldMaintainAudio: Bool) {
        if !message.isEmpty {
            SpeechHelper.shared.speak(message)
            
            // 等待播报完成后处理音频
            let estimatedSpeechDuration = Double(message.count) * 0.2 + 1.0
            DispatchQueue.main.asyncAfter(deadline: .now() + estimatedSpeechDuration) {
                if shouldMaintainAudio {
                    // 暂停计时时，强制恢复后台音乐播放
                    DispatchQueue.main.async {
                        ContinuousAudioPlayer.shared.startContinuousPlayback()
                    }
                } else {
                    resumeBackgroundAudioIfNeeded()
                }
            }
        } else {
            if shouldMaintainAudio {
                // 没有播报内容，立即恢复后台音频
                DispatchQueue.main.async {
                    ContinuousAudioPlayer.shared.startContinuousPlayback()
                }
            } else {
                resumeBackgroundAudioIfNeeded()
            }
        }
    }
    
    /// 如果需要，恢复后台音频播放 - 简化版本
    private func resumeBackgroundAudioIfNeeded() {
        // 只有在计时器运行时才恢复后台音乐
        if viewModel.isRunning {
            if ContinuousAudioPlayer.shared.isContinuouslyPlaying {
                ContinuousAudioPlayer.shared.setVolume(0.005)  // 保持静音音量
            } else {
                // 避免无限递归，只在真正需要时启动
                DispatchQueue.main.async {
                    ContinuousAudioPlayer.shared.startContinuousPlayback()
                }
            }
        }
    }
    
    /// 格式化时长文本，支持小时和分钟的自然表达
    private func formatDurationText(_ minutes: Int) -> String {
        if minutes == 0 {
            return "不提醒"
        } else if minutes < 60 {
            return "\(minutes)分钟"
        } else if minutes % 60 == 0 {
            let hours = minutes / 60
            return "\(hours)小时"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)小时\(remainingMinutes)分钟"
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
