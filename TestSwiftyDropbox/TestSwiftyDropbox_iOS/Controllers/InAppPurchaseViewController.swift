//
//  InAppPurchaseViewController.swift
//  GigHard_Swift
//
//  Created by osx on 02/12/19.
//  Copyright © 2019 osx. All rights reserved.
//

import UIKit
import StoreKit

enum FeaturesPurchased:String {
    case All
    case AudioVideo
    case SetLists
    case None
}

class InAppPurchaseViewController: UIViewController , SKPaymentTransactionObserver {

//    MARK: IBOUTLET(S) AND VARIABLE(S)
    @IBOutlet weak var iAPTableView: UITableView!
    @IBOutlet weak var specialOffersBtn: UIButton!
    @IBOutlet weak var appPurchaseBtn: UIButton!
    
    var headerLabel:UILabel!
//    special offers
    var offersArr = [[String:Any]]()
    var offersPriceArr = [499.0,499.0,799.0]
//    my purchases
    var purchasesArr = [[String:Any]]()
    var purchasesItem: [String:Any]!
    
    var isOfferSelected = true
    var isPurchased =  UserDefaults.standard.bool(forKey:  "isPurchased")
    
    var noPurchases = "No purchases found. If you have previously made purchases which do not appear here, tap the Restore button to re-download them"
    var moduleSelected:Int = 0
    var features : FeaturesPurchased = .None
    //MARK: try features
    
//    MARK: VIEW LIFE CYCLE METHOD(S)
    override func viewDidLoad() {
           super.viewDidLoad()
           if let _ = (UserDefaults.standard.array(forKey: "purchasedOffers")){
                 purchasesArr = UserDefaults.standard.array(forKey: "purchasedOffers") as! [[String : Any]]
           }
           if let _ = (UserDefaults.standard.array(forKey: "remainingOffers")){
                 offersArr = UserDefaults.standard.array(forKey: "remainingOffers") as! [[String : Any]]
           }
        
           self.navigationController?.navigationBar.isHidden = true
           self.specialOffersBtn.isHidden = true
           self.iAPTableView.register(UINib(nibName: "InAppPuchaseTableViewCell", bundle: nil), forCellReuseIdentifier: "InAppPuchaseTableViewCellReuse")
        if isPurchased {
//            offersArr = UserDefaults.standard.array(forKey: "remainingOffers") as! [[String : Any]]
        }else{
            offersArr = DatabaseHelper.shareInstance.getDataFromP_list() ?? []
        }
           SKPaymentQueue.default().add(self)
           IAPHandler.shared.fetchAvailableProducts()
           IAPHandler.shared.purchaseStatusBlock = {[weak self] (type) in
               guard let strongSelf = self else{ return }
                   if type == .purchased {
                   let alertView = UIAlertController(title: "", message: type.message(), preferredStyle: .alert)
                   let action = UIAlertAction(title: "OK", style: .default, handler: { (alert) in
                   })
                   alertView.addAction(action)
                   strongSelf.present(alertView, animated: true, completion: nil)
               }
           }
        IAPHandler.shared.delegate = self
       }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let pPListPath = Bundle.main.path(forResource: "PurchasesList", ofType: "plist")
        let arr = NSArray(contentsOfFile: pPListPath!)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
         NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "timeOut"), object: nil)
    }
    //    MARK: METHOD(S)
    
   func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
          for transaction in transactions {
              switch transaction.transactionState {
              case .failed:
                  queue.finishTransaction(transaction)
                  print("Transaction Failed \(transaction)")

              case .purchased:
                  queue.finishTransaction(transaction)
                  print("Transaction purchased or restored: \(transaction)")
                  self.isPurchased = true
                  if purchasesItem != nil{
                  var featureEnabled = ""
                  if let selectedModule = purchasesItem["IAPIdentifierPro"] as? String {
//                  print(moduleSelected)
                   
                    if selectedModule == "03_gig_pro" {
                        offersArr.removeAll()
                        purchasesArr.removeAll()
                        purchasesArr.append(purchasesItem)
                        featureEnabled = "03_gig_pro"
                        features = .All
                    }  else  if selectedModule == "02_gig_pro" {
                        offersArr.remove(at: moduleSelected)
                        purchasesArr.append(purchasesItem)
                        featureEnabled = "02_gig_pro"
                        features = .SetLists
                    }  else  if selectedModule == "01_gig_pro" {
                        offersArr.remove(at: moduleSelected)
                        purchasesArr.append(purchasesItem)
                        featureEnabled = "01_gig_pro"
                        features = .AudioVideo
                    }

//                    print(offersArr)
//                    print(purchasesArr)
                    if purchasesArr.count > 1 {
                        featureEnabled = "03_gig_pro"
                        features = .All
                        offersArr.removeAll()
                    }
                  }
                      UserDefaults.standard.set(purchasesArr, forKey: "purchasedOffers")
                      UserDefaults.standard.set(offersArr, forKey: "remainingOffers")
                      UserDefaults.standard.set(featureEnabled, forKey: "featuresEnabled")
                  }
                  UserDefaults.standard.set(true, forKey: "isPurchased")
                  
                  self.iAPTableView.reloadData()

              case .deferred, .purchasing:
                  print("Transaction in progress: \(transaction)")
                  
              case .restored:
                queue.finishTransaction(transaction)
                 print("resote")
                  break
                  
              }
          }
      }

    func afterIAP() {
        if features == .All {
            self.offersArr.removeAll()
            let allFeatures = DatabaseHelper.shareInstance.getDataFromP_list()
            for item in allFeatures ?? [] {
                let itemId = item["orderNo"]! as! Int
                if itemId == 0 {
                    self.purchasesArr.removeAll()
                    self.purchasesArr.append(item)
                }
            }
        } else if features == .SetLists {
            self.offersArr.removeAll()
            let allFeatures = DatabaseHelper.shareInstance.getDataFromP_list()
            for item in allFeatures ?? [] {
                let itemId = item["orderNo"]! as! Int
                if itemId == 1 {
                    self.purchasesArr.removeAll()
                    self.purchasesArr.append(item)
                } else {
                    self.offersArr.append(item)
                }
            }
        } else if features == .AudioVideo {
            self.offersArr.removeAll()
            let allFeatures = DatabaseHelper.shareInstance.getDataFromP_list()
            for item in allFeatures ?? [] {
                let itemId = item["orderNo"]! as! Int
                if itemId == 2 {
                    self.purchasesArr.removeAll()
                    self.purchasesArr.append(item)
                } else {
                    self.offersArr.append(item)
                }
            }
        } else if features == .None {
            self.offersArr.removeAll()
            let allFeatures = DatabaseHelper.shareInstance.getDataFromP_list()
            self.offersArr = allFeatures ?? []
        }
//        print(offersArr)
//        print(purchasesArr)
        self.iAPTableView.reloadData()
    }
    
    
    //    MARK: IBACTIONS(S)
    @IBAction func doneBtn(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func myPurchasesAction(_ sender: UIButton) {
       isOfferSelected = false
        self.appPurchaseBtn.isHidden = true
        self.specialOffersBtn.isHidden = false
        
//        MARK: Need To Uncomments
        if isPurchased {
            if (UserDefaults.standard.array(forKey: "purchasedOffers")?.isEmpty) != true{
                  purchasesArr = UserDefaults.standard.array(forKey: "purchasedOffers") as! [[String : Any]]
            }
        } else {
            purchasesArr.removeAll()
        }
        DispatchQueue.main.async {
            self.iAPTableView.reloadData()
        }
    }
    func reloadData(_ notification: Notification){
        
    }
    @IBAction func restoreAction(_ sender: UIButton) {
        IAPHandler.shared.restorePurchase()
//        DispatchQueue.main.async {
//            self.iAPTableView.reloadData()
//        }
    }
    
    @IBAction func offersAction(_ sender: UIButton) {
       isOfferSelected = true
        //        MARK: Need To Uncomments
        if isPurchased {
            if (UserDefaults.standard.array(forKey: "remainingOffers")?.isEmpty) != nil{
                  offersArr = UserDefaults.standard.array(forKey: "remainingOffers") as! [[String : Any]]
            }
        } else {
            offersArr = DatabaseHelper.shareInstance.getDataFromP_list() ?? []
        }
        self.specialOffersBtn.isHidden = true
        self.appPurchaseBtn.isHidden = false
        DispatchQueue.main.async {
            self.iAPTableView.reloadData()
        }
    }
    
    @objc func callPurchasingMethod(_ sender: UIButton) {
//        print(purchasesItem)
        let id = "\(purchasesItem["IAPIdentifierPro"] ?? "")"
        IAPHandler.shared.purchaseMyProduct(id: id)
    }
    
}

//    MARK: UITABLEVIEW DATASURCE AND DELEGATE METHODS(S)
extension InAppPurchaseViewController:UITableViewDelegate,UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isOfferSelected {
            if offersArr.count > 0 {
                return offersArr.count
            }else{
                return 0
            }
        } else {
            if purchasesArr.count > 0 {
                return purchasesArr.count
            }else{
                return 1
            }
        }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = iAPTableView.dequeueReusableCell(withIdentifier: "InAppPuchaseTableViewCellReuse", for: indexPath) as! InAppPuchaseTableViewCell
        cell.delegate = self
        if isOfferSelected {
            if offersArr.count > 0 {
                cell.iapLabel.text = offersArr[indexPath.row]["IAPTitle"] as! String
                cell.iconImgView.image = UIImage(named: offersArr[indexPath.row]["IconFileName"] as! String)
                cell.buyBtn.isHidden = false
//                cell.buyBtn.setTitle("$\(offersPriceArr[indexPath.row])", for: .normal)
                cell.buyBtn.setTitle(offersArr[indexPath.row]["itemPrice"] as! String, for: .normal)
                cell.buyBtnWidthConstraint.constant = 60
                cell.indexPath = indexPath.row
                cell.iconImgView.isHidden = false
                cell.iconImgViewWidthContstraint.constant = 50
                cell.buyBtn.tag = indexPath.row
                cell.productAvailable = self.offersArr
//                cell.buyBtn.addTarget(self, action: #selector(self.purchaseProduct), for: .touchUpInside)
                cell.buyBtn.addTarget(self, action: #selector(self.callPurchasingMethod), for: .touchUpInside)
            }
            else {
                //when offersArr nil
            }
        } else {
            if purchasesArr.count > 0{
                cell.iapLabel.text = purchasesArr[indexPath.row]["IAPTitle"] as! String
                cell.iconImgView.image = UIImage(named: purchasesArr[indexPath.row]["IconFileName"] as! String)
                cell.buyBtn.isHidden = true
                cell.buyBtnWidthConstraint.constant = 0
                cell.restoreBtn.isHidden = true
                cell.restoreBtnWidthConstraint.constant = 0
                cell.iconImgView.isHidden = false
                cell.iconImgViewWidthContstraint.constant = 50
            } else {
                cell.iapLabel.text = noPurchases
                cell.buyBtn.isHidden = true
                cell.buyBtnWidthConstraint.constant = 0
                cell.restoreBtn.isHidden = true
                cell.restoreBtnWidthConstraint.constant = 0
                cell.iconImgView.isHidden = true
                cell.iconImgViewWidthContstraint.constant = 0
            }
          
        }
        return cell
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.iAPTableView.frame.size.width, height: 80))
        headerLabel = UILabel(frame: CGRect(x: 0, y: (headerView.frame.size.height - 60) / 2.0, width: headerView.frame.size.width, height: 60))
        headerLabel.font = UIFont.boldSystemFont(ofSize: 34)
        if isOfferSelected {
            headerLabel.text = "Special Offers"
        } else {
            headerLabel.text = "My Purchases"
        }
        headerLabel.textColor = UIColor.darkGray
        headerLabel.textAlignment = .center
        headerView.backgroundColor = .clear
        headerView.addSubview(headerLabel)
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if !isOfferSelected {
            if purchasesArr.count == 0 {
                return 0
            }
        }
        return 80.0
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.moduleSelected = indexPath.row
    }
}

extension InAppPurchaseViewController: PurchasingDataDelegate {
    func purchaseProduct(purchasesProduct: [String : Any], index: Int) {
        self.purchasesItem = purchasesProduct
        self.moduleSelected = index
    }
}

extension InAppPurchaseViewController: IAPHandlerDelegate {
    func purchasesItemArr(purchasesItem: [String]) {

        if offersArr.count == 0 {
            return
        }
        
        var featureEnabled = ""
        for item in purchasesItem {
            let selectedModule = item as! String
            for index in 0...offersArr.count - 1 {
                if selectedModule == offersArr[index]["IAPIdentifierPro"] as! String {
//                    print(selectedModule)
                    purchasesArr.removeAll()
                    purchasesArr.append(offersArr[index])
                    featureEnabled = selectedModule
                    if selectedModule == "03_gig_pro" {
                        featureEnabled = "03_gig_pro"
                        features = .All
                    }  else  if selectedModule == "02_gig_pro" {
                        featureEnabled = "02_gig_pro"
                        features = .SetLists
                    }  else  if selectedModule == "01_gig_pro" {
                        
                        featureEnabled = "01_gig_pro"
                        features = .AudioVideo
                    }
                }
            }
        }
        if purchasesArr.count > 1 {
            featureEnabled = "03_gig_pro"
            features = .All
            offersArr.removeAll()
        }
        
//        print(featureEnabled)
        
        if featureEnabled == "01_gig_pro" {
            self.offersArr.removeAll()
            let allFeatures = DatabaseHelper.shareInstance.getDataFromP_list()
            for item in allFeatures ?? [] {
                let itemId = item["orderNo"]! as! Int
                if itemId == 2 {

                } else {
                    self.offersArr.append(item)
                }
            }
        } else if featureEnabled == "02_gig_pro" {
            self.offersArr.removeAll()
            let allFeatures = DatabaseHelper.shareInstance.getDataFromP_list()
            for item in allFeatures ?? [] {
                let itemId = item["orderNo"]! as! Int
                if itemId == 1 {

                } else {
                    self.offersArr.append(item)
                }
            }
        } else if featureEnabled == "03_gig_pro" {
            self.offersArr.removeAll()
            let allFeatures = DatabaseHelper.shareInstance.getDataFromP_list()
            for item in allFeatures ?? [] {
                let itemId = item["orderNo"]! as! Int
                if itemId == 0 {

                }
            }
        }
        
//        print(purchasesArr)
//        print(offersArr)
        UserDefaults.standard.set(purchasesArr, forKey: "purchasedOffers")
        UserDefaults.standard.set(offersArr, forKey: "remainingOffers")
        UserDefaults.standard.set(featureEnabled, forKey: "featuresEnabled")
        
        UserDefaults.standard.set(true, forKey: "isPurchased")
        
        self.isPurchased =  UserDefaults.standard.bool(forKey: "isPurchased")
        self.purchasesArr = UserDefaults.standard.array(forKey: "purchasedOffers") as! [[String : Any]]
        self.offersArr = UserDefaults.standard.array(forKey: "remainingOffers") as! [[String : Any]]
        DispatchQueue.main.async {
            self.iAPTableView.reloadData()
        }
    }
    
}


