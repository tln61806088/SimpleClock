import Foundation
import AVFoundation
import UIKit

/// 背景音乐管理器 - 为计时器提供舒缓的钢琴背景音乐
class BackgroundMusicManager: NSObject {
    
    /// 单例实例
    static let shared = BackgroundMusicManager()
    
    private var audioPlayer: AVAudioPlayer?
    private var currentTrackIndex = 0
    private var isPlaying = false
    private var volume: Float = 0.3 // 默认音量较低，不干扰语音播报
    
    /// 世界著名古典音乐列表（钢琴版本）
    /// 注意：您需要使用无版权的公共领域录音版本
    private let pianoTracks = [
        "canon_in_d_pachelbel",           // 1. 卡农 - 帕赫贝尔 (必须有)
        "fur_elise_beethoven",            // 2. 致爱丽丝 - 贝多芬
        "moonlight_sonata_beethoven",     // 3. 月光奏鸣曲 - 贝多芬
        "claire_de_lune_debussy",         // 4. 月光 - 德彪西
        "gymnopedia_no1_satie",           // 5. 金诺佩第一号 - 萨蒂
        "nocturne_op9_no2_chopin",        // 6. 夜曲作品9第2号 - 肖邦
        "minute_waltz_chopin",            // 7. 小狗圆舞曲 - 肖邦
        "turkish_march_mozart",           // 8. 土耳其进行曲 - 莫扎特
        "ave_maria_schubert",             // 9. 圣母颂 - 舒伯特
        "spring_vivaldi",                 // 10. 春 - 维瓦尔第（钢琴版）
        "swan_lake_tchaikovsky",          // 11. 天鹅湖 - 柴可夫斯基
        "prelude_in_c_major_bach",        // 12. C大调前奏曲 - 巴赫
        "air_on_g_string_bach",           // 13. G弦上的咏叹调 - 巴赫
        "eine_kleine_nachtmusik_mozart",  // 14. 小夜曲 - 莫扎特
        "liebestraum_no3_liszt",          // 15. 爱之梦第3号 - 李斯特
        "barcarolle_offenbach",           // 16. 船歌 - 奥芬巴赫
        "canon_and_gigue_pachelbel",      // 17. 卡农与吉格 - 帕赫贝尔
        "meditation_massenet",            // 18. 沉思曲 - 马斯奈
        "reverie_debussy",                // 19. 梦幻曲 - 德彪西
        "arabesque_no1_debussy"           // 20. 阿拉贝斯克第1号 - 德彪西
    ]
    
    private override init() {
        super.init()
        setupAudioSession()
    }
    
    /// 配置音频会话（与语音播报共存）
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // 使用环境音频类别，允许与其他音频混合
            try audioSession.setCategory(.ambient, options: [.mixWithOthers])
            try audioSession.setMode(.default)
            
            print("背景音乐 - 音频会话配置成功")
            
        } catch {
            print("背景音乐 - 音频会话配置失败: \(error.localizedDescription)")
        }
    }
    
    /// 开始播放背景音乐
    /// - Parameter randomStart: 是否随机选择起始曲目
    func startPlaying(randomStart: Bool = true) {
        guard !isPlaying else { return }
        
        if randomStart {
            currentTrackIndex = Int.random(in: 0..<pianoTracks.count)
        }
        
        playCurrentTrack()
    }
    
    /// 停止播放背景音乐
    func stopPlaying() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        print("背景音乐已停止")
    }
    
    /// 暂停播放
    func pausePlaying() {
        audioPlayer?.pause()
        isPlaying = false
        print("背景音乐已暂停")
    }
    
    /// 恢复播放
    func resumePlaying() {
        audioPlayer?.play()
        isPlaying = true
        print("背景音乐已恢复")
    }
    
    /// 播放当前曲目
    private func playCurrentTrack() {
        let trackName = pianoTracks[currentTrackIndex]
        
        guard let url = Bundle.main.url(forResource: trackName, withExtension: "mp3") else {
            print("找不到音频文件: \(trackName).mp3")
            // 尝试下一首
            playNextTrack()
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.volume = volume
            audioPlayer?.numberOfLoops = 0 // 单曲播放，结束后自动切换下一首
            
            let success = audioPlayer?.play() ?? false
            if success {
                isPlaying = true
                print("开始播放: \(trackName)")
            } else {
                print("播放失败: \(trackName)")
                playNextTrack()
            }
            
        } catch {
            print("创建音频播放器失败: \(error.localizedDescription)")
            playNextTrack()
        }
    }
    
    /// 播放下一首
    private func playNextTrack() {
        currentTrackIndex = (currentTrackIndex + 1) % pianoTracks.count
        playCurrentTrack()
    }
    
    /// 播放上一首
    private func playPreviousTrack() {
        currentTrackIndex = (currentTrackIndex - 1 + pianoTracks.count) % pianoTracks.count
        playCurrentTrack()
    }
    
    /// 设置音量
    /// - Parameter volume: 音量值 (0.0 - 1.0)
    func setVolume(_ volume: Float) {
        self.volume = max(0.0, min(1.0, volume))
        audioPlayer?.volume = self.volume
        print("背景音乐音量设置为: \(self.volume)")
    }
    
    /// 获取当前播放状态
    var playingStatus: (isPlaying: Bool, currentTrack: String) {
        let trackName = pianoTracks[currentTrackIndex]
        return (isPlaying, trackName)
    }
    
    /// 跳转到指定曲目
    /// - Parameter index: 曲目索引
    func playTrack(at index: Int) {
        guard index >= 0 && index < pianoTracks.count else { return }
        
        audioPlayer?.stop()
        currentTrackIndex = index
        playCurrentTrack()
    }
    
    /// 获取所有曲目名称（用于UI显示）
    func getAllTrackNames() -> [String] {
        return pianoTracks.map { trackName in
            // 将文件名转换为友好的显示名称
            return trackName
                .replacingOccurrences(of: "piano_", with: "")
                .replacingOccurrences(of: "_", with: " ")
                .capitalized
        }
    }
}

// MARK: - AVAudioPlayerDelegate
extension BackgroundMusicManager: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            print("曲目播放完成，切换下一首")
            playNextTrack()
        } else {
            print("曲目播放异常结束")
            isPlaying = false
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("音频解码错误: \(error?.localizedDescription ?? "未知错误")")
        playNextTrack()
    }
}