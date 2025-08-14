# CLAUDE.md

**本次更新主要内容**：iPad横屏模式优化 - 实现按钮高度分级调整(第一二行1.25倍、第三行2倍)、添加设备方向感知机制、确保滚轮宽度与按钮宽度精确匹配，提升iPad横屏模式下的触控体验和界面一致性 (2025-08-14)

SimpleClock 项目文档 - 专为无障碍用户设计的语音计时器应用

## 项目概览

SimpleClock 是一个专为视力障碍用户设计的无障碍计时器应用，支持 iOS 15.6-18.5 全版本。通过语音识别、语音播报、震动反馈等多模态交互，为用户提供完整的计时体验。项目在2025年7月30日完成了重大性能优化，解决了耗电和发热问题。

## 项目架构

```
SimpleClock/
├── SimpleClockApp.swift              // 应用入口，权限管理和后台任务注册
├── Views/                            // 视图层
│   ├── HomeView.swift               // 主界面，集成所有组件，包含性能优化
│   ├── DigitalClockView.swift       // 数字时钟显示，智能缓存系统
│   ├── MainControlButtonsView.swift // 主控制按钮，事件驱动更新
│   ├── VoiceRecognitionButton.swift // 语音识别按钮，复杂指令解析
│   ├── TimerPickerView.swift        // 计时设置选择器，震动反馈
│   └── ColorThemePicker.swift       // 主题选择器（临时隐藏）
├── ViewModels/
│   └── TimerViewModel.swift         // 计时器核心逻辑，状态管理
├── Models/
│   └── TimerSettings.swift          // 计时设置数据结构
├── Utils/                           // 工具层
│   ├── AudioSessionManager.swift   // 音频会话统一管理
│   ├── ContinuousAudioPlayer.swift // 后台音频播放器
│   ├── SpeechHelper.swift          // 语音播报系统
│   ├── SpeechRecognitionHelper.swift // 语音识别和归一化
│   ├── SilentModeDetector.swift    // 静音检测（按需检测优化）
│   ├── HapticHelper.swift          // 震动反馈工具
│   ├── DesignSystem.swift          // 设计系统（31种主题）
│   ├── NowPlayingManager.swift     // 锁屏媒体控制
│   ├── LockScreenMediaHelper.swift // 锁屏媒体辅助
│   ├── PermissionManager.swift     // 权限管理工具
│   └── PurchaseManager.swift       // 内购管理（待完善）
└── Tests/                          // 测试文件
```

## 核心功能模块详解

### 1. 应用入口 (SimpleClockApp.swift)
**职责**: 应用启动、权限请求、后台任务注册
- 权限管理：通知、语音识别、麦克风、后台刷新
- 后台任务注册：音频播放、应用刷新
- 通知类别设置：支持自定义操作和图标
- 权限状态检查和用户引导

### 2. 主界面 (HomeView.swift)
**职责**: 整合所有功能组件，包含重要性能优化
- **性能优化**: 缓存渐变对象、阴影配置、TimerPicker状态
- **响应式布局**: GeometryReader适配不同屏幕尺寸
- **事件驱动**: 只在真正状态变化时更新UI
- **主题管理**: 集成ThemeManager单例

### 3. 数字时钟显示 (DigitalClockView.swift)
**职责**: 电子手表风格时钟，支持正常时间/倒计时切换
- **智能模式切换**: 正常状态显示当前时间，计时状态显示倒计时
- **分级重绘缓存**: 缓存 cachedHour/Minute/Second，只有变化时才重绘
- **性能优化**: updateCachedStringsSelectively() 避免不必要的字符串计算
- **无障碍支持**: 完整的VoiceOver时间播报

### 4. 主控制按钮区 (MainControlButtonsView.swift)
**职责**: 4个主控制按钮 + 语音识别按钮
- **按钮功能**: 时间播报、开始/暂停/恢复计时、剩余时长、结束计时
- **事件驱动优化**: 缓存按钮状态，只在isRunning/isPaused变化时更新
- **语音反馈**: 所有操作都提供详细语音播报
- **统一术语**: 所有播报使用"剩余时长"而非"剩余时间"
- **iPad分级高度**: 竖屏第三行1.5倍，横屏第一二行1.25倍、第三行2倍

### 5. 语音识别按钮 (VoiceRecognitionButton.swift)
**职责**: 复杂的中文语音指令识别和归一化处理
- **两阶段解析**: extractTimerDurationOnly() + extractIntervalOnly()
- **复杂指令支持**: "计时九十分钟，间隔十五分钟"
- **中文数字转换**: "一个半小时"→90分钟，"三点五小时"→210分钟
- **音频管理**: 录音时降低背景音乐，完成后恢复
- **指令分类**: 常用指令直接执行，复杂指令播报确认

### 6. 计时设置选择器 (TimerPickerView.swift)
**职责**: 计时时长和提醒间隔双滚轮选择
- **滚轮范围**: 计时1-720分钟，间隔0-90分钟（0=不提醒）
- **智能反馈**: 5的倍数震动，1秒延迟语音播报
- **状态管理**: 计时进行中时禁用选择器
- **完整播报**: "计时X分钟，间隔X分钟"格式
- **iPad横屏优化**: 滚轮宽度与按钮宽度精确匹配，方向感知动态调整

### 7. 计时器核心逻辑 (TimerViewModel.swift)
**职责**: 计时状态管理、提醒逻辑、后台运行
- **状态管理**: 未开始/运行中/暂停/结束的完整状态流转
- **提醒系统**: 自定义间隔提醒 + 最后2分钟特殊提醒
- **后台支持**: 应用生命周期监听、状态同步
- **锁屏控制**: 完整的媒体控制集成
- **音频生命周期**: 开始计时启动音乐，结束计时停止音乐

## 音频系统架构

### 音频会话管理 (AudioSessionManager.swift)
**职责**: 统一管理AVAudioSession配置
- **三种模式**: .playback(默认)、.playAndRecord(录音)、.spokenAudio(TTS)
- **后台支持**: playback类别自动支持后台播放
- **中断处理**: 音频中断恢复策略，支持系统恢复建议
- **生命周期**: 应用前后台切换时确保音频会话状态

### 持续音频播放器 (ContinuousAudioPlayer.swift)
**职责**: 维持后台音频会话，支持锁屏控制
- **后台维持策略**: 循环播放piano_01.mp3音频文件
- **锁屏控制**: 完整的MPNowPlayingInfoCenter和MPRemoteCommandCenter
- **状态监控**: 多层播放状态检查和重试机制
- **专辑封面**: 动态生成计时器图标

### 语音播报系统 (SpeechHelper.swift)
**职责**: 专为视障用户设计的TTS系统
- **后台播报**: 集成AudioSessionManager支持后台TTS
- **静音检测**: 按需检测设备静音状态，避免无效播报
- **时间格式化**: 时间段判断（凌晨、上午、下午、晚上）
- **精确播报**: 向上取整算法确保剩余时长播报一致性

### 语音识别系统 (SpeechRecognitionHelper.swift)
**职责**: 中文语音识别和指令归一化
- **权限管理**: 详细的权限错误提示和用户引导
- **音频格式适配**: 硬件格式验证，iPad兼容性处理
- **指令归一化**: 复杂正则匹配和中文数字转换
- **错误策略**: 区分不同错误类型，保留部分识别结果

## 设计系统 (DesignSystem.swift)

### 主题系统
- **31种颜色主题**: 11种纯色 + 20种渐变主题
- **深色渐变**: 多种过渡方式（深→浅、对称、三层递进）
- **动态阴影**: 阴影颜色随主题变化，提升视觉层次
- **ThemeManager**: 单例模式，支持SwiftUI实时更新

### 统一规范
- **字体系统**: 统一超细字体(ultraLight)减少视觉干扰
- **阴影系统**: primaryShadow + secondaryShadow双重阴影
- **边框系统**: 多级边框宽度定义
- **间距系统**: 响应式间距适配不同屏幕

## 性能优化实现 (2025-07-30完成)

### 问题解决
- **Display耗电**: 从80%降至正常水平
- **手机发热**: 完全解决发热问题
- **每秒重绘**: 消除不必要的UI更新

### 优化策略

#### 1. 事件驱动架构
- **MainControlButtonsView**: 缓存按钮状态，只在isRunning/isPaused变化时更新
- **TimerPickerView**: UI组件隔离，避免remainingSeconds每秒重绘
- **VoiceRecognitionButton**: 移除对TimerViewModel的不必要监听

#### 2. 智能缓存系统
- **DigitalClockView**: 分级重绘缓存cachedHour/Minute/Second
- **HomeView**: 缓存渐变对象和阴影配置
- **按需更新**: 只有真正变化时才更新@State触发重绘

#### 3. 静音检测优化
- **SilentModeDetector**: 移除每2秒定时器，改为按需检测
- **SpeechHelper**: 只在真正播报时才检测静音状态
- **能耗降低**: 消除持续后台CPU消耗

#### 4. 渲染优化
- **渐变缓存**: 避免每次重绘重新创建LinearGradient对象
- **阴影缓存**: 缓存shadow配置，减少重复计算
- **主题更新**: 只在主题真正变化时更新缓存对象

## 无障碍设计实现

### VoiceOver支持
- **完整标签**: 所有UI元素都有accessibilityLabel和accessibilityHint
- **结构化访问**: 合理的无障碍元素组织
- **状态播报**: 计时器状态的详细语音描述

### 多模态交互
- **语音播报**: 所有操作都有语音反馈
- **震动反馈**: HapticHelper提供轻微震动
- **语音识别**: 支持自然语言控制
- **视觉反馈**: 清晰的状态指示

### 用户体验优化
- **统一术语**: 全应用使用"剩余时长"而非"剩余时间"
- **连贯播报**: 开始计时时播报完整信息
- **智能提醒**: 自定义间隔 + 最后2分钟特殊提醒
- **错误恢复**: 优雅的错误处理和用户引导

## 语音识别归一化规则

### 基础指令
- **计时控制**: "开始计时"、"暂停计时"、"恢复计时"、"结束计时"
- **时间播报**: "时间播报"、"剩余时长"、"剩余时间"
- **状态查询**: "当前状态"、"还有多久"

### 复杂时间设置
- **标准格式**: "计时九十分钟，间隔十五分钟"
- **简化格式**: "计时一小时"、"间隔五分钟"
- **小数表达**: "三点五小时"→210分钟
- **半小时**: "一个半小时"→90分钟、"两个半小时"→150分钟

### 中文数字转换
- **数字映射**: "五十"→50、"三十五"→35
- **单位处理**: 自动识别分钟/小时单位
- **范围检查**: 计时1-720分钟，间隔0-90分钟

## 后台音频播放实现

### 完整要求
1. **Info.plist配置**: UIBackgroundModes包含"audio"（数组格式）
2. **AVAudioSession**: 类别设为.playback，支持后台播放
3. **实际音频播放**: 必须有真实音频文件播放（piano_01.mp3）
4. **Xcode配置**: Target → Signing & Capabilities → Background Modes

### 生命周期管理
- **启动策略**: 应用启动时激活音频会话，不自动播放音乐
- **计时同步**: 开始计时时启动音乐，结束计时时停止音乐
- **暂停保持**: 计时暂停时音乐继续播放以维持后台会话

### 锁屏控制
- **媒体信息**: MPNowPlayingInfoCenter设置计时器信息
- **远程控制**: MPRemoteCommandCenter处理播放/暂停命令
- **状态同步**: 锁屏操作与应用状态实时同步

## 技术要求和兼容性

### iOS版本支持
- **版本范围**: iOS 15.6 - iOS 18.5
- **最低目标**: iOS 15.6部署目标
- **兼容处理**: @available检查确保API兼容性
- **功能降级**: 高版本特性在低版本时自动降级

### 权限管理
- **通知权限**: 计时提醒和完成通知
- **语音识别**: 语音指令控制功能
- **麦克风权限**: 语音识别录音
- **后台刷新**: 后台计时和音频播放

### Swift技术栈
- **Swift 5.7+**: 兼容iOS 15.6
- **SwiftUI 3.0**: iOS 15兼容版本
- **AVFoundation**: 音频播放、录音、语音合成
- **Speech Framework**: 语音识别
- **UserNotifications**: 本地通知
- **MediaPlayer**: 锁屏媒体控制

## 已修复的重要问题

### 性能和稳定性 (2025-07-30)
- **性能耗电问题**: Display耗电从80%降至正常水平，手机不再heating
- **iPad语音识别崩溃**: 音频格式兼容性问题，AVAudioEngine崩溃修复
- **编译警告清理**: 未使用变量警告修复，代码质量提升

### 历史问题修复
- **隐私权限崩溃**: 通过INFOPLIST_KEY配置解决
- **时间播报精度**: 向上取整逻辑修复，确保播报一致性
- **语音识别交互**: 点击开始/停止录音，优化用户体验
- **后台音频播放**: Info.plist配置和音频会话管理修复

## 最新更新记录

### 📦 2025-08-08 版本1.0.3发布准备
**版本信息**：
- Marketing Version: 1.0.2 → 1.0.3
- Build Version: 1.0.2 → 3
- 发布类型：App Store准备版本

**文档完善**：
1. **技术架构文档优化**
   - 补充语音控制实现的详细技术说明
   - 添加关键API和权限管理说明
   - 完善双阶段解析引擎的实现细节

2. **项目文档标准化**
   - 统一术语使用，修复"heating"→"发热"
   - 完善模块职责说明和代码符号引用
   - 优化文档结构，提升可读性

3. **发布准备工作**
   - 版本号升级到1.0.3，Build号升级到3
   - 项目配置文件更新完成
   - 文档与代码实现保持同步

**技术积累**：
- 形成完整的无障碍应用开发经验文档
- 建立语音识别和TTS系统的最佳实践
- 性能优化方案的系统性总结

### 🎯 2025-08-14 iPad横屏模式完整优化
**本次更新主要内容**：
1. **按钮高度分级调整系统**
   - iPad竖屏：第一二行保持原高度，第三行1.5倍
   - iPad横屏：第一二行1.25倍高度，第三行2倍高度
   - iPhone布局完全锁定，不受影响
   
2. **设备方向感知机制**
   - MainControlButtonsView添加设备方向变化监听
   - TimerPickerView添加方向变化响应机制
   - 使用屏幕尺寸检测而非设备方向，提升准确性
   
3. **滚轮宽度精确匹配**
   - iPad横屏模式下滚轮宽度与按钮宽度完全一致
   - 考虑按钮间距(buttonSpacing)和滚轮间距(pickerSpacing)差异
   - 实时响应设备旋转，动态更新布局
   
4. **模式切换一致性**
   - 解决横屏模式下普通/无障碍模式切换按钮高度不一致问题
   - 添加refreshTrigger机制确保UI及时更新
   - 统一按钮高度计算逻辑

5. **设备方向权限控制**
   - iPhone锁定竖屏使用，避免意外旋转影响体验
   - iPad支持横竖屏自由切换，充分利用大屏优势
   - 通过Deployment Info和AppDelegate双重控制

**技术实现**：
- MainControlButtonsView: calculateButtonHeightForDevice()分级计算
- TimerPickerView: calculatePickerWidth()方向感知计算
- 使用UIScreen.main.bounds检测方向，避免设备方向延迟
- 通过NotificationCenter监听设备旋转，触发UI刷新
- AppDelegate实现supportedInterfaceOrientationsFor设备差异化控制

### 🔧 2025-08-08 语音识别功能优化
**本次更新主要内容**：
1. **修复语音增减时间功能持久化问题**
   - 添加 `timeAdjustmentOffset` 偏移量机制
   - 修复 `updateUIDisplay()` 覆盖语音修改的问题
   - 确保语音指令增减时间后不会被重置
   
2. **解决语音播报冲突问题**
   - 实现语音操作优先机制
   - 操作确认播报完成后再播报定时提醒
   - 避免"已增加x分钟"被"剩余时长x分钟"打断
   
3. **增强语音识别同音字支持**
   - 扩展增加时间关键词：家、佳、嘉、茄、+、++、增、正、挣
   - 扩展减少时间关键词：剪、捡、俭、检、尖、-、--、建、见、间
   - 提高语音识别准确性和容错性
   
4. **优化用户体验**
   - 创建盲人版本分支，专注无障碍体验
   - 简化主界面按钮布局，移除冗余按钮
   - 统一按钮尺寸和颜色，提升视觉识别

**技术实现**：
- TimerViewModel 增加时间调整偏移量机制
- VoiceRecognitionButton 扩展同音字识别
- 语音播报优先级控制，避免播报冲突
- 完整保留所有提醒功能，只优化播报时序

## 当前功能状态 (2025-08-14)

### ✅ 已完成功能
- 完整计时功能（计时、暂停、结束）
- 语音识别控制（两阶段解析，复杂指令支持，同音字识别）
- **语音增减时间功能**（持久化修复，播报冲突解决）
- TTS语音播报（统一术语，后台播报，优先级控制）
- 后台音频播放和锁屏控制
- 本地通知和定时提醒
- 用户设置持久化
- 完整的无障碍支持（盲人版本界面优化）
- 震动反馈和触觉体验
- 性能优化（事件驱动，智能缓存）
- **iPad完整优化支持**（横屏按钮分级调整、滚轮宽度匹配、方向感知）

### ⏸️ 临时隐藏功能
- 主题选择功能（专注核心体验）
- 内购功能（待完善）

### 🚀 发布准备
- 免费增值模式：完整功能免费使用
- 用户积累阶段：专注核心体验，建立用户基础
- 后续变现：用户量增长后推出主题包等付费功能

## 开发和测试命令

```bash
# 构建项目
xcodebuild -project SimpleClock.xcodeproj -scheme SimpleClock -configuration Debug

# 模拟器运行
open -a Simulator
xcodebuild -project SimpleClock.xcodeproj -scheme SimpleClock -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5' build

# 清理构建缓存
xcodebuild clean -project SimpleClock.xcodeproj -scheme SimpleClock

# 检查编译警告
xcodebuild -project SimpleClock.xcodeproj -scheme SimpleClock -configuration Debug build -quiet 2>&1 | grep -E "(warning|error)"
```

## 重要开发原则

1. **无障碍优先**: 每个功能都必须考虑视力障碍用户需求
2. **性能为王**: 避免不必要的UI重绘和CPU消耗
3. **语音反馈**: 所有交互都应提供语音或震动反馈
4. **兼容性**: 确保在iOS 15.6-18.5全版本正常运行
5. **Swift最佳实践**: 遵循官方文档和社区最佳实践
6. **事件驱动**: 优先使用事件驱动而非时间驱动的UI更新

## 项目亮点总结

1. **性能优化**: 分级缓存、事件驱动、智能重绘，彻底解决耗电发热问题
2. **无障碍设计**: 完整的VoiceOver、语音播报、震动反馈体系
3. **语音处理**: 复杂的中文语音识别、指令归一化、两阶段解析
4. **后台音频**: 真实音频播放、锁屏控制、生命周期管理
5. **主题系统**: 31种主题、动态阴影、响应式设计
6. **错误处理**: 优雅的权限管理、音频中断恢复、播放状态监控
7. **用户体验**: 统一术语、连贯播报、智能提醒、自然语言交互

SimpleClock是一个技术实现精细化、用户体验优秀的无障碍计时器应用，展现了对视障用户需求的深度理解和高质量的工程实现。

## 语音控制实现
### 核心功能
1. **指令枚举体系**
   - <mcsymbol name="VoiceCommand" filename="VoiceRecognitionButton.swift" path="SimpleClock/Views/VoiceRecognitionButton.swift" startline="45" type="enum"></mcsymbol> 定义9种计时指令
   - 支持同音字识别（如"开始"匹配"开启/启动"）

2. **双阶段解析引擎**
   - 第一阶段：<mcsymbol name="extractSubtractTimeFromText" filename="VoiceRecognitionButton.swift" path="SimpleClock/Views/VoiceRecognitionButton.swift" startline="132" type="function"></mcsymbol> 精准匹配数字
   - 第二阶段：<mcsymbol name="intelligentCommandRecognition" filename="VoiceRecognitionButton.swift" path="SimpleClock/Views/VoiceRecognitionButton.swift" startline="165" type="function"></mcsymbol> 语义分析

3. **状态校验机制**
   - 在<mcfile name="VoiceRecognitionButton.swift" path="SimpleClock/Views/VoiceRecognitionButton.swift"></mcfile>中实现viewModel.isRunning状态检查
   - 无效操作时通过<mcfile name="SpeechHelper.swift" path="SimpleClock/Utils/SpeechHelper.swift"></mcfile>播报提示

### 关键API
```swift
// 指令执行入口
func executeCommand(_ command: VoiceCommand) {
    switch command {
    case .startTimer:
        guard !viewModel.isRunning else { return }
        viewModel.startTimer()
        SpeechHelper.shared.speak("已开始\(viewModel.selectedTime)分钟计时")
    // ... 其他case ...
    }
}

// 音频会话管理
class AudioSessionManager {
    func switchToMode(_ mode: AudioSessionMode) {
        // ... 实现.playAndRecord与.videoChat模式切换
    }
}
```

### 权限管理
- <mcfile name="PermissionManager.swift" path="SimpleClock/Utils/PermissionManager.swift"></mcfile> 实现语音识别权限请求链
- Info.plist包含`NSSpeechRecognitionUsageDescription`声明