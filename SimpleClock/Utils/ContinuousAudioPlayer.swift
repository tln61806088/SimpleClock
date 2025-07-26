//
//  ContinuousAudioPlayer.swift
//  SimpleClock
//
//  持续播放微弱音频以维持后台音频会话
//  通过循环播放极小音量的滴答声来确保系统不会杀死后台进程
//

import AVFoundation
import UIKit
import os.log

class ContinuousAudioPlayer: NSObject {
    static let shared = ContinuousAudioPlayer()
    
    private let logger = Logger(subsystem: "SimpleClock", category: "ContinuousAudioPlayer")
    private var audioPlayer: AVAudioPlayer?
    private var isPlaying = false
    
    // 微弱但可识别的音量设置（让系统识别为音频播放）
    private let minimalVolume: Float = 0.1
    
    private override init() {
        super.init()
        logger.info("🔊 ContinuousAudioPlayer初始化")
        setupAudioPlayer()
    }
    
    /// 设置音频播放器
    private func setupAudioPlayer() {
        guard let audioData = generateSilentTickAudio() else {
            logger.error("无法生成静默滴答音频")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(data: audioData)
            audioPlayer?.delegate = self
            audioPlayer?.volume = minimalVolume
            audioPlayer?.numberOfLoops = -1  // 无限循环
            let prepared = audioPlayer?.prepareToPlay() ?? false
            
            logger.info("持续音频播放器初始化成功，prepareToPlay: \(prepared)")
        } catch {
            logger.error("创建音频播放器失败: \(error.localizedDescription)")
        }
    }
    
    /// 生成1秒的极微弱滴答声音频数据
    private func generateSilentTickAudio() -> Data? {
        let sampleRate: Double = 44100
        let duration: Double = 1.0  // 1秒
        let frameCount = Int(sampleRate * duration)
        
        // 创建极微弱的滴答声（只在开始有一个很小的脉冲）
        var audioData = Data()
        
        // WAV文件头
        let header = createWAVHeader(sampleRate: Int(sampleRate), frameCount: frameCount)
        audioData.append(header)
        
        // 音频数据：前0.01秒有极微弱的脉冲，其余时间静默
        for i in 0..<frameCount {
            var sample: Int16
            if i < Int(sampleRate * 0.01) {  // 前0.01秒
                let amplitude: Double = 0.001  // 极微弱振幅
                let frequency: Double = 1000   // 1kHz
                let time = Double(i) / sampleRate
                sample = Int16(amplitude * sin(2.0 * Double.pi * frequency * time) * Double(Int16.max))
            } else {
                sample = 0  // 静默
            }
            
            // 立体声（左右声道相同）
            audioData.append(Data(bytes: &sample, count: 2))
            audioData.append(Data(bytes: &sample, count: 2))
        }
        
        logger.info("音频生成完成，大小: \(audioData.count) 字节")
        return audioData
    }
    
    /// 创建WAV文件头
    private func createWAVHeader(sampleRate: Int, frameCount: Int) -> Data {
        var header = Data()
        
        // RIFF header
        header.append("RIFF".data(using: .ascii)!)
        var fileSize = UInt32(36 + frameCount * 4)  // 4 bytes per frame (16-bit stereo)
        header.append(Data(bytes: &fileSize, count: 4))
        header.append("WAVE".data(using: .ascii)!)
        
        // fmt chunk
        header.append("fmt ".data(using: .ascii)!)
        var chunkSize = UInt32(16)
        header.append(Data(bytes: &chunkSize, count: 4))
        var audioFormat = UInt16(1)  // PCM
        header.append(Data(bytes: &audioFormat, count: 2))
        var numChannels = UInt16(2)  // Stereo
        header.append(Data(bytes: &numChannels, count: 2))
        var sampleRateData = UInt32(sampleRate)
        header.append(Data(bytes: &sampleRateData, count: 4))
        var byteRate = UInt32(sampleRate * 4)  // sampleRate * numChannels * bitsPerSample/8
        header.append(Data(bytes: &byteRate, count: 4))
        var blockAlign = UInt16(4)  // numChannels * bitsPerSample/8
        header.append(Data(bytes: &blockAlign, count: 2))
        var bitsPerSample = UInt16(16)
        header.append(Data(bytes: &bitsPerSample, count: 2))
        
        // data chunk
        header.append("data".data(using: .ascii)!)
        var dataSize = UInt32(frameCount * 4)
        header.append(Data(bytes: &dataSize, count: 4))
        
        return header
    }
    
    /// 开始持续播放
    func startContinuousPlayback() {
        logger.info("🔄 开始持续音频播放")
        
        guard let player = audioPlayer else {
            logger.error("音频播放器未初始化，重新初始化")
            setupAudioPlayer()
            guard let _ = audioPlayer else {
                logger.error("重新初始化音频播放器失败")
                return
            }
            logger.info("重新初始化音频播放器成功")
            return startContinuousPlayback() // 递归调用
        }
        
        if isPlaying {
            logger.info("持续音频已在播放中")
            return
        }
        
        // 确保音频会话配置正确
        AudioSessionManager.shared.activateAudioSession()
        
        let success = player.play()
        isPlaying = success
        
        if success {
            logger.info("✅ 开始持续播放微弱音频以维持后台会话，音量: \(player.volume)")
            
            // 延迟检查播放状态
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                if let self = self, let player = self.audioPlayer {
                    self.logger.info("播放状态检查 - isPlaying: \(self.isPlaying), player.isPlaying: \(player.isPlaying), currentTime: \(player.currentTime)")
                }
            }
        } else {
            logger.error("❌ 无法开始持续音频播放")
        }
    }
    
    /// 停止持续播放
    func stopContinuousPlayback() {
        guard let player = audioPlayer else {
            logger.info("音频播放器未初始化")
            return
        }
        
        if !isPlaying {
            logger.info("持续音频并未在播放")
            return
        }
        
        player.stop()
        isPlaying = false
        logger.info("🛑 停止持续播放微弱音频")
    }
    
    /// 调整音量（保持微弱但可被系统识别）
    func setVolume(_ volume: Float) {
        // 使用设定的微弱音量，不再进一步降低
        audioPlayer?.volume = minimalVolume
        logger.info("调整持续音频音量至: \(self.minimalVolume)")
    }
    
    /// 检查是否正在播放
    var isContinuouslyPlaying: Bool {
        let actuallyPlaying = self.isPlaying && (self.audioPlayer?.isPlaying ?? false)
        logger.info("播放状态检查 - 标记状态: \(self.isPlaying), 实际播放: \(self.audioPlayer?.isPlaying ?? false)")
        return actuallyPlaying
    }
    
    /// 强制重启播放（用于异常恢复）
    func forceRestartPlayback() {
        logger.info("强制重启持续音频播放")
        stopContinuousPlayback()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.startContinuousPlayback()
        }
    }
}

// MARK: - AVAudioPlayerDelegate
extension ContinuousAudioPlayer: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            logger.info("持续音频循环完成")
        } else {
            logger.warning("持续音频播放异常结束")
            isPlaying = false
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        logger.error("持续音频解码错误: \(error?.localizedDescription ?? "未知错误")")
        isPlaying = false
    }
    
    func audioPlayerBeginInterruption(_ player: AVAudioPlayer) {
        logger.info("持续音频被中断")
    }
    
    func audioPlayerEndInterruption(_ player: AVAudioPlayer, withOptions flags: Int) {
        logger.info("持续音频中断结束，恢复播放")
        if isPlaying && !player.isPlaying {
            player.play()
        }
    }
}