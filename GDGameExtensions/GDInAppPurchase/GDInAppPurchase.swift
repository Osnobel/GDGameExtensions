//
//  GDInAppPurchase.swift
//  GDInAppPurchase
//
//  Created by Bell on 16/5/28.
//  Copyright © 2016年 GoshDo <http://goshdo.sinaapp.com>. All rights reserved.
//

import Foundation
import StoreKit

public extension SKProduct {
    public var localizedPrice: String {
        get {
            let numberFormatter = NSNumberFormatter()
            numberFormatter.formatterBehavior = .Behavior10_4
            numberFormatter.numberStyle = .CurrencyStyle
            numberFormatter.locale = self.priceLocale
            return numberFormatter.stringFromNumber(self.price)!
        }
    }
    
    override public var description: String {
        get {
            return "Identifier=\(self.productIdentifier) Price=\(self.localizedPrice) Title=\(self.localizedTitle) Description=\(self.localizedDescription)"
        }
    }
}

public class GDProductStore: NSObject, SKProductsRequestDelegate {
    public var loaded: Bool {
        get {
            return _loaded
        }
    }
    private var _loaded: Bool = true {
        didSet {
            if _loaded == oldValue {
                return
            }
            if _loaded {
                LoadingAnimate.stop()
            } else {
                LoadingAnimate.start()
            }
        }
    }
    private var _store: [String : SKProduct] = [:]
    private var _completionHanlder:((SKProduct?, NSError?) -> Void)? = nil
    
    public func preloadProducts(productIdentifiers: Set<String> = []) {
        let request = SKProductsRequest(productIdentifiers: productIdentifiers)
        request.delegate = self
        request.start()
    }
    
    public func product(productIdentifier: String, completionHandler handler: ((SKProduct?, NSError?) -> Void)?) {
        guard handler != nil else { return }
        _completionHanlder = handler
        if let product = _store[productIdentifier] {
            _completionHanlder!(product, nil)
        } else {
            let productIdentifiers:Set<String> = [productIdentifier]
            let request = SKProductsRequest(productIdentifiers: productIdentifiers)
            request.delegate = self
            request.start()
            _loaded = false
        }
    }
    
    public func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
        _loaded = true
        var error: NSError? = nil
        if !response.invalidProductIdentifiers.isEmpty {
            print("Invalid Product ID: \(response.invalidProductIdentifiers)")
            error = NSError(domain: "com.inapppurchase.productstore.invalidproductidentifiers", code: -1, userInfo: [NSLocalizedDescriptionKey:"Invalid Product IDs: \(response.invalidProductIdentifiers)"])
        }
        let products = response.products
        for product in products {
            _store[product.productIdentifier] = product
        }
        if _completionHanlder != nil {
            if products.count == 1 && error == nil {
                _completionHanlder!(products[0], error)
            } else {
                _completionHanlder!(nil, error)
            }
            _completionHanlder = nil
        }
    }
    
    public func request(request: SKRequest, didFailWithError error: NSError) {
        _loaded = true
        if _completionHanlder != nil {
            _completionHanlder!(nil, error)
            _completionHanlder = nil
        }
    }
}

public extension SKPayment {
    override public var description: String {
        get {
            return "Identifier=\(self.productIdentifier) Quantity=\(self.quantity)"
        }
    }
}

public extension SKPaymentTransaction {
    public var receipt: String? {
        get {
            guard let url = NSBundle.mainBundle().appStoreReceiptURL else { return nil }
            return NSData(contentsOfURL: url)?.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
        }
    }
    
    override public var description: String {
        get {
            var _desc = ""
            switch self.transactionState {
            case .Purchased, .Restored:
                _desc += "Identifier=\(self.transactionIdentifier!)"
            default:
                _desc += "Identifier=Invalid Transaction Identifier"
            }
            switch self.transactionState {
            case .Purchased:
                _desc += " State=Purchased"
            case .Purchasing:
                _desc += " State=Purchasing"
            case .Failed:
                _desc += " State=Failed"
            case .Restored:
                _desc += " State=Restored"
            default:
                _desc += " State=\(self.transactionState.rawValue)"
            }
            _desc += " Payment={\(self.payment)}"
            if self.error != nil {
                _desc += " Error={\(self.error!)}"
            }
            return _desc
        }
    }
}

public class GDPayment: NSObject, SKPaymentTransactionObserver {
    // Singleton
    public static func sharedPayment() -> GDPayment {
        return _sharedInstance
    }
    private static let _sharedInstance = GDPayment()
    private override init() { super.init() }
    // Singleton end
    public var loaded: Bool {
        get {
            return _loaded
        }
    }
    public var productStore: GDProductStore = GDProductStore()
    
    private var _loaded: Bool = true {
        didSet {
            if _loaded == oldValue {
                return
            }
            if _loaded {
                LoadingAnimate.stop()
            } else {
                LoadingAnimate.start()
            }
        }
    }
    private var _completedTransactionHandler:((SKPaymentTransaction?, NSError?) -> Void)? = nil
    
    public func purchase(productIdentifier: String, completedTransactionHandler handler:((SKPaymentTransaction?, NSError?) -> Void)?) {
        purchase(productIdentifier, quantity: 1, completedTransactionHandler: handler)
    }
    
    public func purchase(productIdentifier: String, quantity: Int, completedTransactionHandler handler:((SKPaymentTransaction?, NSError?) -> Void)?) {
        _completedTransactionHandler = handler
        guard SKPaymentQueue.canMakePayments() else {
            let error = NSError(domain: "com.inapppurchase.payment.cannotmakepayments", code: -2, userInfo: [NSLocalizedDescriptionKey:"In-App Purchase Disable"])
            _completedTransactionHandler?(nil, error)
            return
        }
        productStore.product(productIdentifier) { (product, error) -> Void in
            if error != nil {
                return
            }
            if product != nil {
                SKPaymentQueue.defaultQueue().addTransactionObserver(self)
                let payment = SKMutablePayment(product: product!)
                if quantity > 1 {
                    payment.quantity = quantity
                }
                SKPaymentQueue.defaultQueue().addPayment(payment)
                self._loaded = false
            }
        }
    }
    
    public func restore(completedTransactionHandler handler:((SKPaymentTransaction?, NSError?) -> Void)?) {
        _completedTransactionHandler = handler
        guard SKPaymentQueue.canMakePayments() else {
            let error = NSError(domain: "com.inapppurchase.payment.cannotmakepayments", code: -2, userInfo: [NSLocalizedDescriptionKey:"In-App Purchase Disable"])
            _completedTransactionHandler?(nil, error)
            return
        }
        SKPaymentQueue.defaultQueue().addTransactionObserver(self)
        SKPaymentQueue.defaultQueue().restoreCompletedTransactions()
        _loaded = false
    }
    
    public func verifyReceipt(transaction:SKPaymentTransaction, completedHandler handler:((NSError?) -> Void)) {
        guard let receiptString = transaction.receipt else {
            let error = NSError(domain: "com.inapppurchase.payment.transactionreceiptempty", code: -3, userInfo: [NSLocalizedDescriptionKey:"In-App Purchase Transaction Receipt is Empty"])
            handler(error)
            return
        }
        postVerifyReceiptRequest(receiptString, completedHandler: handler)
        _loaded = false
    }
    
    private func postVerifyReceiptRequest(receipt: String, isSandbox: Bool = false, completedHandler handler:((NSError?) -> Void)) {
        let httpBodyString = "{\"receipt-data\" : \"\(receipt)\"}"
        var verifyReceiptURL = NSURL(string: "https://buy.itunes.apple.com/verifyReceipt")!
        if isSandbox {
            verifyReceiptURL = NSURL(string: "https://sandbox.itunes.apple.com/verifyReceipt")!
        }
        let request = NSMutableURLRequest(URL: verifyReceiptURL)
        request.HTTPMethod = "POST"
        request.HTTPBody = httpBodyString.dataUsingEncoding(NSUTF8StringEncoding)
        let session = NSURLSession(configuration: NSURLSessionConfiguration.ephemeralSessionConfiguration())
        let task = session.dataTaskWithRequest(request) { (data, response, error) -> Void in
            self._loaded = true
            guard error == nil else {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    handler(error)
                })
                return
            }
            guard let validData = data where validData.length > 0 else {
                // print("JSON could not be serialized. Input data was nil or zero length.")
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    let error = NSError(domain: "com.inapppurchase.payment.transactionreceiptemptyverifyfailed", code: -4, userInfo: [NSLocalizedDescriptionKey:"In-App Purchase Transaction Receipt Verify Failed"])
                    handler(error)
                })
                return
            }
            print(String(data: validData, encoding: NSUTF8StringEncoding)!)
            do {
                let JSON = try NSJSONSerialization.JSONObjectWithData(validData, options: .AllowFragments)
                if let result = JSON as? [String: AnyObject] {
                    let status = result["status"] as? Int
                    if status == 21007 {
                        self._loaded = false
                        self.postVerifyReceiptRequest(receipt, isSandbox: true, completedHandler: handler)
                    } else if let receipt = result["receipt"] as? [String: AnyObject] where receipt["bundle_id"] as? String == NSBundle.mainBundle().bundleIdentifier && status == 0 {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            handler(nil)
                        })
                    } else {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            let error = NSError(domain: "com.inapppurchase.payment.transactionreceiptemptyverifyfailed", code: -4, userInfo: [NSLocalizedDescriptionKey:"In-App Purchase Transaction Receipt Verify Failed"])
                            handler(error)
                        })
                    }
                } else {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        let error = NSError(domain: "com.inapppurchase.payment.transactionreceiptemptyverifyfailed", code: -4, userInfo: [NSLocalizedDescriptionKey:"In-App Purchase Transaction Receipt Verify Failed"])
                        handler(error)
                    })
                }
                return
            } catch let e as NSError {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    handler(e)
                })
                return
            }
        }
        task.resume()
        session.finishTasksAndInvalidate()
    }
    
    private func purchasedTransaction(transaction:SKPaymentTransaction) {
        defer {
            SKPaymentQueue.defaultQueue().finishTransaction(transaction)
        }
        _completedTransactionHandler?(transaction, nil)
    }
    
    private func restoredTransaction(transaction:SKPaymentTransaction) {
        defer {
            SKPaymentQueue.defaultQueue().finishTransaction(transaction)
        }
        _completedTransactionHandler?(transaction, nil)
    }
    
    private func failedTransaction(transaction:SKPaymentTransaction) {
        defer {
            SKPaymentQueue.defaultQueue().finishTransaction(transaction)
        }
        _completedTransactionHandler?(transaction, transaction.error)
    }
    
    // <SKPaymentTransactionObserver> methods
    public func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .Purchased:
                purchasedTransaction(transaction)
            case .Restored:
                restoredTransaction(transaction)
            case .Failed:
                failedTransaction(transaction)
            default:
                //.Purchasing or .Deferred
                break
            }
        }
    }
    
    public func paymentQueue(queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
        _loaded = true
        defer {
            queue.removeTransactionObserver(self)
            _completedTransactionHandler = nil
        }
    }
    
    public func paymentQueue(queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: NSError) {
        _loaded = true
        defer {
            queue.removeTransactionObserver(self)
            _completedTransactionHandler = nil
        }
        _completedTransactionHandler?(nil, error)
    }
    
    public func paymentQueueRestoreCompletedTransactionsFinished(queue: SKPaymentQueue) {
        _loaded = true
        defer {
            queue.removeTransactionObserver(self)
            _completedTransactionHandler = nil
        }
    }
    
    public func paymentQueue(queue: SKPaymentQueue, updatedDownloads downloads: [SKDownload]) {
        _loaded = true
        defer {
            queue.removeTransactionObserver(self)
            _completedTransactionHandler = nil
        }
    }
}

public class LoadingAnimate {
    private static var _view: UIView?
    private static let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
    private static var animateView: UIView {
        get {
            if _view == nil {
                _view = UIView()
                _view!.backgroundColor = UIColor(red:0, green:0, blue:0, alpha: 0.8)
                _view!.addSubview(activityIndicatorView)
            }
            return _view!
        }
    }
    private static var rootView: UIView?
    private static var rootViewUserInteractionEnabled = false
    
    public static func start() {
        rootView = UIApplication.sharedApplication().keyWindow?.subviews.first
        if rootView != nil {
            let width = min(rootView!.frame.size.width, rootView!.frame.size.height)
            animateView.frame = CGRectMake(0, 0, width / 5, width / 5)
            animateView.center = CGPointMake(rootView!.bounds.size.width / 2, rootView!.bounds.size.height / 2)
            animateView.layer.cornerRadius = width / 30
            
            activityIndicatorView.center = CGPointMake(animateView.bounds.size.width / 2, animateView.bounds.size.height / 2)
            activityIndicatorView.startAnimating()
            
            rootView!.addSubview(animateView)
            
            rootViewUserInteractionEnabled = rootView!.userInteractionEnabled
            rootView!.userInteractionEnabled = false
        }
        
    }
    
    public static func stop() {
        activityIndicatorView.stopAnimating()
        animateView.removeFromSuperview()
        rootView?.userInteractionEnabled = rootViewUserInteractionEnabled
    }
}