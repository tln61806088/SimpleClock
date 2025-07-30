import SwiftUI

/// 主题管理器，支持SwiftUI实时更新
class ThemeManager: ObservableObject {
    @Published var currentTheme: DesignSystem.ColorTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "selectedColorTheme")
        }
    }
    
    static let shared = ThemeManager()
    
    private init() {
        if let savedTheme = UserDefaults.standard.string(forKey: "selectedColorTheme"),
           let theme = DesignSystem.ColorTheme(rawValue: savedTheme) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .black
        }
    }
}

/// SimpleClock应用的统一设计系统
/// 管理所有颜色、字体、阴影等视觉元素
struct DesignSystem {
    
    // MARK: - 颜色主题管理
    
    /// 当前选中的颜色主题（兼容性保留）
    static var currentTheme: ColorTheme {
        get { ThemeManager.shared.currentTheme }
        set { ThemeManager.shared.currentTheme = newValue }
    }
    
    /// 颜色主题枚举
    enum ColorTheme: String, CaseIterable, Identifiable {
        // 11种纯色主题
        case red = "red"
        case orange = "orange"
        case yellow = "yellow"
        case green = "green"
        case blue = "blue"
        case indigo = "indigo"
        case purple = "purple"
        case pink = "pink"
        case brown = "brown"
        case gray = "gray"
        case black = "black"
        
        // 20种渐变主题 - 前10种
        case navyPurple = "navyPurple"
        case sunset = "sunset"
        case ocean = "ocean"
        case forest = "forest"
        case rose = "rose"
        case galaxy = "galaxy"
        case mint = "mint"
        case fire = "fire"
        case sky = "sky"
        case lavender = "lavender"
        
        // 新增10种深色渐变主题
        case deepNight = "deepNight"          // 深夜：深蓝到黑色
        case darkForest = "darkForest"        // 暗森林：深绿到黑色  
        case charcoal = "charcoal"            // 炭灰：深灰到黑色
        case deepOcean = "deepOcean"          // 深海：深蓝到深青色
        case darkBerry = "darkBerry"          // 暗莓：深紫到深红
        case shadowGreen = "shadowGreen"      // 阴影绿：墨绿到深绿
        case darkRose = "darkRose"            // 暗玫瑰：深粉到深红
        case midnight = "midnight"            // 午夜：深蓝到深紫
        case darkAmber = "darkAmber"          // 暗琥珀：深橙到深棕
        case steelGray = "steelGray"          // 钢灰：深蓝灰到深灰
        
        var id: String { rawValue }
        
        /// 主题名称
        var name: String {
            switch self {
            case .red: return "红色"
            case .orange: return "橙色"
            case .yellow: return "黄色"
            case .green: return "绿色"
            case .blue: return "蓝色"
            case .indigo: return "靛蓝"
            case .purple: return "紫色"
            case .pink: return "粉色"
            case .brown: return "棕色"
            case .gray: return "灰色"
            case .black: return "黑色"
            case .navyPurple: return "藏青紫"
            case .sunset: return "日落"
            case .ocean: return "海洋"
            case .forest: return "森林"
            case .rose: return "玫瑰"
            case .galaxy: return "星河"
            case .mint: return "薄荷"
            case .fire: return "火焰"
            case .sky: return "天空"
            case .lavender: return "薰衣草"
            case .deepNight: return "深夜"
            case .darkForest: return "暗森林"
            case .charcoal: return "炭灰"
            case .deepOcean: return "深海"
            case .darkBerry: return "暗莓"
            case .shadowGreen: return "阴影绿"
            case .darkRose: return "暗玫瑰"
            case .midnight: return "午夜"
            case .darkAmber: return "暗琥珀"
            case .steelGray: return "钢灰"
            }
        }
        
        /// 是否为渐变主题
        var isGradient: Bool {
            switch self {
            case .red, .orange, .yellow, .green, .blue, .indigo, .purple, .pink, .brown, .gray, .black:
                return false
            default:
                return true
            }
        }
        
        /// 获取主题的主要渐变色
        var primaryGradient: LinearGradient {
            switch self {
            // 纯色主题
            case .red:
                return LinearGradient(colors: [.red], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .orange:
                return LinearGradient(colors: [.orange], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .yellow:
                return LinearGradient(colors: [.yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .green:
                return LinearGradient(colors: [.green], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .blue:
                return LinearGradient(colors: [.blue], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .indigo:
                return LinearGradient(colors: [.indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .purple:
                return LinearGradient(colors: [.purple], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .pink:
                return LinearGradient(colors: [.pink], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .brown:
                return LinearGradient(colors: [.brown], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .gray:
                return LinearGradient(colors: [.gray], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .black:
                return LinearGradient(colors: [.black], startPoint: .topLeading, endPoint: .bottomTrailing)
                
            // 渐变主题
            case .navyPurple:
                return LinearGradient(
                    colors: [Color(red: 0.1, green: 0.2, blue: 0.5), .purple, Color(red: 0.1, green: 0.2, blue: 0.5)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            case .sunset:
                return LinearGradient(
                    colors: [.orange, .red, .pink],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            case .ocean:
                return LinearGradient(
                    colors: [.blue, .cyan, .blue],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            case .forest:
                return LinearGradient(
                    colors: [.green, Color(red: 0.0, green: 0.4, blue: 0.0), .green],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            case .rose:
                return LinearGradient(
                    colors: [.pink, Color(red: 0.9, green: 0.4, blue: 0.6), .pink],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            case .galaxy:
                return LinearGradient(
                    colors: [.purple, .indigo, .black],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            case .mint:
                return LinearGradient(
                    colors: [.mint, .green, .mint],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            case .fire:
                return LinearGradient(
                    colors: [.red, .orange, .yellow],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            case .sky:
                return LinearGradient(
                    colors: [.cyan, .blue, .indigo],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            case .lavender:
                return LinearGradient(
                    colors: [Color(red: 0.9, green: 0.8, blue: 1.0), .purple, Color(red: 0.9, green: 0.8, blue: 1.0)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                
            // 新增深色渐变主题 - 多样化过渡方式
            case .deepNight:
                // 深→浅渐变（如日落模式）
                return LinearGradient(
                    colors: [Color(red: 0.0, green: 0.05, blue: 0.2), Color(red: 0.1, green: 0.3, blue: 0.6), Color(red: 0.3, green: 0.5, blue: 0.9)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            case .darkForest:
                // 对称模式（如藏青紫）
                return LinearGradient(
                    colors: [Color(red: 0.0, green: 0.15, blue: 0.05), Color(red: 0.2, green: 0.7, blue: 0.3), Color(red: 0.0, green: 0.15, blue: 0.05)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            case .charcoal:
                // 浅→深渐变（反向）
                return LinearGradient(
                    colors: [Color(red: 0.6, green: 0.6, blue: 0.6), Color(red: 0.3, green: 0.3, blue: 0.3), Color(red: 0.05, green: 0.05, blue: 0.05)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            case .deepOcean:
                // 三层递进（如海洋模式）
                return LinearGradient(
                    colors: [Color(red: 0.0, green: 0.2, blue: 0.4), Color(red: 0.0, green: 0.4, blue: 0.7), Color(red: 0.0, green: 0.6, blue: 1.0)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            case .darkBerry:
                // 深→浅→中等（不规则）
                return LinearGradient(
                    colors: [Color(red: 0.2, green: 0.0, blue: 0.1), Color(red: 0.8, green: 0.2, blue: 0.5), Color(red: 0.5, green: 0.1, blue: 0.3)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            case .shadowGreen:
                // 中等→亮→深（反对称）
                return LinearGradient(
                    colors: [Color(red: 0.1, green: 0.4, blue: 0.2), Color(red: 0.3, green: 0.8, blue: 0.4), Color(red: 0.0, green: 0.2, blue: 0.1)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            case .darkRose:
                // 浅→深渐变
                return LinearGradient(
                    colors: [Color(red: 0.9, green: 0.4, blue: 0.6), Color(red: 0.6, green: 0.2, blue: 0.4), Color(red: 0.3, green: 0.0, blue: 0.15)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            case .midnight:
                // 对称模式但颜色更丰富
                return LinearGradient(
                    colors: [Color(red: 0.1, green: 0.0, blue: 0.3), Color(red: 0.3, green: 0.1, blue: 0.8), Color(red: 0.05, green: 0.0, blue: 0.2)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            case .darkAmber:
                // 深→亮→中等（类似火焰模式）
                return LinearGradient(
                    colors: [Color(red: 0.2, green: 0.1, blue: 0.0), Color(red: 1.0, green: 0.6, blue: 0.1), Color(red: 0.6, green: 0.3, blue: 0.0)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            case .steelGray:
                // 平缓递进
                return LinearGradient(
                    colors: [Color(red: 0.2, green: 0.25, blue: 0.3), Color(red: 0.4, green: 0.45, blue: 0.5), Color(red: 0.6, green: 0.65, blue: 0.7)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            }
        }
        
        /// 获取主题的主要颜色（用于阴影等）
        var primaryColor: Color {
            switch self {
            case .red: return .red
            case .orange: return .orange
            case .yellow: return .yellow
            case .green: return .green
            case .blue: return .blue
            case .indigo: return .indigo
            case .purple: return .purple
            case .pink: return .pink
            case .brown: return .brown
            case .gray: return .gray
            case .black: return .black
            case .navyPurple: return Color(red: 0.1, green: 0.2, blue: 0.5)
            case .sunset: return .orange
            case .ocean: return .blue
            case .forest: return .green
            case .rose: return .pink
            case .galaxy: return .purple
            case .mint: return .mint
            case .fire: return .red
            case .sky: return .cyan
            case .lavender: return Color(red: 0.9, green: 0.8, blue: 1.0)
            case .deepNight: return Color(red: 0.3, green: 0.5, blue: 0.9)        // 最亮的蓝色
            case .darkForest: return Color(red: 0.2, green: 0.7, blue: 0.3)      // 中间最亮的绿色
            case .charcoal: return Color(red: 0.6, green: 0.6, blue: 0.6)        // 最亮的灰色
            case .deepOcean: return Color(red: 0.0, green: 0.6, blue: 1.0)       // 最亮的海蓝
            case .darkBerry: return Color(red: 0.8, green: 0.2, blue: 0.5)       // 中间最亮的紫红
            case .shadowGreen: return Color(red: 0.3, green: 0.8, blue: 0.4)     // 中间最亮的翠绿
            case .darkRose: return Color(red: 0.9, green: 0.4, blue: 0.6)        // 最亮的玫瑰色
            case .midnight: return Color(red: 0.3, green: 0.1, blue: 0.8)        // 中间最亮的紫蓝
            case .darkAmber: return Color(red: 1.0, green: 0.6, blue: 0.1)       // 中间最亮的金色
            case .steelGray: return Color(red: 0.6, green: 0.65, blue: 0.7)      // 最亮的钢灰
            }
        }
        
        /// 获取主题的次要颜色
        var secondaryColor: Color {
            switch self {
            case .red: return .red.opacity(0.7)
            case .orange: return .orange.opacity(0.7)
            case .yellow: return .yellow.opacity(0.7)
            case .green: return .green.opacity(0.7)
            case .blue: return .blue.opacity(0.7)
            case .indigo: return .indigo.opacity(0.7)
            case .purple: return .purple.opacity(0.7)
            case .pink: return .pink.opacity(0.7)
            case .brown: return .brown.opacity(0.7)
            case .gray: return .gray.opacity(0.7)
            case .black: return .black.opacity(0.7)
            case .navyPurple: return .purple
            case .sunset: return .red
            case .ocean: return .cyan
            case .forest: return Color(red: 0.0, green: 0.4, blue: 0.0)
            case .rose: return Color(red: 0.9, green: 0.4, blue: 0.6)
            case .galaxy: return .indigo
            case .mint: return .green
            case .fire: return .orange
            case .sky: return .blue
            case .lavender: return .purple
            case .deepNight: return Color(red: 0.0, green: 0.05, blue: 0.2)         // 最深的蓝黑
            case .darkForest: return Color(red: 0.0, green: 0.15, blue: 0.05)       // 深绿黑色
            case .charcoal: return Color(red: 0.05, green: 0.05, blue: 0.05)        // 最深的黑灰
            case .deepOcean: return Color(red: 0.0, green: 0.2, blue: 0.4)          // 深海蓝
            case .darkBerry: return Color(red: 0.2, green: 0.0, blue: 0.1)          // 深紫黑色
            case .shadowGreen: return Color(red: 0.0, green: 0.2, blue: 0.1)        // 最深的绿黑
            case .darkRose: return Color(red: 0.3, green: 0.0, blue: 0.15)          // 最深的玫瑰黑
            case .midnight: return Color(red: 0.05, green: 0.0, blue: 0.2)          // 深紫黑色
            case .darkAmber: return Color(red: 0.2, green: 0.1, blue: 0.0)          // 深棕黑色
            case .steelGray: return Color(red: 0.2, green: 0.25, blue: 0.3)         // 深钢蓝色
            }
        }
    }
    
    /// 主要颜色定义
    struct Colors {
        /// 主要渐变色（动态根据当前主题）
        static var primaryGradient: LinearGradient {
            currentTheme.primaryGradient
        }
        
        /// 主要颜色（动态根据当前主题）
        static var primaryColor: Color {
            currentTheme.primaryColor
        }
        
        /// 次要颜色（动态根据当前主题）
        static var secondaryColor: Color {
            currentTheme.secondaryColor
        }
        
        /// 背景渐变色
        static let backgroundGradient = LinearGradient(
            gradient: Gradient(colors: [
                Color(.systemBackground),
                Color(.systemGray6).opacity(0.3),
                Color(.systemBackground)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        /// 分割线渐变色
        static let dividerGradient = LinearGradient(
            gradient: Gradient(colors: [
                .clear,
                .gray.opacity(0.3),
                .clear
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // MARK: - 字体系统
    
    /// 字体定义
    struct Fonts {
        /// 时钟数字字体
        static func clockDigit(size: CGFloat) -> Font {
            .system(size: size, weight: .ultraLight, design: .monospaced)
        }
        
        /// 按钮文字字体
        static func buttonText(size: CGFloat) -> Font {
            .system(size: size, weight: .ultraLight, design: .monospaced)
        }
        
        /// 按钮图标字体
        static func buttonIcon(size: CGFloat) -> Font {
            .system(size: size, weight: .ultraLight, design: .monospaced)
        }
        
        /// 标题字体
        static func title(size: CGFloat) -> Font {
            .system(size: size, weight: .ultraLight, design: .monospaced)
        }
        
        /// 选择器文字字体（粗体）
        static func pickerText(size: CGFloat) -> Font {
            .system(size: size, weight: .bold, design: .monospaced)
        }
        
        /// 标签文字字体
        static func labelText(size: CGFloat) -> Font {
            .system(size: size, weight: .ultraLight, design: .monospaced)
        }
    }
    
    // MARK: - 阴影系统
    
    /// 阴影效果定义
    struct Shadows {
        /// 主要阴影（动态根据当前主题）
        static var primaryShadow: Shadow {
            Shadow(
                color: Colors.primaryColor.opacity(0.3),
                radius: 4,
                x: 0,
                y: 2
            )
        }
        
        /// 次要阴影（动态根据当前主题）
        static var secondaryShadow: Shadow {
            Shadow(
                color: Colors.secondaryColor.opacity(0.2),
                radius: 2,
                x: 0,
                y: 1
            )
        }
        
        /// 大阴影（用于时钟整体）
        static var largePrimaryShadow: Shadow {
            Shadow(
                color: Colors.primaryColor.opacity(0.4),
                radius: 12,
                x: 0,
                y: 6
            )
        }
        
        /// 大次要阴影（用于时钟整体）
        static var largeSecondaryShadow: Shadow {
            Shadow(
                color: Colors.secondaryColor.opacity(0.3),
                radius: 6,
                x: 0,
                y: 3
            )
        }
        
        /// 时钟数字阴影
        static var clockDigitShadow: Shadow {
            Shadow(
                color: Colors.primaryColor.opacity(0.3),
                radius: 8,
                x: 0,
                y: 4
            )
        }
        
        /// 时钟数字次要阴影
        static var clockDigitSecondaryShadow: Shadow {
            Shadow(
                color: Colors.secondaryColor.opacity(0.2),
                radius: 4,
                x: 0,
                y: 2
            )
        }
    }
    
    // MARK: - 边框系统
    
    /// 边框定义
    struct Borders {
        /// 主要边框（用于按钮）
        static let primaryBorder = StrokeStyle(lineWidth: 2)
        
        /// 细边框（用于图标背景）
        static let thinBorder = StrokeStyle(lineWidth: 1)
        
        /// 动画边框（用于录音波纹）
        static let animationBorder = StrokeStyle(lineWidth: 3)
    }
    
    // MARK: - 尺寸系统
    
    /// 尺寸定义
    struct Sizes {
        // MARK: - 等比例自适应系统（基于iPhone 15 Pro设计）
        
        /// iPhone 15 Pro基准尺寸
        private static let baseScreenWidth: CGFloat = 393.0    // iPhone 15 Pro宽度
        private static let baseScreenHeight: CGFloat = 852.0   // iPhone 15 Pro高度
        
        /// 当前屏幕尺寸
        private static var screenWidth: CGFloat {
            UIScreen.main.bounds.width
        }
        
        private static var screenHeight: CGFloat {
            UIScreen.main.bounds.height
        }
        
        /// 宽度缩放比例
        private static var widthScale: CGFloat {
            screenWidth / baseScreenWidth
        }
        
        /// 高度缩放比例  
        private static var heightScale: CGFloat {
            screenHeight / baseScreenHeight
        }
        
        /// 综合缩放比例（取宽高缩放的平均值，确保比例协调）
        static var scale: CGFloat {
            min(widthScale, heightScale) // 使用较小的缩放比例，避免内容溢出
        }
        
        // MARK: - iPhone 15 Pro基准尺寸定义
        
        /// 基准时钟数字大小
        private static let baseClockDigit: CGFloat = 72
        
        /// 基准按钮图标大小
        private static let baseButtonIcon: CGFloat = 24
        
        /// 基准按钮文字大小
        private static let baseButtonText: CGFloat = 16
        
        /// 基准标题文字大小
        private static let baseTitleText: CGFloat = 20
        
        /// 基准选择器文字大小
        private static let basePickerText: CGFloat = 18
        
        /// 基准标签文字大小
        private static let baseLabelText: CGFloat = 16
        
        /// 基准标签图标大小
        private static let baseLabelIcon: CGFloat = 14
        
        /// 基准语音识别按钮高度
        private static let baseVoiceButtonHeight: CGFloat = 157.5
        
        /// 基准主控制按钮高度
        private static let baseMainButtonHeight: CGFloat = 90
        
        /// 基准语音图标背景圆形大小
        private static let baseVoiceIconBackground: CGFloat = 60
        
        /// 基准语音状态文字大小
        private static let baseVoiceStateText: CGFloat = 18
        
        // MARK: - 等比例缩放的动态尺寸
        
        /// 时钟数字大小（等比例缩放）
        static var clockDigit: CGFloat {
            baseClockDigit * scale
        }
        
        /// 冒号大小（等比例缩放）
        static var colon: CGFloat {
            clockDigit * 0.7 // 相对于时钟数字的70%
        }
        
        /// 按钮图标大小（等比例缩放）
        static var buttonIcon: CGFloat {
            baseButtonIcon * scale
        }
        
        /// 按钮文字大小（等比例缩放）
        static var buttonText: CGFloat {
            baseButtonText * scale
        }
        
        /// 标题文字大小（等比例缩放）
        static var titleText: CGFloat {
            baseTitleText * scale
        }
        
        /// 选择器文字大小（等比例缩放）
        static var pickerText: CGFloat {
            basePickerText * scale
        }
        
        /// 标签文字大小（等比例缩放）
        static var labelText: CGFloat {
            baseLabelText * scale
        }
        
        /// 标签图标大小（等比例缩放）
        static var labelIcon: CGFloat {
            baseLabelIcon * scale
        }
        
        /// 语音识别按钮高度（等比例缩放）
        static var voiceButtonHeight: CGFloat {
            baseVoiceButtonHeight * scale
        }
        
        /// 主控制按钮高度（等比例缩放）
        static var mainButtonHeight: CGFloat {
            baseMainButtonHeight * scale
        }
        
        /// 语音图标背景圆形大小（等比例缩放）
        static var voiceIconBackground: CGFloat {
            baseVoiceIconBackground * scale
        }
        
        /// 语音图标大小（等比例缩放）
        static var voiceIcon: CGFloat {
            voiceIconBackground * 0.47 // 相对于背景圆形的47%
        }
        
        /// 语音状态文字大小（等比例缩放）
        static var voiceStateText: CGFloat {
            baseVoiceStateText * scale
        }
        
        // MARK: - 调试信息
        
        /// 获取当前缩放信息（用于调试）
        static var debugScaleInfo: String {
            return """
            屏幕尺寸: \(Int(screenWidth))×\(Int(screenHeight))
            基准尺寸: \(Int(baseScreenWidth))×\(Int(baseScreenHeight))
            宽度缩放: \(String(format: "%.2f", widthScale))
            高度缩放: \(String(format: "%.2f", heightScale))
            最终缩放: \(String(format: "%.2f", scale))
            """
        }
    }
    
    // MARK: - 间距系统
    
    /// 间距定义（等比例缩放）
    struct Spacing {
        // MARK: - iPhone 15 Pro基准间距
        private static let baseTiny: CGFloat = 2
        private static let baseSmall: CGFloat = 8
        private static let baseMedium: CGFloat = 16
        private static let baseLarge: CGFloat = 32
        private static let baseClockDigitSpacing: CGFloat = 2
        private static let baseButtonSpacing: CGFloat = 16
        private static let basePickerSpacing: CGFloat = 32
        private static let baseLabelSpacing: CGFloat = 6
        private static let baseIconTextSpacing: CGFloat = 10
        private static let baseVoiceButtonInternalSpacing: CGFloat = 12
        
        // MARK: - 等比例缩放的间距
        
        /// 极小间距（等比例缩放）
        static var tiny: CGFloat {
            baseTiny * Sizes.scale
        }
        
        /// 小间距（等比例缩放）
        static var small: CGFloat {
            baseSmall * Sizes.scale
        }
        
        /// 中间距（等比例缩放）
        static var medium: CGFloat {
            baseMedium * Sizes.scale
        }
        
        /// 大间距（等比例缩放）
        static var large: CGFloat {
            baseLarge * Sizes.scale
        }
        
        /// 时钟数字间距（等比例缩放）
        static var clockDigitSpacing: CGFloat {
            baseClockDigitSpacing * Sizes.scale
        }
        
        /// 按钮间距（等比例缩放）
        static var buttonSpacing: CGFloat {
            baseButtonSpacing * Sizes.scale
        }
        
        /// 选择器间距（等比例缩放）
        static var pickerSpacing: CGFloat {
            basePickerSpacing * Sizes.scale
        }
        
        /// 标签间距（等比例缩放）
        static var labelSpacing: CGFloat {
            baseLabelSpacing * Sizes.scale
        }
        
        /// 图标和文字间距（等比例缩放）
        static var iconTextSpacing: CGFloat {
            baseIconTextSpacing * Sizes.scale
        }
        
        /// 语音按钮内部间距（等比例缩放）
        static var voiceButtonInternalSpacing: CGFloat {
            baseVoiceButtonInternalSpacing * Sizes.scale
        }
    }
    
    // MARK: - 圆角系统
    
    /// 圆角定义（等比例缩放）
    struct CornerRadius {
        // MARK: - iPhone 15 Pro基准圆角
        private static let baseButton: CGFloat = 16
        private static let baseVoiceButton: CGFloat = 24
        private static let basePickerBackground: CGFloat = 12
        
        // MARK: - 等比例缩放的圆角
        
        /// 按钮圆角（等比例缩放）
        static var button: CGFloat {
            baseButton * Sizes.scale
        }
        
        /// 语音按钮圆角（等比例缩放）
        static var voiceButton: CGFloat {
            baseVoiceButton * Sizes.scale
        }
        
        /// 选择器背景圆角（等比例缩放）
        static var pickerBackground: CGFloat {
            basePickerBackground * Sizes.scale
        }
    }
}

/// 阴影数据结构
struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - View扩展，方便使用设计系统

extension View {
    /// 应用主要文字样式
    func primaryTextStyle(size: CGFloat) -> some View {
        self
            .font(DesignSystem.Fonts.buttonText(size: size))
            .foregroundStyle(DesignSystem.Colors.primaryGradient)
            .shadow(color: DesignSystem.Shadows.primaryShadow.color, 
                   radius: DesignSystem.Shadows.primaryShadow.radius,
                   x: DesignSystem.Shadows.primaryShadow.x,
                   y: DesignSystem.Shadows.primaryShadow.y)
            .shadow(color: DesignSystem.Shadows.secondaryShadow.color,
                   radius: DesignSystem.Shadows.secondaryShadow.radius,
                   x: DesignSystem.Shadows.secondaryShadow.x,
                   y: DesignSystem.Shadows.secondaryShadow.y)
    }
    
    /// 应用时钟数字样式
    func clockDigitStyle() -> some View {
        self
            .font(DesignSystem.Fonts.clockDigit(size: DesignSystem.Sizes.clockDigit))
            .foregroundStyle(DesignSystem.Colors.primaryGradient)
            .shadow(color: DesignSystem.Shadows.clockDigitShadow.color,
                   radius: DesignSystem.Shadows.clockDigitShadow.radius,
                   x: DesignSystem.Shadows.clockDigitShadow.x,
                   y: DesignSystem.Shadows.clockDigitShadow.y)
            .shadow(color: DesignSystem.Shadows.clockDigitSecondaryShadow.color,
                   radius: DesignSystem.Shadows.clockDigitSecondaryShadow.radius,
                   x: DesignSystem.Shadows.clockDigitSecondaryShadow.x,
                   y: DesignSystem.Shadows.clockDigitSecondaryShadow.y)
    }
    
    /// 应用主要边框样式
    func primaryBorderStyle() -> some View {
        self.background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                .stroke(DesignSystem.Colors.primaryGradient, lineWidth: DesignSystem.Borders.primaryBorder.lineWidth)
        )
    }
}