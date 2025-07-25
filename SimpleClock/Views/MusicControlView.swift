import SwiftUI

/// 背景音乐控制视图
struct MusicControlView: View {
    @State private var isPlaying = false
    @State private var currentTrack = ""
    @State private var volume: Float = 0.3
    @State private var showTrackList = false
    
    private let musicManager = BackgroundMusicManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            // 音乐控制标题
            HStack {
                Image(systemName: "music.note")
                    .foregroundColor(.gray)
                Text("背景音乐")
                    .font(.headline)
                    .foregroundColor(.gray)
                Spacer()
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("背景音乐控制")
            
            // 当前播放信息
            if isPlaying && !currentTrack.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("正在播放")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formatTrackName(currentTrack))
                        .font(.body)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("正在播放：\(formatTrackName(currentTrack))")
            }
            
            // 播放控制按钮
            HStack(spacing: 20) {
                // 播放/暂停按钮
                Button(action: togglePlayback) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.gray)
                }
                .accessibilityLabel(isPlaying ? "暂停音乐" : "播放音乐")
                .onTapGesture {
                    HapticHelper.shared.lightImpact()
                }
                
                // 曲目列表按钮
                Button(action: { showTrackList.toggle() }) {
                    Image(systemName: "list.bullet.circle")
                        .font(.system(size: 36))
                        .foregroundColor(.gray)
                }
                .accessibilityLabel("选择曲目")
                .onTapGesture {
                    HapticHelper.shared.lightImpact()
                }
            }
            
            // 音量控制
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "speaker.fill")
                        .foregroundColor(.gray)
                    Text("音量")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(volume * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Slider(value: $volume, in: 0...1, step: 0.1) { _ in
                    musicManager.setVolume(volume)
                }
                .accentColor(.gray)
                .accessibilityLabel("音量控制")
                .accessibilityValue("\(Int(volume * 100))%")
            }
        }
        .padding(.horizontal, 16)
        .onAppear {
            updatePlaybackStatus()
        }
        .sheet(isPresented: $showTrackList) {
            TrackListView()
        }
    }
    
    /// 切换播放状态
    private func togglePlayback() {
        if isPlaying {
            musicManager.pausePlaying()
        } else {
            musicManager.startPlaying()
        }
        updatePlaybackStatus()
    }
    
    /// 更新播放状态
    private func updatePlaybackStatus() {
        let status = musicManager.playingStatus
        isPlaying = status.isPlaying
        currentTrack = status.currentTrack
    }
    
    /// 格式化曲目名称为中文显示
    private func formatTrackName(_ trackName: String) -> String {
        let trackMap: [String: String] = [
            "canon_in_d_pachelbel": "卡农 - 帕赫贝尔",
            "fur_elise_beethoven": "致爱丽丝 - 贝多芬",
            "moonlight_sonata_beethoven": "月光奏鸣曲 - 贝多芬",
            "claire_de_lune_debussy": "月光 - 德彪西",
            "gymnopedia_no1_satie": "金诺佩第一号 - 萨蒂",
            "nocturne_op9_no2_chopin": "夜曲作品9第2号 - 肖邦",
            "minute_waltz_chopin": "小狗圆舞曲 - 肖邦",
            "turkish_march_mozart": "土耳其进行曲 - 莫扎特",
            "ave_maria_schubert": "圣母颂 - 舒伯特",
            "spring_vivaldi": "春 - 维瓦尔第",
            "swan_lake_tchaikovsky": "天鹅湖 - 柴可夫斯基",
            "prelude_in_c_major_bach": "C大调前奏曲 - 巴赫",
            "air_on_g_string_bach": "G弦上的咏叹调 - 巴赫",
            "eine_kleine_nachtmusik_mozart": "小夜曲 - 莫扎特",
            "liebestraum_no3_liszt": "爱之梦第3号 - 李斯特",
            "barcarolle_offenbach": "船歌 - 奥芬巴赫",
            "canon_and_gigue_pachelbel": "卡农与吉格 - 帕赫贝尔",
            "meditation_massenet": "沉思曲 - 马斯奈",
            "reverie_debussy": "梦幻曲 - 德彪西",
            "arabesque_no1_debussy": "阿拉贝斯克第1号 - 德彪西"
        ]
        
        return trackMap[trackName] ?? trackName
    }
}

/// 曲目列表视图
struct TrackListView: View {
    @Environment(\.dismiss) private var dismiss
    private let musicManager = BackgroundMusicManager.shared
    
    var body: some View {
        NavigationView {
            List {
                ForEach(Array(musicManager.getAllTrackNames().enumerated()), id: \.offset) { index, trackName in
                    Button(action: {
                        musicManager.playTrack(at: index)
                        HapticHelper.shared.lightImpact()
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(formatTrackName(trackName))
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)
                                
                                Text("第 \(index + 1) 首")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "play.circle")
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 4)
                    }
                    .accessibilityLabel("播放 \(formatTrackName(trackName))")
                }
            }
            .navigationTitle("选择曲目")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                }
            }
        }
    }
    
    /// 格式化曲目名称（复用主视图的方法）
    private func formatTrackName(_ trackName: String) -> String {
        let trackMap: [String: String] = [
            "canon_in_d_pachelbel": "卡农 - 帕赫贝尔",
            "fur_elise_beethoven": "致爱丽丝 - 贝多芬",
            "moonlight_sonata_beethoven": "月光奏鸣曲 - 贝多芬",
            "claire_de_lune_debussy": "月光 - 德彪西",
            "gymnopedia_no1_satie": "金诺佩第一号 - 萨蒂",
            "nocturne_op9_no2_chopin": "夜曲作品9第2号 - 肖邦",
            "minute_waltz_chopin": "小狗圆舞曲 - 肖邦",
            "turkish_march_mozart": "土耳其进行曲 - 莫扎特",
            "ave_maria_schubert": "圣母颂 - 舒伯特",
            "spring_vivaldi": "春 - 维瓦尔第",
            "swan_lake_tchaikovsky": "天鹅湖 - 柴可夫斯基",
            "prelude_in_c_major_bach": "C大调前奏曲 - 巴赫",
            "air_on_g_string_bach": "G弦上的咏叹调 - 巴赫",
            "eine_kleine_nachtmusik_mozart": "小夜曲 - 莫扎特",
            "liebestraum_no3_liszt": "爱之梦第3号 - 李斯特",
            "barcarolle_offenbach": "船歌 - 奥芬巴赫",
            "canon_and_gigue_pachelbel": "卡农与吉格 - 帕赫贝尔",
            "meditation_massenet": "沉思曲 - 马斯奈",
            "reverie_debussy": "梦幻曲 - 德彪西",
            "arabesque_no1_debussy": "阿拉贝斯克第1号 - 德彪西"
        ]
        
        return trackMap[trackName] ?? trackName
    }
}

#Preview {
    MusicControlView()
}