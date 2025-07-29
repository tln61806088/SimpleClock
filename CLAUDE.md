# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概览

SimpleClock是一个专为视力障碍用户设计的无障碍计时器应用，支持iOS 15.6及以上版本。核心功能包括电子手表风格时钟显示、语音识别控制、震动反馈和语音播报。

## 核心功能模块

### 1. 电子手表风格时钟（DigitalClockView）
- 24小时制数字显示，由小方块拼成数字
- 冒号每秒闪烁
- 已实现基础功能，包含VoiceOver无障碍支持

### 2. 计时设置区（TimerPickerView）
- 左侧：计时时长（1~180分钟，默认90分钟）
- 右侧：提醒间隔（1、5、10、15、30、60、90分钟）
- 滚动5分钟时震动反馈，停止1秒后播报当前设置

### 3. 操作按钮区（MainControlButtonsView）
- 第一行：时间播报、开始计时/暂停计时
- 第二行：剩余时间、结束计时
- 第三行：语音识别按钮（大圆形）
- 所有按钮均有语音反馈

### 4. 语音识别功能（VoiceRecognitionButton）
- 按住时：轻微震动，显示"正在录音"动画
- 松开时：轻微震动，开始语音识别
- 支持语音指令归一化处理

### 5. 计时与提醒逻辑（TimerViewModel）
- 自定义间隔提醒
- 最后2分钟每分钟提醒
- 本地通知支持

## 项目架构

```
SimpleClock/
├── Views/
│   ├── DigitalClockView.swift         // 电子手表风格时钟（已实现）
│   ├── TimerPickerView.swift          // 计时/间隔选择器
│   ├── MainControlButtonsView.swift   // 操作按钮区
│   ├── VoiceRecognitionButton.swift   // 语音识别按钮
│   └── HomeView.swift                 // 主界面组合
├── ViewModels/
│   └── TimerViewModel.swift           // 计时与提醒逻辑
├── Models/
│   └── TimerSettings.swift            // 计时设置数据结构
├── Utils/
│   ├── SpeechHelper.swift             // 语音播报工具
│   ├── HapticHelper.swift             // 震动工具
│   └── SpeechRecognitionHelper.swift  // 语音识别+归一化
└── SimpleClockApp.swift               // 应用入口，本地通知授权
```

## 开发顺序建议

1. 电子手表风格时钟（DigitalClockView）- ✅ 已实现
2. 计时选择器（TimerPickerView）- 实现震动和语音播报
3. 操作按钮区（MainControlButtonsView）- 所有按钮语音反馈
4. 语音识别按钮（VoiceRecognitionButton）- 录音动画、震动、识别
5. 计时与提醒逻辑（TimerViewModel）- 自定义间隔和提醒
6. 语音播报与震动工具（SpeechHelper、HapticHelper）
7. 语音识别与归一化（SpeechRecognitionHelper）
8. 主界面组合（HomeView）- 替换当前的ContentView
9. 无障碍优化与本地通知

## 语音识别归一化规则

### 指令归一化
- "暂停"、"计时暂停"、"暂停计时" → 暂停操作
- "开始"、"计时开始"、"开始计时" → 开始操作
- "恢复"、"恢复计时" → 恢复操作
- "结束"、"结束计时" → 结束操作
- "时间播报"、"播报时间" → 时间播报
- "剩余时间"、"播报剩余时间" → 剩余时间播报

### 数字归一化
- 中文数字（"五十"、"三十五"）→ 阿拉伯数字（50、35）
- 支持"计时xx分钟/xx小时"、"间隔xx分钟/xx小时/xx秒"

## 技术要求

### iOS版本兼容性
- 支持iOS 15.6 - iOS 18.5完整版本范围
- 最低部署目标：iOS 15.6
- 在高版本使用新特性，在低版本时自动降级兼容
- 使用@available检查确保API兼容性

### 无障碍功能
- 全面的VoiceOver支持
- 语音播报使用AVSpeechSynthesizer
- 震动反馈使用UIImpactFeedbackGenerator（轻微震动）
- 所有UI元素正确设置accessibilityLabel和accessibilityHint

### 权限管理
- 语音识别权限（Speech Recognition）- 在首次使用时动态请求，提供详细错误提示
- 麦克风权限（Microphone）- 随语音识别一起处理
- 本地通知权限（User Notifications）- 应用启动后延迟请求
- iOS版本适配：iOS 16+支持provisional通知，iOS 15.6使用基础版本
- 优雅的权限错误处理和用户引导

## 常用开发命令

```bash
# 构建项目
xcodebuild -project SimpleClock.xcodeproj -scheme SimpleClock -configuration Debug

# 在模拟器中运行
open -a Simulator
xcrun simctl boot [DEVICE_ID]
xcodebuild -project SimpleClock.xcodeproj -scheme SimpleClock -destination 'platform=iOS Simulator,name=iPhone 13,OS=15.6' build

# 清理构建缓存
xcodebuild clean -project SimpleClock.xcodeproj -scheme SimpleClock
```

## 重要注意事项

1. **严格按需求实现**：专注当前任务，不做无关修改或优化
2. **兼容性**：确保所有代码在iOS 15.6上正常运行
3. **无障碍优先**：每个组件都必须考虑视力障碍用户的使用需求
4. **语音反馈**：所有交互都应提供语音或震动反馈
5. **Swift最佳实践**：遵循Swift官方文档和最佳实践
6. **测试验证**：新功能实现后需要在iOS 15.6设备/模拟器上测试

## 当前状态 (2025-01-27)

### 已完成功能 ✅
- **项目基础结构**：完整的SwiftUI架构，支持iOS 15.6-18.5
- **DigitalClockView**：重新设计为简洁的数字时钟显示，支持倒计时切换
- **TimerPickerView**：计时时长(1-180分钟)和提醒间隔(0,1,5,10,15,30,60,90分钟)选择
- **MainControlButtonsView**：4个主控制按钮，自适应宽度布局
- **VoiceRecognitionButton**：长方形语音识别按钮，支持按住说话
- **TimerViewModel**：完整的计时逻辑，包括开始/暂停/结束/设置更新
- **语音播报功能**：完整的TTS系统，支持时间播报、剩余时间、设置播报
- **语音识别功能**：支持中文语音指令识别和归一化处理
- **震动反馈**：所有交互都有相应的触觉反馈
- **无障碍支持**：完整的VoiceOver支持，针对视障用户优化
- **权限管理**：语音识别、麦克风、通知权限的动态请求和错误处理

### 核心特性
- **时钟显示**：正常情况显示当前时间，开始计时后切换为倒计时显示
- **统一灰色设计**：所有按钮使用灰色，尊重视障用户不依赖颜色的需求
- **响应式布局**：16px统一左右边距，按钮自适应屏幕宽度
- **精确时间播报**：使用向上取整逻辑，确保播报时间的一致性
- **智能提醒系统**：支持0分钟(不提醒)到90分钟的自定义间隔
- **计时状态管理**：未开始/运行中/暂停/结束的完整状态流转

### 已修复的问题
- 隐私权限崩溃问题（通过INFOPLIST_KEY配置解决）
- 时间播报少1分钟问题（向上取整逻辑修复）
- 数字间距重叠问题（响应式布局优化）
- 语音识别交互问题（按住录音，松手识别）
- 计时结束后显示问题（正确重置状态）
- **后台音频播放问题（2025-01-27修复）**：之前的播放器都无法在后台播放

### 技术实现亮点
- iOS版本兼容性处理：@available检查确保15.6-18.5全版本支持
- 响应式字体和布局：GeometryReader动态适应屏幕尺寸
- 中文语音识别归一化：支持自然语言指令转换
- 内存管理优化：正确的Timer和观察者生命周期管理
- 无障碍体验设计：每个UI元素都有完整的accessibility标签

## 后台音频播放成功经验 (2025-01-27)

### 问题描述
之前实现的所有音频播放器都无法在后台工作，应用切换到后台或锁屏后立即停止播放，导致TTS语音播报失效。

### 根本原因
1. **Info.plist配置错误**：UIBackgroundModes配置为字符串格式而非数组格式
2. **缺少启动时激活**：应用启动后没有立即开始持续音频播放
3. **音频会话配置虽正确但未生效**：由于Info.plist问题导致整个后台播放功能失效

### 成功修复方案

#### 1. 修复Info.plist配置（关键）
```diff
- INFOPLIST_KEY_UIBackgroundModes = "audio background-processing";
+ INFOPLIST_KEY_UIBackgroundModes = (
+     audio,
+     "background-processing",
+ );
```

#### 2. 应用启动时立即激活后台音频
在`SimpleClockApp.swift`中添加：
```swift
private func requestAllPermissions() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        // 启动持续音频播放以维持后台会话
        ContinuousAudioPlayer.shared.startContinuousPlayback()
    }
}
```

#### 3. 确保音频会话正确配置
```swift
// AudioSessionManager.swift - 已正确配置
try audioSession.setCategory(
    .playback,  // 播放类别，支持后台播放
    mode: .spokenAudio,  // 语音音频模式，为TTS优化
    options: [
        .duckOthers,
        .interruptSpokenAudioAndMixWithOthers
    ]
)
```

### iOS后台音频播放的完整要求
1. **Info.plist配置**：UIBackgroundModes必须包含"audio"（数组格式）
2. **AVAudioSession配置**：类别设为.playback，模式设为.spokenAudio
3. **实际音频播放**：必须有真实的音频文件在播放（不能是生成的假音频）
4. **启动时激活**：应用启动后立即开始播放以维持音频会话

### 测试验证
- 应用启动后能听到piano_01.mp3的持续播放
- 切换到后台或锁屏后音频继续播放
- TTS语音播报在后台正常工作
- 用户确认："可以了 我听到了"

### 重要教训
- iOS的UIBackgroundModes配置格式非常严格，字符串格式无效
- 必须有实际的音频播放才能维持后台音频会话
- 所有配置正确但Info.plist错误会导致整个功能失效

## 音乐播放生命周期优化 (2025-01-27)

### 新的需求
用户反馈希望音乐播放与计时器生命周期同步：
- 应用启动时不自动播放音乐
- 只有在开始计时时才播放音乐
- 计时结束时停止音乐播放
- 同时实现完整的锁屏媒体控制

### 成功实现方案

#### 1. 应用启动逻辑优化
```swift
// SimpleClockApp.swift - 移除自动音乐播放
private func requestAllPermissions() {
    // 立即激活音频会话（遵循iOS最佳实践）
    AudioSessionManager.shared.activateAudioSession()
    
    // 注意：不再自动启动音乐播放
    // 音乐播放将在计时器启动时开始
}
```

#### 2. 计时器同步音乐播放
```swift
// TimerViewModel.swift - 关键修改点
func startTimer() {
    // 开始计时时启动音乐播放以维持后台音频会话
    logger.info("🔄 计时开始，启动音乐播放")
    continuousAudioPlayer.startContinuousPlayback()  // 第189-191行
    
    // 更新锁屏媒体信息为计时状态
    updateNowPlayingInfo()
}

func pauseTimer() {
    // 计时暂停时，音乐继续播放以维持后台会话
    // 不停止音乐播放，这样锁屏控制依然可用
}

func stopTimer() {
    // 计时结束时停止音乐播放
    continuousAudioPlayer.stopContinuousPlayback()  // 第234-235行
    
    // 清除锁屏媒体信息
    nowPlayingManager.clearNowPlayingInfo()
}
```

#### 3. 音频会话配置优化
```swift
// AudioSessionManager.swift - 支持锁屏控制
try audioSession.setCategory(
    .playback,  // 播放类别，支持后台播放
    mode: .default,  // 使用默认模式，比spokenAudio更适合音乐播放
    options: [
        .duckOthers  // 只降低其他应用音量，不混音
        // 重要：移除.mixWithOthers选项，因为它会导致MPNowPlayingInfoCenter被忽略！
    ]
)
```

#### 4. 锁屏媒体控制集成
```swift
// ContinuousAudioPlayer.swift - 新增锁屏控制
private func setupRemoteCommands() {
    let commandCenter = MPRemoteCommandCenter.shared()
    
    // 启用播放/暂停控制
    commandCenter.playCommand.isEnabled = true
    commandCenter.pauseCommand.isEnabled = true
    commandCenter.togglePlayPauseCommand.isEnabled = true
    commandCenter.nextTrackCommand.isEnabled = true
    commandCenter.previousTrackCommand.isEnabled = true
    
    // 通过NotificationCenter与TimerViewModel通信
    commandCenter.playCommand.addTarget { [weak self] event in
        NotificationCenter.default.post(name: .lockScreenPlayCommand, object: nil)
        return .success
    }
}

// TimerViewModel.swift - 锁屏媒体信息更新
private func updateNowPlayingInfo() {
    if startTime != nil {  // 只有在计时运行或暂停时才显示
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = "SimpleClock计时器"
        nowPlayingInfo[MPMediaItemPropertyArtist] = String(format: "剩余: %02d:%02d", minutes, seconds)
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    // 注意：没有计时任务时，不设置任何锁屏信息
}
```

### 测试验证结果

#### ✅ 模拟器测试 (iPhone 16)
- ✅ 应用启动不自动播放音乐，显示正常时钟
- ✅ 点击"开始计时"成功启动倒计时和音乐播放
- ✅ 后台切换和锁屏状态音频继续播放
- ✅ 锁屏控制正常显示和工作
- ✅ 用户确认："后台播放正常"

#### ⚠️ 真机测试问题 (iPhone 15 Pro)
- ❌ 应用退出前台后立即停止播放
- ❌ Console显示"有音频输出"但无声音
- ❌ 音频文件正常加载，持续时间276.234秒
- ❌ 播放器状态显示正常但实际无声音

### 技术要点总结
1. **音频会话模式**：锁屏控制需要`.default`模式，不能使用`.mixWithOthers`
2. **生命周期同步**：音乐播放完全与计时器状态同步
3. **锁屏控制**：通过MPNowPlayingInfoCenter和MPRemoteCommandCenter实现
4. **后台维持**：暂停时保持音乐播放以维持后台会话
5. **真机差异**：模拟器和真机的后台音频行为存在差异，需进一步调试

## 锁屏音乐控制组件实现 (2025-01-27)

### 问题现象
用户反馈：音乐正常播放，但锁屏界面没有显示音乐播放控制组件（播放/暂停按钮等）。

### 根本原因
**遗漏了关键的Xcode项目配置**：在Target → Signing & Capabilities中没有添加Background Modes capability。

### 完整解决方案

#### 1. Xcode项目配置（关键！）
**Target → Signing & Capabilities → + Capability → Background Modes**
- ✅ 勾选 "Audio, AirPlay, and Picture in Picture"
- ❌ 不需要勾选 "Remote notifications"（SimpleClock只使用本地通知）

#### 2. MPNowPlayingInfoCenter正确配置
```swift
// 第一步：设置播放状态（关键）
MPNowPlayingInfoCenter.default().playbackState = .playing

// 第二步：设置详细媒体信息
var nowPlayingInfo = [String: Any]()
nowPlayingInfo[MPMediaItemPropertyTitle] = "SimpleClock 计时器"
nowPlayingInfo[MPMediaItemPropertyArtist] = "正在计时"
nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0 // 必须为1.0
nowPlayingInfo[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue

// 第三步：设置到系统
MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
```

#### 3. MPRemoteCommandCenter配置
```swift
let commandCenter = MPRemoteCommandCenter.shared()
commandCenter.playCommand.isEnabled = true
commandCenter.pauseCommand.isEnabled = true
commandCenter.togglePlayPauseCommand.isEnabled = true

commandCenter.playCommand.addTarget { event in
    // 处理播放命令 - 开始/恢复计时
    return .success
}
```

#### 4. 音频播放时机控制
```swift
// 等待音频真正开始播放后设置锁屏信息
DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
    if player.isPlaying {
        self.updateInitialNowPlayingInfo()
    }
}
```

### 技术要点

1. **Background Modes capability是必须的**：没有这个配置，系统不会识别应用为音频播放应用
2. **playbackState必须设为.playing**：这是激活锁屏控件的关键
3. **playbackRate必须为1.0**：0.0会导致锁屏组件不显示
4. **必须等音频真正开始播放**：过早设置锁屏信息会失败

### 成功验证
- 启动计时器后锁屏能看到"SimpleClock 计时器"的音乐控制组件
- 锁屏播放/暂停按钮可以控制计时器
- 显示计时器图标和进度信息
- 用户确认："现在一切正常了"

### 重要教训
**Xcode的Target配置和代码配置必须同时正确**，仅有代码配置而没有项目capability配置是不够的。

## 临时发布版本优化 (2025-01-29)

### 用户体验优化

#### 1. 语音播报统一优化
- **统一术语**：所有播报内容从"剩余时间"改为"剩余时长"
- **开始计时播报**：修改为"开始计时，剩余时长X小时X分钟"（连贯播报）
- **剩余时长按钮**：
  - 有计时任务 → "剩余时长X小时X分钟"
  - 无计时任务 → "当前无计时任务"
- **语音识别支持**：支持"剩余时长"、"剩余"、"剩余时间"等多种指令

#### 2. 计时器状态管理优化
- **结束计时行为**：点击"结束计时"后清空计时任务，显示时钟而不是滚轮设置
- **状态一致性**：确保按钮播报与语音识别播报完全一致

#### 3. 主题选择临时隐藏
为了专注核心功能和简化用户体验：
- **隐藏组件**：临时隐藏主题颜色选择按钮和面板
- **免费策略**：当前版本提供完整功能 + 基础黑色主题
- **后续规划**：用户量增长后再推出主题包内购

### 发布分支管理
- **主分支**：`ui-beautification` (功能开发)
- **发布分支**：`release/temp-v1.0` (临时发布版本)
- **发布准备**：隐藏内购功能，专注核心计时体验

### 技术改进记录

#### 语音播报优化
```swift
// MainControlButtonsView.swift - 开始计时连贯播报
var message = "开始计时，剩余时长"
if hours > 0 {
    message += "\(hours)小时"
}
if minutes > 0 || hours == 0 {
    message += "\(minutes)分钟"
}
SpeechHelper.shared.speak(message)
```

#### 状态管理优化
```swift
// TimerViewModel.swift - 结束计时清空状态
func stopTimer() {
    // 结束计时后，清空计时任务，显示时钟
    remainingSeconds = 0
    // ... 其他清理逻辑
}
```

#### 主题选择隐藏
```swift
// HomeView.swift - 临时隐藏主题选择
// 临时隐藏主题选择按钮 - 免费版本暂时只提供基础黑色主题
// ColorThemeToggleButton()
//     .environmentObject(colorThemeState)
```

### 当前功能状态
✅ 完整计时功能（计时、暂停、结束）
✅ 语音识别控制（两阶段解析优化）
✅ TTS语音播报（统一为"剩余时长"）
✅ 后台音频播放和锁屏控制
✅ 本地通知和定时提醒
✅ 用户设置持久化
✅ 完整的无障碍支持
✅ 震动反馈和触觉体验
⏸️ 主题选择功能（临时隐藏）
⏳ 内购功能（待后续完善）

### 发布策略
1. **免费增值模式**：完整功能免费使用
2. **用户积累阶段**：专注核心体验，建立用户基础
3. **后续变现**：用户量增长后推出主题包等付费功能

## Swift版本和依赖

- Swift 5.7+（兼容iOS 15.6）
- SwiftUI 3.0（iOS 15兼容版本）
- AVFoundation（语音播报和识别）
- UserNotifications（本地通知）
- MediaPlayer（锁屏音乐控制）
- SwiftData（可选，用于设置持久化）