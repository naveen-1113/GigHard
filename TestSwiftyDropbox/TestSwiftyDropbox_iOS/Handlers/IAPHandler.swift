//
//  IAPHandler.swift
//  Note
//
//  Created by osx on 04/12/19.
//  Copyright © 2019 example. All rights reserved.
//

import Foundation
import StoreKit


protocol IAPHandlerDelegate {
    func purchasesItemArr(purchasesItem: [String])
}

enum IAPAHandlerAlertType{
    case disabled
    case restored
    case purchased
    
    func message() -> String{
        switch self{
        case .disabled: return "Purchases are disabled in your device"
        case .restored: return "You have successfully restored your purchase!"
        case .purchased: return "You have succesfully bought the purchase!"
        }
    }
}

class IAPHandler: NSObject {
    
    static let shared = IAPHandler()
    let window =  UIApplication.shared.keyWindow
    public var sharedSecret = "37502c555d0f48a98f0582e954993752"
    var productIDs = ["01_gig_pro","02_gig_pro","03_gig_pro"]
    fileprivate var product_id = "com.paragoni.gig"
    fileprivate var productsRequest = SKProductsRequest()
    var iapProducts = [SKProduct]()
    var itemIndex : Int?
    var restoreDataArr = [String]()
    var delegate:IAPHandlerDelegate?
    var purchaseStatusBlock: ((IAPAHandlerAlertType) -> Void)?
    //Mark: - Make Purchase of a Product
    
    func canMakePurchases() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    func purchaseMyProduct(id: String)
    {
        if iapProducts.count == 0
        {
            return
        }
        
        if self.canMakePurchases()
        {
            if id == "01_gig_pro"
            {
                itemIndex = 0
            }
            else if id == "02_gig_pro"
            {
                itemIndex = 1
            } else if id == "03_gig_pro"
            {
                itemIndex = 2
            }
            guard let index = itemIndex else {
                return
            }
              let product = iapProducts[index]
              let payment = SKPayment(product: product)
              SKPaymentQueue.default().add(self)
              SKPaymentQueue.default().add(payment)
              product_id = product.productIdentifier

        }
        else
        {
            purchaseStatusBlock!(.disabled)
        }
    }
    // Mark:- Restore Purchase
    
    func restorePurchase()
    {
        if self.canMakePurchases()
        {
            SKPaymentQueue.default().add(self)
            SKPaymentQueue.default().restoreCompletedTransactions()
           //paymentQueue( SKPaymentQueue.default(), updatedTransactions: [.init()])
        }
        else
        {
            
        }
    }

    // Mark:- Fetch available IAP Products
    func fetchAvailableProducts()
    {
        let productIdentifiers = Set(productIDs)
        
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers )
        productsRequest.delegate = self
        productsRequest.start()
    }
    func receiptValidation() {
            let SUBSCRIPTION_SECRET = "37502c555d0f48a98f0582e954993752"
            let receiptPath = Bundle.main.appStoreReceiptURL?.path
            //print(Bundle.main.appStoreReceiptURL)
            
            if FileManager.default.fileExists(atPath: receiptPath!){
                var receiptData:NSData?
                do{
                    receiptData = try NSData(contentsOf: Bundle.main.appStoreReceiptURL!, options: NSData.ReadingOptions.alwaysMapped)
                    print(receiptData)
                }
                catch{
                    print("ERROR: " + error.localizedDescription)
                }
                
                let base64encodedReceipt = receiptData?.base64EncodedString(options: NSData.Base64EncodingOptions.endLineWithCarriageReturn)
 
                let requestDictionary = ["receipt-data":base64encodedReceipt!,"password":SUBSCRIPTION_SECRET, "exclude-old-transactions" : "false"]
                
                
                //print(requestDictionary)
                guard JSONSerialization.isValidJSONObject(requestDictionary) else {  print("requestDictionary is not valid JSON");  return }
                do {
                    let requestData = try JSONSerialization.data(withJSONObject: requestDictionary)
                    let myID = "\(UserDefaults.standard.value(forKey: "owner_id") as! String)"
                    
                    
                    let jsonStringSize = String(data: requestData, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))!
                    
//                    let baseStringSize = jsonStringSize.base64Encoded()
//
//
//                    let baseUrl = "\(alertManager.callAlert.baseURL)/save_token_latest_102"
//                    let requestDict = NSMutableDictionary()
//                    requestDict.setValue("\(myID)", forKey: "user_id")
//                     requestDict.setValue("ios", forKey: "device_type")
//                    // requestDict.setValue("0", forKey: "token")
//                    requestDict.setValue(baseStringSize, forKey: "token")
//                     requestDict.setValue("\(selectedPackage)", forKey: "pck_id")
//                    print(requestDict)
//                    apiManager.callApi.postRequest(method: baseUrl, parameters: requestDict, completionHandler: { (response, status) in
//                        //print(response)
//                    })
                    
    //                apiManager.callApi.sendRequest(parameters: requestDict, method: "save_token", containArray: false, success:{(response) in
    //
    //                    print(response)
    //
    //                } )
                    
                }catch let error as NSError {
                    print("json serialization failed with error: \(error)")
                }
        }
        }
    // MARK: Custom method implementation
    
    func requestProductInfo() {
        if SKPaymentQueue.canMakePayments() {
            let productIdentifiers = NSSet(array: productIDs)
            let productRequest = SKProductsRequest(productIdentifiers: productIdentifiers as! Set<NSObject> as! Set<String>)
            
            productRequest.delegate = self
            productRequest.start()
        }
        else {
            print("Cannot perform In App Purchases.")
        }
    }
}

extension IAPHandler: SKProductsRequestDelegate, SKPaymentTransactionObserver
{
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        print(response.products)
        if response.products.count > 0
        {
            iapProducts = response.products
            for product in iapProducts
            {
                let numberFormatter = NumberFormatter()
                numberFormatter.formatterBehavior = .behavior10_4
                numberFormatter.numberStyle = .currency
                numberFormatter.locale = product.priceLocale
                let price1Str = numberFormatter.string(from: product.price)
                print(price1Str)
                //  print(product.localizedDescription + "\n for just \(price1Str)")
                
            }
        }
    }
  
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        if queue.transactions.count == 0
        {
//            NotificationCenter.default.post(name: .noPurchase, object: nil)
        }
        else
        {
            if self.restoreDataArr.count > 0 {
                self.delegate?.purchasesItemArr(purchasesItem: self.restoreDataArr)
            }
        }
    }

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        
        var sortedArray = [SKPaymentTransaction]()
        //        for transaction: AnyObject in transactions
        //        {
        if transactions.count > 1
        {
            sortedArray = transactions.sorted {  ($0 ).transactionDate! > ($1 ).transactionDate!}
        }
        else if transactions.count == 1
        {
            sortedArray = transactions
        }
        //}
        if let trans = sortedArray[0] as? SKPaymentTransaction//transaction as? SKPaymentTransaction
        {
            
            switch trans.transactionState
            {
            case .purchased:
                print("purchased")
                if trans.payment.productIdentifier == "01_gig_pro"
                {
                    print(trans.payment.productIdentifier)
//                    selectedPackage = 1
                }
                else if trans.payment.productIdentifier == "02_gig_pro"
                {
                    print(trans.payment.productIdentifier)
//                    selectedPackage = 2
                }
                else if trans.payment.productIdentifier == "03_gig_pro"
                {
                    print(trans.payment.productIdentifier)
//                    selectedPackage = 3
                }
                SKPaymentQueue.default().finishTransaction(trans)
                 
//                NotificationCenter.default.post(name: .payment, object: nil)
                
                break
                
            case .failed:
                print("failed")
//                NotificationCenter.default.post(name: .failed, object: nil)
                SKPaymentQueue.default().finishTransaction(trans)
                break
                
            case .restored:
                
                //let latestTrans = sortedArray[sortedArray.count - 1]
                
                if transactions.count > 0
                {
                    if trans.payment.productIdentifier == "01_gig_pro"
                    {
                        print("01_gig_pro")
                        restoreDataArr.append("01_gig_pro")

                    }
                    if trans.payment.productIdentifier == "02_gig_pro"
                    {
                        print("02_gig_pro")
                       restoreDataArr.append("02_gig_pro")
                    }
                     if trans.payment.productIdentifier == "03_gig_pro"
                    {
                        print("03_gig_pro")
                      restoreDataArr.append("03_gig_pro")
                    }
                    
//                    Restore_receipt()
                    print(restoreDataArr)
                    SKPaymentQueue.default().finishTransaction(trans)
                    //NotificationCenter.default.post(name: .payment, object: nil)
                }
                else
                {
//                    NotificationCenter.default.post(name: .noPurchase, object: nil)
                }
                break
                
            case .deferred:
                print("deferred")
//                NotificationCenter.default.post(name: .payment, object: nil)
                break
                
            case .purchasing:
                print("purchasing")
                
                //NotificationCenter.default.post(name: .payment, object: nil)
                break
                
            default: break
            }
        }
    }
    
   
}

