//
//  EditViewController.swift
//  GigHard_Swift
//
//  Created by osx on 26/11/19.
//  Copyright © 2019 osx. All rights reserved.
//

import UIKit
import MessageUI
import NotificationCenter
import SwiftyDropbox
import CoreData
import CloudKit
import MBProgressHUD

class EditViewController: UIViewController{
//    MARK:- IBOUTLET(S)
    
    @IBOutlet weak var editorContainerView: UIView!
    @IBOutlet weak var docTitleLbl: UILabel!
    @IBOutlet weak var documentTxtView: BSHighlightableTextView!
    @IBOutlet weak var prompsterLogoImgView: UIImageView!
    @IBOutlet weak var myDocsBtnOutlet: UIButton!
    @IBOutlet weak var settingsPageBtnOutlet: UIButton!
    @IBOutlet weak var doneBtnOutlet: UIButton!
    @IBOutlet weak var shareBtnOutlet: UIButton!
    @IBOutlet weak var IAPBtnOutlet: UIButton!
    @IBOutlet weak var decreaseFontBtnOutlet: UIButton!
    @IBOutlet weak var increaseFontBtnOutlet: UIButton!
    @IBOutlet weak var promptBtnOutlet: UIButton!
    @IBOutlet weak var importBtnOutlet: UIButton!
    @IBOutlet weak var exportBtnOutlet: UIButton!
    @IBOutlet weak var noDocumentSeletedLbl: UILabel!
    @IBOutlet weak var adViewOutlet: UIView!
    @IBOutlet weak var formatBarView: UIView!
    @IBOutlet weak var formatBarHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var frtBrFontSizeBtnOutlet: UIButton!
    @IBOutlet weak var customFontBtnOutlet: UIButton!
    
//    MARK:- VARIABLE(S)
    var txtViewString:String?
    var txtViewFontSize:CGFloat!
    var txtViewFtSize:Int!
    var txtViewFontSizeInt:Int?
    private var cloudKitNote = CloudKitNote()
    private var saving:Bool = false
    private var dirty:Bool = false
    var isSetList:Bool = false
    var docIndexValue:Int?
    var gigDict:[String:Any] = ["documentName": "About Gig Hards","documentDescription": "","editDocumentSize": 14,"promptDocumentTextSize": 14,"promptDocumentSpeed": 1]
    var lyricsDoc : Data?
    var coreDataObj = NSManagedObject()
    var icloudDocs = [CKRecord]()
    var isPurchased = Bool()
    var feature:FeaturesPurchased = .None
    
    var allNotes = [CKRecord]()
    var ckrecord : CKRecord?
    
//    let monitor = NWPathMonitor()
    
//    MARK:- VIEW LIFE-CYCLE METHOD(S)
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.checkInternetConnection()
        
        self.setLayout()
        self.documentTxtView.delegate = self

        self.formatBarView.isHidden = true
        self.formatBarHeightConstraint.constant = 0

        let welcomeText = self.setWelcomeText()
        self.icloudDocs = DatabaseHelper.shareInstance.fetchNotes(completionHandler: { (allDocuments) in
            print(allDocuments)
        })
        var gigAttrText = NSAttributedString()
        if self.documentTxtView.attributedText == nil {
            gigAttrText = NSAttributedString(string: welcomeText)
        } else {
            gigAttrText = NSAttributedString(string: welcomeText)
        }
        self.gigDict = ["documentName": "About Gig Hards","documentDescription": welcomeText ,"documentAttrText": gigAttrText,"editDocumentSize": 14,"promptDocumentTextSize": 20,"promptDocumentSpeed": 1] as [String : Any]

        self.documentTxtView.attributedText = gigAttrText
        if icloudDocs.count == 0 {
//            DatabaseHelper.shareInstance.saveDocToCoreData(documentObj: gigDict)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateTxtView(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateTxtView(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
                self.isPurchased = UserDefaults.standard.bool(forKey: "isPurchased")
                if let featureEnabled = UserDefaults.standard.string(forKey: "featuresEnabled") {
                    if featureEnabled == "03_gig_pro"{
                        feature = .All
                    } else if featureEnabled == "02_gig_pro"{
                        feature = .SetLists
                    } else if featureEnabled == "01_gig_pro"{
                        feature = .AudioVideo
                    }
                }
        
        self.navigationController?.navigationBar.isHidden = true
//        self.fetchNotes()
        if self.ckrecord != nil {
            self.docTitleLbl.text = self.ckrecord?.value(forKey: "documentName") as! String
            let attributedData = self.ckrecord?.value(forKey: "documentAttrText") as? Data
            guard let attrStr = NSKeyedUnarchiver.unarchiveObject(with: attributedData!) as? NSAttributedString else { return }
            self.documentTxtView.attributedText = attrStr
            self.txtViewFtSize = self.ckrecord?.value(forKey: "editDocumentSize") as! Int
            self.showAttrText(textView: self.documentTxtView, attributedText: attrStr, withSize: self.txtViewFtSize!)
        }
        if self.docTitleLbl.text == nil {
            self.noDocumentSeletedLbl.isHidden = false
        } else {
           self.noDocumentSeletedLbl.isHidden = true
        }
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "SetListViewControllerID") as! SetListViewController
        vc.delegate = self
        self.documentTxtView.textColor = .black
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
//        self.documentTxtView.endEditing(true)
//        // update document
//        self.updateDocument { (record, err) in
//            if err != nil {
//                print("not saved..")
//            }
//            if record != nil {
//                print("record saved..")
//            }
//        }
        //        MBProgressHUD.showAdded(to: self.view, animated: true)
        DispatchQueue.main.async {
            self.documentTxtView.endEditing(true)
            //            self.cloudKitNote.delegate = self
            //            let modifiedDate = Date()
            //            self.cloudKitNote.save(text: self.documentTxtView.text, modified: modifiedDate) { (error) in
            //                if let error = error {
            //                    print(error)
            //                }
            //            }
            // self.textViewShouldEndEditing(documentTxtView)
            self.formatBarView.isHidden = true
            self.formatBarHeightConstraint.constant = 0
            // update doc
            self.updateDocument { (record) in
                print("Something...")
                //                DispatchQueue.main.async {
                //                    MBProgressHUD.hide(for: self.view, animated: true)
                //                }
            }
        }
    }
//    MARK:- PRIVATE METHOD(S)
    func setLayout() {
        
        self.doneBtnOutlet.isHidden = true
        self.navigationController?.navigationBar.isHidden = true
        self.txtViewFontSize = 16.0
        self.txtViewFtSize = 16
        self.frtBrFontSizeBtnOutlet.setTitle("\(self.txtViewFtSize!)", for: .normal)
        self.documentTxtView.backgroundColor = .white
        self.noDocumentSeletedLbl.isHidden = true
        self.docTitleLbl.text = "About Gig Hard"
        self.documentTxtView.font = documentTxtView.font?.withSize(CGFloat(txtViewFtSize))
        if ( UI_USER_INTERFACE_IDIOM() == .pad)
        {
            self.shareBtnOutlet.setImage(UIImage(named: ""), for: .normal)
            self.shareBtnOutlet.setTitle("Share", for: .normal)
        }
    }
    
    func setWelcomeText() -> String{
        let path = Bundle.main.url(forResource: "welcome", withExtension: "txt")
        var string = ""
        do {
            string = try String(contentsOf: path!)
        } catch let err {
            print(err.localizedDescription)
        }
        return string
    }
    
    
    @objc func onTimer() {
        if dirty && !saving {
            self.saving = true
            let textToSave = self.documentTxtView.text
            let modifiedToSave = Date()
            self.cloudKitNote.save(text: textToSave!, modified: modifiedToSave) { (error) in
                DispatchQueue.main.async {
                    self.saving = false
                    if let error = error {
                        debugPrint("cloudKitNote.save failed, error: ", error)
                        return
                    }
                    self.dirty = false
                }
            }
        }
    }
    
    @objc func updateTxtView(notification:Notification) {
        let userInfo = notification.userInfo!
        let keyboardEndCoordinates = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let keyboardEndFrame = self.view.convert(keyboardEndCoordinates, to: view.window)
        if notification.name == UIResponder.keyboardWillHideNotification {
        documentTxtView.contentInset = UIEdgeInsets.zero
        } else {
        documentTxtView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardEndFrame.height, right: 0)
        documentTxtView.scrollIndicatorInsets = documentTxtView.contentInset
        }
    }
    
    func setAlignment(align: NSTextAlignment) {
        self.documentTxtView.textStorage.beginEditing()
        self.documentTxtView.textAlignment = align
        self.documentTxtView.textStorage.endEditing()
    }
    
    func addBodyText(pageRect: CGRect, textTop: CGFloat) {
      let textFont = UIFont.systemFont(ofSize: 22.0, weight: .regular)
      let paragraphStyle = NSMutableParagraphStyle()
      paragraphStyle.alignment = .natural
      paragraphStyle.lineBreakMode = .byWordWrapping
      let textAttributes = [
        NSAttributedString.Key.paragraphStyle: paragraphStyle,
        NSAttributedString.Key.font: textFont
      ]
      let attributedText = NSAttributedString(
        string: documentTxtView.text,
        attributes: textAttributes
      )
      let textRect = CGRect(
        x: 10,
        y: textTop,
        width: pageRect.width - 20,
        height: pageRect.height - textTop - pageRect.height / 5.0
      )
      attributedText.draw(in: textRect)
    }
    
    func updateDocument(completionHandler: @escaping(_ success: Bool?) -> Void) {
        
//        MBProgressHUD.showAdded(to: self.view, animated: true)
        self.showIndicator(withTitle: "Gig hard!", and: "Saving Document...")
        
        guard let docName = self.docTitleLbl.text else { return }
        guard let docDescription = self.documentTxtView.text else { return }
        let editDocSize = self.txtViewFtSize!
        var promptTextSize = Int()
        if ckrecord == nil {
            promptTextSize = 28
        } else {
            promptTextSize = ckrecord?.value(forKey: "promptDocumentTextSize") as! Int
        }
        
        var docAttrText = NSAttributedString()
        if self.documentTxtView.attributedText == nil {
            docAttrText = NSAttributedString(string: " ")
        } else {
            docAttrText = self.documentTxtView.attributedText!
        }
        var promptSpeed = Int()
        if ckrecord == nil {
            promptSpeed = 1
        } else {
            promptSpeed = ckrecord?.value(forKey: "promptDocumentSpeed") as! Int
        }
        
        let updateDate = Date() as Date
        let docDict = ["documentName": docName,"documentDescription": docDescription,"documentAttrText": docAttrText,"editDocumentSize": editDocSize,"promptDocumentTextSize": promptTextSize,"promptDocumentSpeed": promptSpeed, "docUpdateDate": updateDate] as [String : Any]
//        self.icloudDocs = DatabaseHelper.shareInstance.fetchNotes(completionHandler: { (rcrds) in
////            print(rcrds)
//        })
        if self.docIndexValue == nil {
            completionHandler(false)
        }else {
            if self.ckrecord != nil {
                DatabaseHelper.shareInstance.updateRecordInPlaylist(editRecord: ckrecord, documentObj: docDict) { (isSuccess) in
                    
//                        completionHandler(true)
//                        DatabaseHelper.shareInstance.savingNote(editRecord: self.ckrecord, documentObj: docDict) { (record) in
//                            DispatchQueue.main.async {
//                                self.hideIndicator()
//                                completionHandler(true)
//                            }
//                        }
                }
                DatabaseHelper.shareInstance.savingNote(editRecord: self.ckrecord, documentObj: docDict) { (record) in
                    DispatchQueue.main.async {
                        self.hideIndicator()
                        completionHandler(true)
                    }
                }
            } else {
                completionHandler(true)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
            self.hideIndicator()
        }
    }
    
    func showAttrText(textView: UITextView ,attributedText: NSAttributedString, withSize: Int) {

        let textRange = textView.selectedRange
        textView.isScrollEnabled = false
        let attrStr:NSMutableAttributedString = attributedText.mutableCopy() as! NSMutableAttributedString

        attrStr.enumerateAttributes(in: NSMakeRange(0, attrStr.length), options: NSAttributedString.EnumerationOptions.reverse) { (attributes, range, stop) in
                let mutableAttributes = attributes
                print(mutableAttributes)
            if mutableAttributes[NSAttributedString.Key("NSFont")] != nil {
                var currentFont:UIFont = mutableAttributes[NSAttributedString.Key("NSFont")] as! UIFont
                currentFont = currentFont.withSize(CGFloat(withSize))
                attrStr.addAttribute(.font, value: currentFont, range: range)
            } else {
                attrStr.addAttributes([NSAttributedString.Key.font: UIFont.init(name: "Helvetica Neue", size: CGFloat(withSize))], range: range)
            }
        }
        
        textView.attributedText = attrStr
        textView.isScrollEnabled = true
        textView.selectedRange = textRange
    }
    
    @objc func reachabilityChanged(note: Notification) {

//      let reachability = note.object as! Reachability
//
//      switch reachability.checkConnection() {
//      case .wifi:
//          print("Reachable via WiFi")
//      case .cellular:
//          print("Reachable via Cellular")
//      case .unavailable:
//        print("Network not reachable")
//      }
    }
    
    func fetchNotes() -> [CKRecord] {
        
        var allNotes = [CKRecord]()
        let container = CKContainer.default()
        let privateDatabase = container.privateCloudDatabase
        let predicate = NSPredicate(value: true)
        
        let query = CKQuery(recordType: "PromptDocuments", predicate: predicate)
        
        privateDatabase.perform(query, inZoneWith: nil) { (results, error) -> Void in
            if error != nil {
                print(error!)
            }
            else {
                allNotes.removeAll()
                for result in results! {
                    allNotes.append(result)
                    if self.ckrecord != nil {
                        if "\(result.value(forKey: "documentName")!)" == "\(self.ckrecord?.value(forKey: "documentName") as! String)" {
                            self.ckrecord = result
                        }
                    }
                }
            }
        }
        return allNotes
    }
    
    func checkInternetConnection() {
        if Reachability.isConnectedToNetwork() {
            print("Internet connection available")
        }
        else{
            let alertController = UIAlertController(title: "Gig Hard!", message: "Please check your internet connetion!", preferredStyle: .alert)
            let dismissAction = UIAlertAction(title: "OK", style: .default) { (alert) in
                DispatchQueue.main.async {
                    self.checkInternetConnection()
                }
            }
            alertController.addAction(dismissAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    
//    MARK:- IBACTION(S)
    @IBAction func myDocsBtn(_ sender: UIButton) {
        
        //        MBProgressHUD.showAdded(to: self.view, animated: true)
                self.updateDocument { (isSuccess) in
                    if isSuccess! {
                        DispatchQueue.main.async {
        //                    MBProgressHUD.hide(for: self.view, animated: true)
                            if self.feature == .None || self.feature == .AudioVideo {
                                let docListVC = self.storyboard?.instantiateViewController(withIdentifier: "DocumentListViewControllerID") as! DocumentListViewController
                                docListVC.delegate = self
                                docListVC.selectedDoc = self.ckrecord
                                if docListVC.documentsArr.count == 0 {
                                    docListVC.docDescription = self.documentTxtView.text
                                }
                                let navigationController = UINavigationController(rootViewController: docListVC)
                                navigationController.modalPresentationStyle = .fullScreen
        
                                self.navigationController?.present(navigationController, animated: true, completion: nil)
                            }else {
                                let vc = self.storyboard?.instantiateViewController(withIdentifier: "SetListViewControllerID") as! SetListViewController
                                vc.delegate = self
                                self.navigationController?.pushViewController(vc, animated: false)
                            }
                        }
                    } else {
                        MBProgressHUD.hide(for: self.view, animated: true)
        
                            if self.feature == .None || self.feature == .AudioVideo {
                                let docListVC = self.storyboard?.instantiateViewController(withIdentifier: "DocumentListViewControllerID") as! DocumentListViewController
                                docListVC.delegate = self
                                if docListVC.documentsArr.count == 0 {
                                    docListVC.docDescription = self.documentTxtView.text
                                }
                                let navigationController = UINavigationController(rootViewController: docListVC)
                                navigationController.modalPresentationStyle = .fullScreen
        
                                self.navigationController?.present(navigationController, animated: true, completion: nil)
                            }else {
                                let vc = self.storyboard?.instantiateViewController(withIdentifier: "SetListViewControllerID") as! SetListViewController
                                vc.delegate = self
                                self.navigationController?.pushViewController(vc, animated: true)
                            }
                        }
                    }
        
        
//        if self.feature == .All || self.feature == .SetLists {
//            let vc = self.storyboard?.instantiateViewController(withIdentifier: "SetListViewControllerID") as! SetListViewController
//            vc.delegate = self
//            self.navigationController?.pushViewController(vc, animated: true)
//
//        }else {
//            let docListVC = self.storyboard?.instantiateViewController(withIdentifier: "DocumentListViewControllerID") as! DocumentListViewController
//            docListVC.delegate = self
//            if docListVC.documentsArr.count == 0 {
//                docListVC.docDescription = self.documentTxtView.text
//            }
//            let navigationController = UINavigationController(rootViewController: docListVC)
//            navigationController.modalPresentationStyle = .fullScreen
//
//            self.navigationController?.present(navigationController, animated: true, completion: nil)
//        }
        
    }

    @IBAction func doneBtn(_ sender: UIButton) {
//        MBProgressHUD.showAdded(to: self.view, animated: true)
        DispatchQueue.main.async {
            self.documentTxtView.endEditing(true)
            //            self.cloudKitNote.delegate = self
            //            let modifiedDate = Date()
            //            self.cloudKitNote.save(text: self.documentTxtView.text, modified: modifiedDate) { (error) in
            //                if let error = error {
            //                    print(error)
            //                }
            //            }
            // self.textViewShouldEndEditing(documentTxtView)
            self.formatBarView.isHidden = true
            self.formatBarHeightConstraint.constant = 0
            // update doc
            self.updateDocument { (record) in
                print("Something...")
//                DispatchQueue.main.async {
//                    MBProgressHUD.hide(for: self.view, animated: true)
//                }
            }
        }
    }
    
    @IBAction func shareAction(_ sender: UIButton) {
        var fileName = String()
        var fileData = String()
        if ckrecord != nil {
            fileName = "\(ckrecord?.value(forKey: "documentName")!)"
            fileData = "\(ckrecord?.value(forKey: "documentName")!)"
        } else {
            fileName = self.docTitleLbl.text ?? ""
            fileData = self.documentTxtView.text ?? ""
        }
guard
    let title = self.docTitleLbl.text,
    let body = self.documentTxtView.attributedText
    else {
        // 2
        let alert = UIAlertController(
            title: "All Information Not Provided",
            message: "You must supply all information to create a flyer.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
        return
        }
        // 3
//        let pdfCreator = PDFCreator(
//            title: title,
//            body: body,
//            image: image,
//            contact: contact
//        )

        let pdfCreator = CreatorPDF(title: title, body: body)
        let pdfData = pdfCreator.createFlyer()
        let vc = UIActivityViewController(
            activityItems: [pdfData],
            applicationActivities: []
        )
        vc.excludedActivityTypes = [UIActivity.ActivityType.airDrop,UIActivity.ActivityType.assignToContact,UIActivity.ActivityType.copyToPasteboard,UIActivity.ActivityType.postToTencentWeibo,UIActivity.ActivityType.print,UIActivity.ActivityType.saveToCameraRoll,UIActivity.ActivityType.mail]
        vc.popoverPresentationController?.sourceView = sender
        present(vc, animated: true, completion: nil)
    }

    
    
    @IBAction func settingsPageBtn(_ sender: UIButton) {
        let settingsVC = self.storyboard?.instantiateViewController(withIdentifier: "SettingsViewControllerID") as! SettingsViewController
        self.navigationController?.pushViewController(settingsVC, animated: true)
    }
    
    @IBAction func IAPBtnAction(_ sender: UIButton) {
        let inAppPurchaseVC = self.storyboard?.instantiateViewController(withIdentifier: "InAppPurchaseViewControllerID") as! InAppPurchaseViewController
        self.navigationController?.pushViewController(inAppPurchaseVC, animated: true)
    }
    
    @IBAction func increaseFontBtn(_ sender: UIButton) {
        if ckrecord != nil {
            if self.txtViewFtSize == 40 {
                
            } else {
                self.txtViewFtSize += 1
                let textRange = documentTxtView.selectedRange
                documentTxtView.isScrollEnabled = false
                let attrStr:NSMutableAttributedString = documentTxtView.attributedText.mutableCopy() as! NSMutableAttributedString

                attrStr.enumerateAttributes(in: NSMakeRange(0, attrStr.length), options: NSAttributedString.EnumerationOptions.reverse) { (attributes, range, stop) in
                    let mutableAttributes = attributes
                    var currentFont:UIFont = mutableAttributes[NSAttributedString.Key("NSFont")] as! UIFont
                    currentFont = currentFont.withSize(CGFloat(txtViewFtSize))
                    attrStr.addAttribute(.font, value: currentFont, range: range)
                }
                
                self.documentTxtView.attributedText = attrStr
                self.documentTxtView.isScrollEnabled = true
                self.documentTxtView.selectedRange = textRange
            }
        } else {
            self.txtViewFtSize += 1
            self.documentTxtView.font = documentTxtView.font?.withSize(CGFloat(txtViewFtSize))
        }
        
    }
    
    @IBAction func decreaseFontBtn(_ sender: UIButton) {
        if ckrecord != nil {
            if self.txtViewFtSize == 12 {
                
            } else {
                self.txtViewFtSize -= 1
                let textRange = documentTxtView.selectedRange
                documentTxtView.isScrollEnabled = false
                let attrStr:NSMutableAttributedString = documentTxtView.attributedText.mutableCopy() as! NSMutableAttributedString

                attrStr.enumerateAttributes(in: NSMakeRange(0, attrStr.length), options: NSAttributedString.EnumerationOptions.reverse) { (attributes, range, stop) in
                    let mutableAttributes = attributes
                    var currentFont:UIFont = mutableAttributes[NSAttributedString.Key("NSFont")] as! UIFont
                    currentFont = currentFont.withSize(CGFloat(txtViewFtSize))
                    attrStr.addAttribute(.font, value: currentFont, range: range)
                }
                
                self.documentTxtView.attributedText = attrStr
                self.documentTxtView.isScrollEnabled = true
                self.documentTxtView.selectedRange = textRange
            }
        } else {
            self.txtViewFtSize -= 1
            self.documentTxtView.font = documentTxtView.font?.withSize(CGFloat(txtViewFtSize))
        }
        
    }
    
    @IBAction func promptBtn(_ sender: UIButton) {
        
        let promptDocVC = self.storyboard?.instantiateViewController(withIdentifier: "PromptDocumentViewControllerID") as! PromptDocumentViewController
        promptDocVC.ckRecord = self.ckrecord
        promptDocVC.documentIndex = self.docIndexValue
        promptDocVC.scrollableText = self.documentTxtView.text
        promptDocVC.documentTitle = self.docTitleLbl.text
        promptDocVC.scrollAttrText = self.documentTxtView.attributedText
        promptDocVC.docEditTxtSize = self.txtViewFtSize
        self.navigationController?.pushViewController(promptDocVC, animated: true)
        
//        MBProgressHUD.showAdded(to: self.view, animated: true)
//        self.updateDocument { (saved, err) in
//            DispatchQueue.main.async {
//                MBProgressHUD.hide(for: self.view, animated: true)
//                let promptDocVC = self.storyboard?.instantiateViewController(withIdentifier: "PromptDocumentViewControllerID") as! PromptDocumentViewController
//                promptDocVC.ckRecord = self.ckrecord
//                promptDocVC.documentIndex = self.docIndexValue
//                promptDocVC.scrollableText = self.documentTxtView.text
//                promptDocVC.documentTitle = self.docTitleLbl.text
//                promptDocVC.scrollAttrText = self.documentTxtView.attributedText
//                promptDocVC.docEditTxtSize = self.txtViewFtSize
//                self.navigationController?.pushViewController(promptDocVC, animated: true)
//            }
//        }
        
    }
    
    @IBAction func importBtn(_ sender: UIButton) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "ImportViewControllerID") as! ImportViewController
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func exportBtn(_ sender: UIButton) {
        self.sendEmail()
    }
    
//    MARK:- Formatting Bar Button Actions
    @IBAction func customFontAction(_ sender: UIButton) {
        let storyboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "PopOverViewControllerID") as! PopOverViewController
        vc.modalPresentationStyle = .popover
        vc.isCustomText = true
        vc.fontDelegate = self
        vc.docTxtSize = self.txtViewFtSize
        let popover: UIPopoverPresentationController = vc.popoverPresentationController!
        popover.sourceView = sender
        popover.sourceView?.backgroundColor = .white
        present(vc, animated: true, completion:nil)
    }
    
    @IBAction func formatBarFontSizeAction(_ sender: UIButton) {
        let storyboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "PopOverViewControllerID") as! PopOverViewController
        vc.modalPresentationStyle = .popover
        vc.isTextSize = true
        vc.txtSizeDelegate = self
        let popover: UIPopoverPresentationController = vc.popoverPresentationController!
        popover.sourceView = sender
        popover.sourceView?.backgroundColor = .white
        present(vc, animated: true, completion:nil)
    }
    
    @IBAction func formatBarFontDecreaseBtn(_ sender: Any) {
        if self.txtViewFtSize == 12 {
            
        } else {
            self.txtViewFtSize -= 1
            self.frtBrFontSizeBtnOutlet.setTitle("\(self.txtViewFtSize!)", for: .normal)
            let textRange = documentTxtView.selectedRange
            documentTxtView.isScrollEnabled = false
            let attrStr:NSMutableAttributedString = documentTxtView.attributedText.mutableCopy() as! NSMutableAttributedString

            attrStr.enumerateAttributes(in: NSMakeRange(0, attrStr.length), options: NSAttributedString.EnumerationOptions.reverse) { (attributes, range, stop) in
                let mutableAttributes = attributes
                var currentFont:UIFont = mutableAttributes[NSAttributedString.Key("NSFont")] as! UIFont
                currentFont = currentFont.withSize(CGFloat(txtViewFtSize))
                attrStr.addAttribute(.font, value: currentFont, range: range)
            }
            
            self.documentTxtView.attributedText = attrStr
            self.documentTxtView.isScrollEnabled = true
            self.documentTxtView.selectedRange = textRange
        }
//        self.updateDocument()
    }
    
    @IBAction func formatBarFontIncreaseAction(_ sender: UIButton) {
        if self.txtViewFtSize == 40 {
            
        } else {
            self.txtViewFtSize += 1
            self.frtBrFontSizeBtnOutlet.setTitle("\(self.txtViewFtSize!)", for: .normal)
            let textRange = documentTxtView.selectedRange
            documentTxtView.isScrollEnabled = false
            let attrStr:NSMutableAttributedString = documentTxtView.attributedText.mutableCopy() as! NSMutableAttributedString

            attrStr.enumerateAttributes(in: NSMakeRange(0, attrStr.length), options: NSAttributedString.EnumerationOptions.reverse) { (attributes, range, stop) in
                let mutableAttributes = attributes
                var currentFont:UIFont = mutableAttributes[NSAttributedString.Key("NSFont")] as! UIFont
                currentFont = currentFont.withSize(CGFloat(txtViewFtSize))
                attrStr.addAttribute(.font, value: currentFont, range: range)
            }
            
            self.documentTxtView.attributedText = attrStr
            self.documentTxtView.isScrollEnabled = true
            self.documentTxtView.selectedRange = textRange
        }
//        self.updateDocument()
    }
    
    @IBAction func fontAlignmentAction(_ sender: UIButton) {
        let storyboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "PopOverViewControllerID") as! PopOverViewController
        vc.modalPresentationStyle = .popover
        vc.isAlignment = true
        vc.alignDelegate = self
        let popover: UIPopoverPresentationController = vc.popoverPresentationController!
        popover.sourceView = sender
        popover.sourceView?.backgroundColor = .white
        present(vc, animated: true, completion:nil)
    }
    
    @IBAction func boldAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        
        let range = self.documentTxtView.selectedRange
        let currentAttrDict:NSDictionary = documentTxtView.textStorage.attributes(at: range.location, effectiveRange: nil) as NSDictionary
        let currentFont:UIFont = currentAttrDict.object(forKey: NSAttributedString.Key.font) as! UIFont
        let fontDescriptor:UIFontDescriptor = currentFont.fontDescriptor
        var symTraits = fontDescriptor.symbolicTraits
        if sender.isSelected == true {
            symTraits.insert([.traitBold])
        } else {
            symTraits.remove([.traitBold])
        }
        
        guard let fontDescriptorVar = fontDescriptor.withSymbolicTraits(symTraits) else { return }
        let updatedFont = UIFont.init(descriptor: fontDescriptorVar, size: 0.0)
        documentTxtView.textStorage.beginEditing()
        let attr = [NSAttributedString.Key.font : updatedFont]
        documentTxtView.textStorage.setAttributes(attr, range: range)
        documentTxtView.textStorage.endEditing()
    }
    
    @IBAction func italicAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        let range = self.documentTxtView.selectedRange
        let currentAttrDict:NSDictionary = documentTxtView.textStorage.attributes(at: range.location, effectiveRange: nil) as NSDictionary
        let currentFont:UIFont = currentAttrDict.object(forKey: NSAttributedString.Key.font) as! UIFont
        let fontDescriptor:UIFontDescriptor = currentFont.fontDescriptor
        var symTraits = fontDescriptor.symbolicTraits
        if sender.isSelected == true {
            symTraits.insert([.traitItalic])
        } else {
            symTraits.remove(.traitItalic)
        }
        guard let fontDescriptorVar = fontDescriptor.withSymbolicTraits(symTraits) else { return }
        let updatedFont = UIFont.init(descriptor: fontDescriptorVar, size: 0.0)
        documentTxtView.textStorage.beginEditing()
        let attr = [NSAttributedString.Key.font : updatedFont]
        documentTxtView.textStorage.setAttributes(attr, range: range)
        documentTxtView.textStorage.endEditing()
    }
    
    @IBAction func underlineAction(_ sender: UIButton) {
        
//        sender.isSelected = !sender.isSelected
//        let attributed = NSMutableAttributedString(attributedString: self.documentTxtView.attributedText)
//        let range = self.documentTxtView.selectedRange
//        let currentAttrDict:NSDictionary = documentTxtView.textStorage.attributes(at: range.location, effectiveRange: nil) as NSDictionary
//        let currentFont:UIFont = currentAttrDict.object(forKey: NSAttributedString.Key.font) as! UIFont
//        let fontDescriptor:UIFontDescriptor = currentFont.fontDescriptor
//        var symTraits = fontDescriptor.symbolicTraits
//        if sender.isSelected == true {
////           symTraits.insert([.traitItalic])
//            attributed.removeAttribute(.underlineStyle, range: range)
//        } else {
//            attributed.addAttributes([.underlineStyle : NSUnderlineStyle.single.rawValue], range: range)
//
//        }
//        guard let fontDescriptorVar = fontDescriptor.withSymbolicTraits(symTraits) else { return }
//        let updatedFont = UIFont.init(descriptor: fontDescriptorVar, size: 0.0)
//        documentTxtView.textStorage.beginEditing()
//        let attr = [NSAttributedString.Key.font : updatedFont]
//        documentTxtView.textStorage.setAttributes(attr, range: range)
//        documentTxtView.textStorage.endEditing()
        
        sender.isSelected = !sender.isSelected
        let range = self.documentTxtView.selectedRange
        documentTxtView.textStorage.beginEditing()
        var attr = [:] as! [NSAttributedString.Key : Any]
        if sender.isSelected == true {
            attr = [NSAttributedString.Key.underlineStyle : NSUnderlineStyle.single.rawValue]
        } else {

        }
        documentTxtView.textStorage.setAttributes(attr, range: range)
        documentTxtView.textStorage.endEditing()
        self.documentTxtView.font = documentTxtView.font?.withSize(CGFloat(self.txtViewFtSize))
    }

    func convertToJSONArray(moArray: NSManagedObject) -> Any {
        var jsonArray: [[String: Any]] = []
        var dict: [String: Any] = [:]
        for attribute in moArray.entity.attributesByName {
            //check if value is present, then add key to dictionary so as to avoid the nil value crash
            if let value = moArray.value(forKey: attribute.key) {
                dict[attribute.key] = value
//                print(dict)
            }
        }
        jsonArray.append(dict)
        
        do {
            let data = NSKeyedArchiver.archivedData(withRootObject: jsonArray)
            lyricsDoc = data
            UserDefaults.standard.set(lyricsDoc, forKey: "selectedDocument")

        }
        catch {}
        return lyricsDoc ?? 0
    }
    func sendEmail() {
        if (UserDefaults.standard.dictionary(forKey: "selectedDocument")) != nil {
              convertToJSONArray(moArray: coreDataObj)
        } else {
             UserDefaults.standard.data(forKey: "selectedDocument")
        }
        if MFMailComposeViewController.canSendMail() {
            let docName = "\(docTitleLbl!.text ?? "")"
            let mailComposer = MFMailComposeViewController()
            mailComposer.mailComposeDelegate = self
            mailComposer.setToRecipients([""])
            mailComposer.setSubject("\(docName) lyrics exported from Gig Hard!")
            mailComposer.setMessageBody("Here's the latest version of \(docName) from Gig Hard!", isHTML: true)

//            MARK:- send mail as 
            guard
            let title = self.docTitleLbl.text,
            let body = self.documentTxtView.attributedText
                else { return }
            let pdfCreator = CreatorPDF(title: title, body: body)
            let pdfData = pdfCreator.createFlyer()

            if let dataMail = pdfData as? Data {
                mailComposer.addAttachmentData(pdfData, mimeType: "application/pdf", fileName: "\(docName).pdf")
            }
            
            // share recfile
//            if DatabaseHelper.shareInstance.exportRecUrl != nil {
//             let path = DatabaseHelper.shareInstance.exportRecUrl?.absoluteString
//                let audioData = DatabaseHelper.shareInstance.exportRecData as Data?
//                if (audioData?.count ?? 0) > 0 {
//                    if (URL(fileURLWithPath: path!).pathExtension == "wav") {
//                        if let audioData = audioData {
//                            mailComposer.addAttachmentData(audioData, mimeType: "audio/x-wav", fileName: DatabaseHelper.shareInstance.exportRecUrl!.lastPathComponent)
//                        }
//                    } else {
//                        if let audioData = audioData {
//                            mailComposer.addAttachmentData(audioData, mimeType: "audio/mp4a-latm", fileName: DatabaseHelper.shareInstance.exportRecUrl!.lastPathComponent)
//                        }
//                    }
//                }
//            }
            
            mailComposer.modalPresentationStyle = .fullScreen
            present(mailComposer, animated: true)
        } else {
            let alertView = UIAlertController(title: "Gig Hard!", message: "Make sure your device can send Emails.", preferredStyle: .alert)
            let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
            alertView.addAction(dismissAction)
            self.present(alertView, animated: true, completion: nil)
        }
    }
}

//MARK: MFMailComposerDelegate
extension EditViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        switch result.rawValue {
        case MFMailComposeResult.cancelled.rawValue:
            print("Cancelled")
        case MFMailComposeResult.saved.rawValue:
            print("saved")
        case MFMailComposeResult.failed.rawValue:
            print("failed")
        case MFMailComposeResult.sent.rawValue:
            print("sent")
        default:
            break
        }
        self.dismiss(animated: true, completion: nil)
    }
}

//MARK: UITextViewDelegate
extension EditViewController: UITextViewDelegate,UITextFieldDelegate {
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        self.doneBtnOutlet.isHidden = false
        if ( UI_USER_INTERFACE_IDIOM() == .pad)
        {
            self.formatBarView.isHidden = false
            self.formatBarHeightConstraint.constant = 60
        }
        return true
    }
    
    @objc func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        self.doneBtnOutlet.isHidden = true
        self.documentTxtView.resignFirstResponder()
        if ( UI_USER_INTERFACE_IDIOM() == .pad)
        {
            self.formatBarView.isHidden = false
            self.formatBarHeightConstraint.constant = 60
        }
        DispatchQueue.main.async {
            self.documentTxtView.endEditing(true)
            //            self.cloudKitNote.delegate = self
            //            let modifiedDate = Date()
            //            self.cloudKitNote.save(text: self.documentTxtView.text, modified: modifiedDate) { (error) in
            //                if let error = error {
            //                    print(error)
            //                }
            //            }
            // self.textViewShouldEndEditing(documentTxtView)
            self.formatBarView.isHidden = true
            self.formatBarHeightConstraint.constant = 0
            // update doc
            self.updateDocument { (record) in
                print("Something...")
                //                DispatchQueue.main.async {
                //                    MBProgressHUD.hide(for: self.view, animated: true)
                //                }
            }
        }
        return true
    }
}

//MARK: ICLOUD DELEGATE
extension EditViewController:CloudKitNoteDelegate {
    func cloudKitNoteChanged(note: CloudKitNote) {
        DispatchQueue.main.async {
            self.documentTxtView.text = note.text
        }
    }
}

//MARK: VIEW CONTROLLER DELEGATE METHODS
extension EditViewController: PromptDocumentDelegate, PromptSongDelegate{
    
    func selectedDoc(promptDoc: CKRecord, indexValue: Int?) {
        self.ckrecord = promptDoc
        self.docIndexValue = indexValue
    }
    
    func selectPromptRecord(promptRecord: CKRecord, indexValue: Int?) {
        self.ckrecord = promptRecord
        self.docIndexValue = indexValue
    }
    
        func selectSongFromSortedList(song: [String : Any], indexValue: Int?) {
            // should not be used here
        }
   
}
//MARK: RICH TEXT STYLE DELEGATE METHODS
extension EditViewController: PopOverViewContollerFontDelegate,PopOverViewControllerAlignmentDelegate,PopOverViewControllerTextSizeDelegate {
    func fontSelectionViewController(controller: UIViewController, font: String) {
        controller.dismiss(animated: true, completion: nil)
        self.documentTxtView.font = UIFont(name: font, size: CGFloat(txtViewFtSize))
        self.frtBrFontSizeBtnOutlet.setTitle("\(self.txtViewFtSize!)", for: .normal)
        self.customFontBtnOutlet.setTitle(font, for: .normal)
    }
    
    func alignmentSelectionViewController(controller: UIViewController, alignment: NSTextAlignment) {
        controller.dismiss(animated: true, completion: nil)
        self.documentTxtView.textAlignment = alignment
    }
    
    func textSizeSelectionViewController(controller: UIViewController, withSize: Int) {
        controller.dismiss(animated: true, completion: nil)
        self.frtBrFontSizeBtnOutlet.setTitle("\(withSize)", for: .normal)
        self.documentTxtView.font = documentTxtView.font?.withSize(CGFloat(withSize))
        self.txtViewFtSize = withSize
    }
}

extension String {
    func base64Encoded() -> String? {
        if let data = self.data(using: .utf8) {
            return data.base64EncodedString()
        }
        return nil
    }
    /// will set a regual and a bold text in the same label
      func attrText(withString string: String, boldString: String, font: UIFont) -> NSAttributedString {
           let attributedString = NSMutableAttributedString(string: string,
                                                        attributes: [NSAttributedString.Key.font: font])
           let boldFontAttribute: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: font.pointSize)]
           let range = (string as NSString).range(of: boldString)
           attributedString.addAttributes(boldFontAttribute, range: range)
           return attributedString
       }
    
    func attributedStringWithColor(_ strings: [String], color: UIColor, characterSpacing: UInt? = nil) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: self)
        for string in strings {
            let range = (self as NSString).range(of: string)
            attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: range)
        }

        guard let characterSpacing = characterSpacing else {return attributedString}

        attributedString.addAttribute(NSAttributedString.Key.kern, value: characterSpacing, range: NSRange(location: 0, length: attributedString.length))

        return attributedString
    }
}

extension UITextView {
    func centerVertically() {
        let fittingSize = CGSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude)
        let size = sizeThatFits(fittingSize)
        let topOffset = (bounds.size.height - size.height * zoomScale) / 2
        let positiveTopOffset = max(1, topOffset)
        contentOffset.y = -positiveTopOffset
    }
}
