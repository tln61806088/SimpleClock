import Foundation
import Speech
import AVFoundation

/// 语音识别与归一化工具类
class SpeechRecognitionHelper: NSObject {
    
    /// 单例实例
    static let shared = SpeechRecognitionHelper()
    
    // MARK: - Private Properties
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private var isRecording = false
    private var completionHandler: ((String) -> Void)?
    private var lastRecognizedText: String?
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        
        // 请求语音识别权限
        requestSpeechRecognitionPermission()
    }
    
    // MARK: - Public Methods
    
    /// 开始语音识别
    /// - Parameter completion: 识别完成回调，返回归一化后的指令
    func startRecording(completion: @escaping (String) -> Void) {
        guard !isRecording else { return }
        
        completionHandler = completion
        
        // 检查权限状态
        let authStatus = SFSpeechRecognizer.authorizationStatus()
        
        switch authStatus {
        case .notDetermined:
            // 首次请求权限
            SFSpeechRecognizer.requestAuthorization { [weak self] status in
                DispatchQueue.main.async {
                    if status == .authorized {
                        self?.startRecording(completion: completion)
                    } else {
                        completion("需要语音识别权限才能使用此功能，请在设置中允许SimpleClock访问语音识别")
                    }
                }
            }
            return
            
        case .denied, .restricted:
            completion("语音识别权限被拒绝，请在设置 > 隐私与安全 > 语音识别中允许SimpleClock访问")
            return
            
        case .authorized:
            break
            
        @unknown default:
            completion("语音识别权限状态未知")
            return
        }
        
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            completion("语音识别服务当前不可用，请稍后再试")
            return
        }
        
        do {
            try startRecognitionSession()
        } catch {
            completion("语音识别启动失败：\(error.localizedDescription)")
        }
    }
    
    /// 停止语音识别
    func stopRecording() {
        guard isRecording else { return }
        
        isRecording = false
        
        // 停止音频引擎
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        // 结束识别请求
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        // 取消识别任务
        recognitionTask?.cancel()
        recognitionTask = nil
    }
    
    /// 获取最后识别的文本
    func getLastRecognizedText() -> String? {
        let text = lastRecognizedText
        lastRecognizedText = nil  // 清空，避免重复使用
        return text
    }
    
    // MARK: - Private Methods
    
    /// 请求语音识别权限
    private func requestSpeechRecognitionPermission() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    print("语音识别权限已授权")
                case .denied, .restricted, .notDetermined:
                    print("语音识别权限未授权")
                @unknown default:
                    print("语音识别权限状态未知")
                }
            }
        }
    }
    
    /// 启动识别会话
    private func startRecognitionSession() throws {
        // 取消之前的任务
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // 配置音频会话 - iOS版本兼容性处理
        let audioSession = AVAudioSession.sharedInstance()
        if #available(iOS 16.0, *) {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        } else {
            // iOS 15.x fallback
            try audioSession.setCategory(.record, options: .duckOthers)
        }
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // 创建识别请求
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw NSError(domain: "SpeechRecognitionHelper", code: 1, userInfo: [NSLocalizedDescriptionKey: "无法创建识别请求"])
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // 获取音频输入节点
        let inputNode = audioEngine.inputNode
        
        // 创建识别任务
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            self?.handleRecognitionResult(result: result, error: error)
        }
        
        // 配置音频格式
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        // 启动音频引擎
        audioEngine.prepare()
        try audioEngine.start()
        
        isRecording = true
    }
    
    /// 处理识别结果
    private func handleRecognitionResult(result: SFSpeechRecognitionResult?, error: Error?) {
        if let result = result {
            let recognizedText = result.bestTranscription.formattedString
            
            // 存储最新的识别结果（即使是部分结果）
            let normalizedCommand = normalizeCommand(recognizedText)
            lastRecognizedText = normalizedCommand
            
            // 如果设置了实时回调，也可以调用
            if result.isFinal {
                DispatchQueue.main.async {
                    self.completionHandler?(normalizedCommand)
                }
            }
        }
        
        if let error = error {
            print("语音识别错误: \(error)")
            lastRecognizedText = "识别失败"
            DispatchQueue.main.async {
                self.completionHandler?("识别失败")
            }
        }
    }
    
    /// 归一化语音指令
    /// - Parameter text: 原始识别文本
    /// - Returns: 归一化后的指令
    private func normalizeCommand(_ text: String) -> String {
        let lowercaseText = text.lowercased().replacingOccurrences(of: " ", with: "")
        
        // 暂停相关指令
        if lowercaseText.contains("暂停") {
            return "暂停计时"
        }
        
        // 开始相关指令
        if lowercaseText.contains("开始") {
            return "开始计时"
        }
        
        // 恢复相关指令
        if lowercaseText.contains("恢复") {
            return "恢复计时"
        }
        
        // 结束相关指令
        if lowercaseText.contains("结束") {
            return "结束计时"
        }
        
        // 时间播报
        if lowercaseText.contains("时间播报") || lowercaseText.contains("播报时间") {
            return "时间播报"
        }
        
        // 剩余时间
        if lowercaseText.contains("剩余时间") || lowercaseText.contains("播报剩余时间") {
            return "剩余时间"
        }
        
        // 计时设置指令
        if let duration = extractDuration(from: text) {
            return "计时\(duration)分钟"
        }
        
        // 间隔设置指令
        if let interval = extractInterval(from: text) {
            return "间隔\(interval)分钟"
        }
        
        return "未识别的指令：\(text)"
    }
    
    /// 从文本中提取计时时长
    private func extractDuration(from text: String) -> Int? {
        // 匹配"计时xx分钟"或"xx分钟计时"等模式
        let patterns = [
            "计时(\\d+)分钟",
            "计时([一二三四五六七八九十百]+)分钟",
            "(\\d+)分钟计时",
            "([一二三四五六七八九十百]+)分钟计时"
        ]
        
        for pattern in patterns {
            if let match = extractNumber(from: text, pattern: pattern) {
                return match
            }
        }
        
        return nil
    }
    
    /// 从文本中提取间隔时间
    private func extractInterval(from text: String) -> Int? {
        // 匹配"间隔xx分钟"等模式
        let patterns = [
            "间隔(\\d+)分钟",
            "间隔([一二三四五六七八九十百]+)分钟",
            "每隔(\\d+)分钟",
            "每隔([一二三四五六七八九十百]+)分钟"
        ]
        
        for pattern in patterns {
            if let match = extractNumber(from: text, pattern: pattern) {
                return match
            }
        }
        
        return nil
    }
    
    /// 从文本中提取数字（支持中文数字转换）
    private func extractNumber(from text: String, pattern: String) -> Int? {
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: text.utf16.count)
        
        if let match = regex?.firstMatch(in: text, options: [], range: range) {
            let matchRange = match.range(at: 1)
            if matchRange.location != NSNotFound,
               let swiftRange = Range(matchRange, in: text) {
                let numberString = String(text[swiftRange])
                return convertChineseNumber(numberString) ?? Int(numberString)
            }
        }
        
        return nil
    }
    
    /// 转换中文数字为阿拉伯数字
    private func convertChineseNumber(_ chineseNumber: String) -> Int? {
        let chineseToArabic: [String: Int] = [
            "一": 1, "二": 2, "三": 3, "四": 4, "五": 5,
            "六": 6, "七": 7, "八": 8, "九": 9, "十": 10,
            "二十": 20, "三十": 30, "四十": 40, "五十": 50,
            "六十": 60, "七十": 70, "八十": 80, "九十": 90,
            "一百": 100
        ]
        
        // 直接匹配
        if let number = chineseToArabic[chineseNumber] {
            return number
        }
        
        // 处理复合数字（如"二十五"）
        if chineseNumber.contains("十") && chineseNumber.count > 1 {
            let components = chineseNumber.components(separatedBy: "十")
            if components.count == 2 {
                let tens = components[0].isEmpty ? 1 : (chineseToArabic[components[0]] ?? 0)
                let ones = components[1].isEmpty ? 0 : (chineseToArabic[components[1]] ?? 0)
                return tens * 10 + ones
            }
        }
        
        return nil
    }
}