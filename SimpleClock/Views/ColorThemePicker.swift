import SwiftUI

/// 颜色主题选择器 - 共享状态管理
class ColorThemeState: ObservableObject {
    @Published var isExpanded = false
}

/// 颜色主题切换按钮（用于导航栏）
struct ColorThemeToggleButton: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @EnvironmentObject private var colorThemeState: ColorThemeState
    @State private var animateButton = false
    
    var body: some View {
        Button(action: {
            HapticHelper.shared.lightImpact()
            withAnimation(.easeInOut(duration: 0.3)) {
                colorThemeState.isExpanded.toggle()
                animateButton.toggle()
            }
        }) {
            Image(systemName: colorThemeState.isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                .font(DesignSystem.Fonts.buttonIcon(size: DesignSystem.Sizes.labelIcon + 2))
                .foregroundStyle(themeManager.currentTheme.primaryGradient)
                .shadow(color: DesignSystem.Shadows.primaryShadow.color,
                       radius: DesignSystem.Shadows.primaryShadow.radius,
                       x: DesignSystem.Shadows.primaryShadow.x,
                       y: DesignSystem.Shadows.primaryShadow.y)
                .shadow(color: DesignSystem.Shadows.secondaryShadow.color,
                       radius: DesignSystem.Shadows.secondaryShadow.radius,
                       x: DesignSystem.Shadows.secondaryShadow.x,
                       y: DesignSystem.Shadows.secondaryShadow.y)
                .scaleEffect(animateButton ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: animateButton)
        }
        .accessibilityLabel("颜色主题选择")
        .accessibilityHint(colorThemeState.isExpanded ? "点击收起颜色选择" : "点击展开颜色选择")
    }
}

/// 颜色主题覆盖层（用于全屏覆盖）
struct ColorThemeOverlay: View {
    @EnvironmentObject private var colorThemeState: ColorThemeState
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var purchaseManager = PurchaseManager.shared
    @State private var showPurchaseAlert = false
    @State private var selectedLockedTheme: DesignSystem.ColorTheme?
    
    var body: some View {
        if colorThemeState.isExpanded {
            ZStack {
                // 半透明背景，点击可关闭
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            colorThemeState.isExpanded = false
                        }
                    }
                
                // 颜色选择面板
                VStack {
                    HStack {
                        colorSelectionPanel
                        Spacer()
                    }
                    Spacer()
                }
                .padding(.horizontal, DesignSystem.Spacing.medium + 4)
                .padding(.top, 75) // 在导航栏下方显示
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.3), value: colorThemeState.isExpanded)
            .alert("解锁主题", isPresented: $showPurchaseAlert) {
                if let theme = selectedLockedTheme {
                    Button("购买解锁") {
                        handlePurchaseTheme(theme)
                    }
                    Button("取消", role: .cancel) {
                        selectedLockedTheme = nil
                    }
                }
            } message: {
                if let theme = selectedLockedTheme {
                    Text(getPurchaseMessage(for: theme))
                }
            }
        }
    }
    
    /// 颜色选择面板
    private var colorSelectionPanel: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            // 标题
            Text("选择主题颜色")
                .font(DesignSystem.Fonts.labelText(size: DesignSystem.Sizes.labelText - 2))
                .foregroundStyle(themeManager.currentTheme.primaryGradient)
                .padding(.top, DesignSystem.Spacing.small)
            
            // 纯色区域
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.tiny) {
                Text("纯色")
                    .font(DesignSystem.Fonts.labelText(size: DesignSystem.Sizes.labelText - 4))
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 5), spacing: 4) {
                    ForEach(solidColorThemes, id: \.id) { theme in
                        ColorThemeButton(
                            theme: theme, 
                            isSelected: themeManager.currentTheme == theme,
                            isLocked: !purchaseManager.isThemeUnlocked(theme)
                        ) {
                            if purchaseManager.isThemeUnlocked(theme) {
                                selectTheme(theme)
                            } else {
                                selectedLockedTheme = theme
                                showPurchaseAlert = true
                            }
                        }
                    }
                }
            }
            
            // 渐变色区域
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.tiny) {
                Text("渐变色")
                    .font(DesignSystem.Fonts.labelText(size: DesignSystem.Sizes.labelText - 4))
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 5), spacing: 4) {
                    ForEach(gradientColorThemes, id: \.id) { theme in
                        ColorThemeButton(
                            theme: theme, 
                            isSelected: themeManager.currentTheme == theme,
                            isLocked: !purchaseManager.isThemeUnlocked(theme)
                        ) {
                            if purchaseManager.isThemeUnlocked(theme) {
                                selectTheme(theme)
                            } else {
                                selectedLockedTheme = theme
                                showPurchaseAlert = true
                            }
                        }
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .padding(.top, DesignSystem.Spacing.tiny)
    }
    
    /// 纯色主题列表
    private var solidColorThemes: [DesignSystem.ColorTheme] {
        [.black, .orange, .red, .green, .blue, .indigo, .purple, .pink, .brown, .gray]
    }
    
    /// 渐变主题列表
    private var gradientColorThemes: [DesignSystem.ColorTheme] {
        [.navyPurple, .sunset, .ocean, .forest, .rose, .galaxy, .mint, .fire, .sky, .lavender,
         .deepNight, .darkForest, .charcoal, .deepOcean, .darkBerry, .shadowGreen, .darkRose, .midnight, .darkAmber, .steelGray]
    }
    
    /// 选择主题
    private func selectTheme(_ theme: DesignSystem.ColorTheme) {
        HapticHelper.shared.selectionImpact()
        themeManager.currentTheme = theme
        
        // 播报选择的主题
        SpeechHelper.shared.speak("已选择\(theme.name)主题")
        
        // 选择后自动收起面板
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                colorThemeState.isExpanded = false
            }
        }
    }
    
    /// 处理主题购买
    private func handlePurchaseTheme(_ theme: DesignSystem.ColorTheme) {
        let productIdentifier: PurchaseManager.ProductIdentifier
        
        if theme.isGradient {
            productIdentifier = .gradientColors
        } else {
            productIdentifier = .solidColors
        }
        
        purchaseManager.purchase(productIdentifier) { success in
            if success {
                // 购买成功后自动选择该主题
                self.selectTheme(theme)
            }
            self.selectedLockedTheme = nil
        }
    }
    
    /// 获取购买提示信息
    private func getPurchaseMessage(for theme: DesignSystem.ColorTheme) -> String {
        if theme.isGradient {
            let price = purchaseManager.getPriceString(for: .gradientColors)
            return "解锁\(theme.name)主题需要购买渐变主题包(\(price))，将解锁所有渐变色主题。"
        } else {
            let price = purchaseManager.getPriceString(for: .solidColors)
            return "解锁\(theme.name)主题需要购买纯色主题包(\(price))，将解锁除黑色外的所有纯色主题。"
        }
    }
}

/// 单个颜色主题按钮
struct ColorThemeButton: View {
    let theme: DesignSystem.ColorTheme
    let isSelected: Bool
    let isLocked: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            RoundedRectangle(cornerRadius: 8)
                .fill(isLocked ? LinearGradient(colors: [.gray.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing) : theme.primaryGradient)
                .frame(width: 32, height: 32)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isSelected ? Color.primary : Color.clear,
                            lineWidth: isSelected ? 2 : 0
                        )
                )
                .overlay(
                    // 选中标记或锁定标记
                    Group {
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .background(Circle().fill(Color.black.opacity(0.7)).frame(width: 16, height: 16))
                        } else if isLocked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .background(Circle().fill(Color.black.opacity(0.7)).frame(width: 16, height: 16))
                        }
                    }
                )
                .scaleEffect(isPressed ? 0.9 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .accessibilityLabel(theme.name)
        .accessibilityHint(isLocked ? "需要购买解锁\(theme.name)主题" : "选择\(theme.name)主题")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

#if DEBUG
struct ColorThemePicker_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ColorThemeToggleButton()
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
    }
}
#endif