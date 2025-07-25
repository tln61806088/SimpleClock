import AVFoundation

class BackgroundMusicPlayer: NSObject {
    static let shared = BackgroundMusicPlayer()
    private var audioPlayer: AVAudioPlayer?
    private var musicFiles: [String] = []
    private var currentIndex: Int = 0
    private var isPlaying: Bool = false
    private var isManuallyPaused: Bool = false
    private var userVolume: Float = 0.5 // 用户设置的音量，0.01~0.5，默认50%

    private let minVolume: Float = 0.0001 // 0.01%
    private let maxVolume: Float = 0.5    // 50%

    private override init() {
        super.init()
        // 20首无版权钢琴曲，卡农为 piano_01.mp3
        musicFiles = (1...20).map { String(format: "piano_%02d.mp3", $0) }
        shuffleMusic()
    }

    private func shuffleMusic() {
        musicFiles.shuffle()
        currentIndex = 0
    }

    private func playCurrentMusic() {
        guard !musicFiles.isEmpty else { return }
        let fileName = musicFiles[currentIndex]
        guard let url = Bundle.main.url(forResource: fileName, withExtension: nil) else {
            print("找不到音频文件: \(fileName)")
            nextMusic()
            return
        }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.numberOfLoops = 0
            audioPlayer?.volume = isManuallyPaused ? minVolume : userVolume
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlaying = true
        } catch {
            print("播放音频失败: \(error)")
            nextMusic()
        }
    }

    func play() {
        if isPlaying {
            // 如果之前是“伪暂停”，恢复音量
            if isManuallyPaused {
                setVolume(userVolume)
                isManuallyPaused = false
            }
            return
        }
        if audioPlayer == nil {
            playCurrentMusic()
        } else {
            audioPlayer?.play()
            setVolume(userVolume)
            isPlaying = true
            isManuallyPaused = false
        }
    }

    func pause() {
        // 不真正暂停，只是音量降到极低
        setVolume(minVolume)
        isManuallyPaused = true
    }

    func stop() {
        audioPlayer?.stop()
        isPlaying = false
        isManuallyPaused = false
        audioPlayer = nil
    }

    func setVolume(_ volume: Float) {
        let v = max(minVolume, min(maxVolume, volume))
        audioPlayer?.volume = v
        if !isManuallyPaused {
            userVolume = v
        }
    }

    func getUserVolume() -> Float {
        return userVolume
    }

    func nextMusic() {
        currentIndex = (currentIndex + 1) % musicFiles.count
        playCurrentMusic()
    }

    // duck 音量（如语音播报时）
    func duckVolume() {
        audioPlayer?.volume = minVolume * 10 // 0.1%
    }
    // 恢复到用户设置音量
    func restoreVolume() {
        if !isManuallyPaused {
            setVolume(userVolume)
        }
    }
}

extension BackgroundMusicPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // 自动播放下一首
        nextMusic()
    }
} 