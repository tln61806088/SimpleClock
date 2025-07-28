import SwiftUI

/// SimpleClock应用的统一设计系统
/// 管理所有颜色、字体、阴影等视觉元素
struct DesignSystem {
    
    // MARK: - 颜色系统
    
    /// 主要颜色定义
    struct Colors {
        /// 藏青色 - 主色调
        static let navyBlue = Color(red: 0.1, green: 0.2, blue: 0.5)
        
        /// 紫色 - 辅助色
        static let purple = Color.purple
        
        /// 主要渐变色（藏青色-紫色-藏青色）
        static let primaryGradient = LinearGradient(
            gradient: Gradient(colors: [
                navyBlue,
                purple,
                navyBlue
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
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
        /// 主要阴影（藏青色）
        static let primaryShadow = Shadow(
            color: Colors.navyBlue.opacity(0.3),
            radius: 4,
            x: 0,
            y: 2
        )
        
        /// 次要阴影（紫色）
        static let secondaryShadow = Shadow(
            color: Colors.purple.opacity(0.2),
            radius: 2,
            x: 0,
            y: 1
        )
        
        /// 大阴影（用于时钟整体）
        static let largePrimaryShadow = Shadow(
            color: Colors.navyBlue.opacity(0.4),
            radius: 12,
            x: 0,
            y: 6
        )
        
        /// 大次要阴影（用于时钟整体）
        static let largeSecondaryShadow = Shadow(
            color: Colors.purple.opacity(0.3),
            radius: 6,
            x: 0,
            y: 3
        )
        
        /// 时钟数字阴影
        static let clockDigitShadow = Shadow(
            color: Colors.navyBlue.opacity(0.3),
            radius: 8,
            x: 0,
            y: 4
        )
        
        /// 时钟数字次要阴影
        static let clockDigitSecondaryShadow = Shadow(
            color: Colors.purple.opacity(0.2),
            radius: 4,
            x: 0,
            y: 2
        )
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