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
        
        // 10种渐变主题
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
        /// 时钟数字大小
        static let clockDigit: CGFloat = 72
        
        /// 冒号大小
        static let colon: CGFloat = 50
        
        /// 按钮图标大小
        static let buttonIcon: CGFloat = 24
        
        /// 按钮文字大小
        static let buttonText: CGFloat = 16
        
        /// 标题文字大小
        static let titleText: CGFloat = 20
        
        /// 选择器文字大小
        static let pickerText: CGFloat = 18
        
        /// 标签文字大小
        static let labelText: CGFloat = 16
        
        /// 标签图标大小
        static let labelIcon: CGFloat = 14
        
        /// 语音识别按钮高度
        static let voiceButtonHeight: CGFloat = 157.5
        
        /// 主控制按钮高度
        static let mainButtonHeight: CGFloat = 90
        
        /// 语音图标背景圆形大小
        static let voiceIconBackground: CGFloat = 60
        
        /// 语音图标大小
        static let voiceIcon: CGFloat = 28
        
        /// 语音状态文字大小
        static let voiceStateText: CGFloat = 18
    }
    
    // MARK: - 间距系统
    
    /// 间距定义
    struct Spacing {
        /// 极小间距
        static let tiny: CGFloat = 2
        
        /// 小间距
        static let small: CGFloat = 8
        
        /// 中间距
        static let medium: CGFloat = 16
        
        /// 大间距
        static let large: CGFloat = 32
        
        /// 时钟数字间距（冒号padding）
        static let clockDigitSpacing: CGFloat = 2
        
        /// 按钮间距
        static let buttonSpacing: CGFloat = 16
        
        /// 选择器间距
        static let pickerSpacing: CGFloat = 32
        
        /// 标签间距
        static let labelSpacing: CGFloat = 6
        
        /// 图标和文字间距
        static let iconTextSpacing: CGFloat = 10
        
        /// 语音按钮内部间距
        static let voiceButtonInternalSpacing: CGFloat = 12
    }
    
    // MARK: - 圆角系统
    
    /// 圆角定义
    struct CornerRadius {
        /// 按钮圆角
        static let button: CGFloat = 16
        
        /// 语音按钮圆角
        static let voiceButton: CGFloat = 24
        
        /// 选择器背景圆角
        static let pickerBackground: CGFloat = 12
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