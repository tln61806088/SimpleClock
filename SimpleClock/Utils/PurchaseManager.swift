import Foundation
import StoreKit

/// 内购管理器，处理主题解锁的购买逻辑
class PurchaseManager: NSObject, ObservableObject {
    
    static let shared = PurchaseManager()
    
    // MARK: - Published Properties
    
    @Published var isLoading = false
    @Published var purchaseError: String?
    @Published var availableProducts: [SKProduct] = []
    
    // MARK: - Private Properties
    
    private var productsRequest: SKProductsRequest?
    private var purchaseCompletionHandler: ((Bool) -> Void)?
    
    // MARK: - Product Identifiers
    
    enum ProductIdentifier: String, CaseIterable {
        case solidColors = "com.simpleclock.solid_colors"      // 纯色主题包 9.9元
        case gradientColors = "com.simpleclock.gradient_colors" // 渐变主题包 15.9元
        case allThemes = "com.simpleclock.all_themes"          // 全部主题包 19.9元
        
        var displayName: String {
            switch self {
            case .solidColors:
                return "纯色主题包"
            case .gradientColors:
                return "渐变主题包"
            case .allThemes:
                return "全部主题"
            }
        }
        
        var description: String {
            switch self {
            case .solidColors:
                return "解锁除黑色外的所有纯色主题"
            case .gradientColors:
                return "解锁所有渐变色主题"
            case .allThemes:
                return "解锁全部主题，享受最大优惠"
            }
        }
    }
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        SKPaymentQueue.default().add(self)
        loadProducts()
    }
    
    deinit {
        SKPaymentQueue.default().remove(self)
    }
    
    // MARK: - Public Methods
    
    /// 检查指定主题是否已解锁
    func isThemeUnlocked(_ theme: DesignSystem.ColorTheme) -> Bool {
        // 黑色主题永远免费
        if theme == .black {
            return true
        }
        
        // 检查是否购买了全部主题包
        if isPurchased(.allThemes) {
            return true
        }
        
        // 检查纯色主题
        if !theme.isGradient && isPurchased(.solidColors) {
            return true
        }
        
        // 检查渐变主题
        if theme.isGradient && isPurchased(.gradientColors) {
            return true
        }
        
        return false
    }
    
    /// 购买指定产品
    func purchase(_ productIdentifier: ProductIdentifier, completion: @escaping (Bool) -> Void) {
        guard let product = availableProducts.first(where: { $0.productIdentifier == productIdentifier.rawValue }) else {
            completion(false)
            return
        }
        
        purchaseCompletionHandler = completion
        isLoading = true
        purchaseError = nil
        
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    /// 恢复购买
    func restorePurchases(completion: @escaping (Bool) -> Void) {
        isLoading = true
        purchaseError = nil
        purchaseCompletionHandler = completion
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    /// 获取产品价格字符串
    func getPriceString(for productIdentifier: ProductIdentifier) -> String {
        guard let product = availableProducts.first(where: { $0.productIdentifier == productIdentifier.rawValue }) else {
            return "获取价格中..."
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceLocale
        return formatter.string(from: product.price) ?? "¥\(product.price)"
    }
    
    // MARK: - Private Methods
    
    /// 加载可购买产品
    private func loadProducts() {
        let productIdentifiers = Set(ProductIdentifier.allCases.map { $0.rawValue })
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productsRequest?.delegate = self
        productsRequest?.start()
    }
    
    /// 检查是否已购买指定产品
    private func isPurchased(_ productIdentifier: ProductIdentifier) -> Bool {
        return UserDefaults.standard.bool(forKey: "purchased_\(productIdentifier.rawValue)")
    }
    
    /// 保存购买状态
    private func savePurchaseState(_ productIdentifier: ProductIdentifier) {
        UserDefaults.standard.set(true, forKey: "purchased_\(productIdentifier.rawValue)")
        UserDefaults.standard.synchronize()
    }
    
    /// 处理购买成功
    private func handleSuccessfulPurchase(_ productIdentifier: String) {
        guard let identifier = ProductIdentifier(rawValue: productIdentifier) else { return }
        
        savePurchaseState(identifier)
        
        DispatchQueue.main.async {
            self.isLoading = false
            self.purchaseCompletionHandler?(true)
            self.purchaseCompletionHandler = nil
            
            // 播报购买成功
            //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            // 语音播报内容："购买成功，[产品名称]已解锁" (第157行)
            //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            SpeechHelper.shared.speak("购买成功，\(identifier.displayName)已解锁")
        }
    }
    
    /// 处理购买失败
    private func handleFailedPurchase(_ error: Error?) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.purchaseError = error?.localizedDescription ?? "购买失败"
            self.purchaseCompletionHandler?(false)
            self.purchaseCompletionHandler = nil
            
            // 播报购买失败
            //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            // 语音播报内容："购买失败，请稍后重试" (第170行)
            //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            SpeechHelper.shared.speak("购买失败，请稍后重试")
        }
    }
}

// MARK: - SKProductsRequestDelegate

extension PurchaseManager: SKProductsRequestDelegate {
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        DispatchQueue.main.async {
            self.availableProducts = response.products
            print("已加载 \(response.products.count) 个可购买产品")
            
            // 打印无效产品标识符
            for invalidIdentifier in response.invalidProductIdentifiers {
                print("无效产品标识符: \(invalidIdentifier)")
            }
        }
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        DispatchQueue.main.async {
            print("产品请求失败: \(error.localizedDescription)")
            self.purchaseError = "无法加载产品信息: \(error.localizedDescription)"
        }
    }
}

// MARK: - SKPaymentTransactionObserver

extension PurchaseManager: SKPaymentTransactionObserver {
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                handleSuccessfulPurchase(transaction.payment.productIdentifier)
                SKPaymentQueue.default().finishTransaction(transaction)
                
            case .failed:
                handleFailedPurchase(transaction.error)
                SKPaymentQueue.default().finishTransaction(transaction)
                
            case .restored:
                handleSuccessfulPurchase(transaction.payment.productIdentifier)
                SKPaymentQueue.default().finishTransaction(transaction)
                
            case .deferred, .purchasing:
                // 等待中或购买中，不需要处理
                break
                
            @unknown default:
                break
            }
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        handleFailedPurchase(error)
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.purchaseCompletionHandler?(true)
            self.purchaseCompletionHandler = nil
            
            // 播报恢复成功
            //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            // 语音播报内容："购买记录已恢复" (第239行)
            //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            SpeechHelper.shared.speak("购买记录已恢复")
        }
    }
}