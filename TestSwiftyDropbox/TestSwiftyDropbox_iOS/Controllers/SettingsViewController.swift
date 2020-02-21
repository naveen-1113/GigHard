//
//  SettingsViewController.swift
//  GigHard_Swift
//
//  Created by osx on 29/11/19.
//  Copyright © 2019 osx. All rights reserved.
//

import UIKit
import MessageUI
import MBProgressHUD
import Foundation
import CloudKit

protocol SettingsViewControllerDelegate {
    func playRec(recUrl: URL, recData:Data)
}

class SettingsViewController: UIViewController {

    //    MARK:- IBOUTLET(S) AND VARIABLES
    @IBOutlet weak var lblAboutGigHard: UILabel!
    @IBOutlet weak var settingTableView: UITableView!
    var settingsListArr = [String]()
    var isDismissFromSetList:Bool! = false
    var isAudioFiles:Bool! = false
    var delegate : SettingsViewControllerDelegate?
    var allRecordings = [CKRecord]()
    var sortedRecordings = [URL]()
    var index = 0
    var appVersion:String?
    
    var isDocExist:Bool! = false
    var exportedUrl: URL?
    
    lazy var refreshing: UIRefreshControl = {
      let refreshControl = UIRefreshControl()
        refreshControl.tintColor = .darkGray
        refreshControl.addTarget(self, action: #selector(getRecordings), for: .valueChanged)
        return refreshControl
    }()
    
    //    MARK:- VIEW LIFE CYCLE METHODS
    override func viewDidLoad() {
        super.viewDidLoad()
        appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
        print(appVersion!)
        if isAudioFiles {
            MBProgressHUD.showAdded(to: self.view, animated: true)
        } else {
            self.settingTableView.isEditing = false
        }
        if isAudioFiles {
            self.lblAboutGigHard.text = "Recordings"
            self.getRecordings()
            self.settingTableView.reloadData()
            self.settingTableView.refreshControl = refreshing
        } else {
            self.lblAboutGigHard.text = "About Gig Hard"
           settingsListArr = ["How to Videos","Support","Other apps by DanteMedia.com","Turn your App Idea into a reality!","Gig Hard V \(appVersion!)","Copyright © 2019-DANTE MEDIA,LLC"]
        }
        self.handleNavigationBar()
        self.settingTableView.register(UINib(nibName: "SettingsTableViewCell", bundle: nil), forCellReuseIdentifier: "SettingsTableViewCellReuse")
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
            MBProgressHUD.hide(for: self.view, animated: true)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.settingTableView.reloadData()
    }

    //    MARK:- PRIVATE METHODS
    func handleNavigationBar() {
        self.navigationController?.navigationBar.isHidden = false
        if isAudioFiles {
            self.navigationItem.title = "All Recordings"
        } else {
            self.navigationItem.title = "Settings"
        }
        let doneBtn = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(handleDoneAction))
        self.navigationController?.navigationBar.backgroundColor = .white
        self.navigationItem.rightBarButtonItem = doneBtn
        self.navigationItem.setHidesBackButton(true, animated:true)
    }
    
    @objc func getRecordings() {
        DatabaseHelper.shareInstance.fetchAllRecordings { (recordings) in
            self.allRecordings.removeAll()
            self.allRecordings = recordings
            
            DispatchQueue.main.async {
                
                let sortedRecordings = self.allRecordings.sorted { a, b in
                    let url1 = URL(string: a.value(forKey: "recordingStr") as! String)
                    let url2 = URL(string: b.value(forKey: "recordingStr") as! String)
                    return (url1!.lastPathComponent)
                        .localizedStandardCompare(url2!.lastPathComponent)
                        == ComparisonResult.orderedAscending
                }
                self.allRecordings = sortedRecordings
                self.refreshing.endRefreshing()
                MBProgressHUD.hide(for: self.view, animated: true)
                self.settingTableView.reloadData()
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
            self.refreshing.endRefreshing()
        }
    }
    
    func mailSentSuccessfully(songName: URL) {
        let name = songName.lastPathComponent.deletingSuffix(".m4a")
        let alertView = UIAlertController(title: "Gig Hard!", message: "\(name) exported successfully.", preferredStyle: .alert)
        let dismissAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alertView.addAction(dismissAction)
        self.present(alertView, animated: true, completion: nil)
    }
    
    
//    func sendemail(email: String, recUrl: URL, recData: Data){
//        if( MFMailComposeViewController.canSendMail() ) {
////            println("Can send email.")
//
//            let mailComposer = MFMailComposeViewController()
//            mailComposer.mailComposeDelegate = self
//
//            //Set the subject and message of the email
//            mailComposer.setSubject("Voice Note")
//            mailComposer.setMessageBody("my sound", isHTML: false)
//            mailComposer.setToRecipients([email])
//
////            if let docsDir = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as? String {
////                var fileManager = NSFileManager.defaultManager()
////                var filecontent = fileManager.contentsAtPath(docsDir + "/" + fileName)
//
//                mailComposer.addAttachmentData(recData, mimeType: "audio/x-wav", fileName: recUrl.lastPathComponent)
////            }
//
//            self.present(mailComposer, animated: true, completion: nil)
//        }
//    }
    
//    MARK:- IBACTIONS
    @objc func handleDoneAction() {
        if isAudioFiles {
             self.navigationController?.popViewController(animated: true)
        } else {
        self.navigationController?.popToRootViewController(animated: true)
        }
    }
}

//MARK:- TABLEVIEW DELEGATE AND DATASOURCES
extension SettingsViewController: UITableViewDelegate,UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isAudioFiles {
            return self.allRecordings.count
        } else {
            return self.settingsListArr.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = settingTableView.dequeueReusableCell(withIdentifier: "SettingsTableViewCellReuse", for: indexPath) as! SettingsTableViewCell
        if isAudioFiles {
            cell.accessoryType = .none
//            cell.lblDetail.text = allRecordings[(indexPath as NSIndexPath).row].lastPathComponent
            let urlStr = self.allRecordings[indexPath.row].value(forKey: "recordingStr") as! String
            let url = URL(string: urlStr)!
            cell.lblDetail.text = url.lastPathComponent
        } else {
            cell.accessoryType = .disclosureIndicator
            cell.lblDetail.text = self.settingsListArr[indexPath.row]
            if (indexPath.row == self.settingsListArr.count - 1) || (indexPath.row == self.settingsListArr.count - 2) {
              cell.accessoryType = .none
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isAudioFiles {
            let data = self.allRecordings[indexPath.row].value(forKey: "recordingData") as! Data
            let urlStr = self.allRecordings[indexPath.row].value(forKey: "recordingStr") as! String
            let url = URL(string: urlStr)!
            
            DatabaseHelper.shareInstance.exportRecData = data
            DatabaseHelper.shareInstance.exportRecUrl = url
            delegate?.playRec(recUrl: url, recData: data)
            self.navigationController?.popViewController(animated: true)
        } else {
            let webVC = self.storyboard?.instantiateViewController(withIdentifier: "WebViewControllerID") as! WebViewController
            let navigationController = UINavigationController(rootViewController: webVC)
            navigationController.modalPresentationStyle = .fullScreen
            navigationController.modalTransitionStyle = .crossDissolve
            if indexPath.row == 0 {
                if let url =  URL(string: "https://dantemedia.com/gig-hard-tutorial/") {
                    UIApplication.shared.openURL(url)
                }
            }
            else if indexPath.row == 1 {
                if MFMailComposeViewController.canSendMail() {
                    let mailComposer = MFMailComposeViewController()
                    mailComposer.mailComposeDelegate = self
                    mailComposer.setToRecipients(["apps@dantemedia.com"])
//                    mailComposer.setBccRecipients(["dante@paragoni.com"])
                    
                    mailComposer.navigationItem.title = "Gig Hard \(appVersion!) Support"
//                    composeVC.setToRecipients(["address@example.com"])
                    mailComposer.setSubject("Gig Hard \(appVersion!) Support")
//                    composeVC.setMessageBody("Hello from California!", isHTML: false)
                    mailComposer.setMessageBody("<p></p>", isHTML: true)
                    mailComposer.modalPresentationStyle = .fullScreen
                    present(mailComposer, animated: true)
                } else {
                    let alertView = UIAlertController(title: "Gig Hard!", message: "Make sure your device can send Emails.", preferredStyle: .alert)
                    let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
                    alertView.addAction(dismissAction)
                    self.present(alertView, animated: true, completion: nil)
                }
            }
            else if indexPath.row == 2 {
                if let url =  URL(string: "https://dantemedia.com/apps/") {
                    UIApplication.shared.openURL(url)
                }
            }
            else if indexPath.row == 3 {
                if let url =  URL(string: "https://bit.ly/inappsettings") {
                    UIApplication.shared.openURL(url)
                }
            }
            else if indexPath.row == 4 || indexPath.row == 5 {
            }
        }
    }

    
//    MARK:- delete update
    @available(iOS 11.0, *)
     func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "Delete") { (action, sourceView, completionHandler) in
            MBProgressHUD.showAdded(to: self.view, animated: true)
            DatabaseHelper.shareInstance.deleteRecording(selectedRecording: self.allRecordings[indexPath.row]) { (isSuccess) in
                if isSuccess! {
                    print("recording deleted")
                } else {
                    print("recording not deleted")
                }
                DispatchQueue.main.async {
                    self.getRecordings()
                }
            }

        }

        let rename = UIContextualAction(style: .normal, title: "Rename") { (action, sourceView, completionHandler) in

            let alertAddList = UIAlertController(title: "Gig Hard!", message: "Please enter new name for recording.", preferredStyle: .alert)
            alertAddList.addTextField { (textField) in
                textField.delegate = self as UITextFieldDelegate
                textField.layer.cornerRadius = 4
                textField.autocapitalizationType = .words
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            let okAction = UIAlertAction(title: "OK", style: .default) { UIAlertAction in
                // do rename stuff here
                DispatchQueue.main.async {
                    MBProgressHUD.showAdded(to: self.view, animated: true)
                }
                let answer = alertAddList.textFields![0]
                
                if answer.text!.count > 0
                {
                    let oldUrlStr = self.allRecordings[indexPath.row].value(forKey: "recordingStr") as! String
                    let url = URL(string: oldUrlStr)!
                    var newUrl = url.deletingLastPathComponent()
                    newUrl = newUrl.appendingPathComponent(answer.text! + ".m4a")
                    let newUrlStr = newUrl.absoluteString
                    
                    DatabaseHelper.shareInstance.fetchAllRecordings { (allRecordings) in
                        
                        DispatchQueue.main.async {
                            let allRecordings = allRecordings
                            for record in allRecordings {
                                //                            print(name.value(forKey: "recordingStr"))
                                let url = URL(string: record.value(forKey: "recordingStr") as! String)
                                let name = url?.lastPathComponent
                                if name == answer.text! + ".m4a" {
                                    print("name exist")
                                    self.isDocExist = true
                                }
                            }
                            if self.isDocExist == true {
                                self.isDocExist = false
                                let alert = UIAlertController(title: "Gig Hards!", message: "The entered name is already taken by oyher recording please choose different name for your recording.", preferredStyle: .alert)
                                //                                let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                                alert.addAction(cancelAction)
                                DispatchQueue.main.async {
                                    MBProgressHUD.hide(for: self.view, animated: true)
                                    self.present(alert, animated: true, completion: nil)
                                }
                            } else {
                                DatabaseHelper.shareInstance.saveRecToIcloud(editRecord: self.allRecordings[indexPath.row], recData: self.allRecordings[indexPath.row].value(forKey: "recordingData") as! Data, recUrl: newUrlStr) { (isSuccess) in
                                    if isSuccess! {
                                        print("Renaming Successful")
                                    } else {
                                        print("Renaming Failed")
                                    }
                                    DispatchQueue.main.async {
                                        self.getRecordings()
                                    }
                                }
                            }
                        }
                    }
                }
                DispatchQueue.main.async {
                    self.settingTableView.reloadData()
                }
            }
            alertAddList.addAction(cancelAction)
            alertAddList.addAction(okAction)
            self.present(alertAddList, animated: true, completion: nil)
        }
        
        let share = UIContextualAction(style: .normal, title: "Share") { (action, sourceView, completionHandler) in
            DispatchQueue.main.async {
                let data = self.allRecordings[indexPath.row].value(forKey: "recordingData") as! Data
                let urlStr = self.allRecordings[indexPath.row].value(forKey: "recordingStr") as! String
                let url = URL(string: urlStr)!
                self.exportedUrl = url
                if MFMailComposeViewController.canSendMail() {
                    let mailComposer = MFMailComposeViewController()
                    mailComposer.mailComposeDelegate = self
                    mailComposer.setToRecipients([""])
                    mailComposer.setSubject("\(url.lastPathComponent) exported from Gig Hard!")
                    mailComposer.setMessageBody("", isHTML: true)
                    
                    if url != nil {
                        let path = url.absoluteString
                        let audioData = data as Data?
                        if (audioData?.count ?? 0) > 0 {
                            if (URL(fileURLWithPath: path).pathExtension == "wav") {
                                if let audioData = audioData {
                                    mailComposer.addAttachmentData(audioData, mimeType: "audio/x-wav", fileName: url.lastPathComponent)
                                }
                            } else {
                                if let audioData = audioData {
                                    mailComposer.addAttachmentData(audioData, mimeType: "audio/mp4a-latm", fileName: url.lastPathComponent)
                                }
                            }
                        }
                    }
                    mailComposer.modalPresentationStyle = .fullScreen
                    self.present(mailComposer, animated: true)
                } else {
                    let alertView = UIAlertController(title: "Gig Hard!", message: "Make sure your device can send Emails.", preferredStyle: .alert)
                    let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
                    alertView.addAction(dismissAction)
                    self.present(alertView, animated: true, completion: nil)
                }
            }
        }
        share.backgroundColor = UIColor(red: 34.0/255.0, green: 34.0/255.0, blue: 34.0/255.0, alpha: 1)
        let swipeActionConfig = UISwipeActionsConfiguration(actions: [share, rename, delete])
        swipeActionConfig.performsFirstActionWithFullSwipe = false
        return swipeActionConfig
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if isAudioFiles {
            return .delete
        }
        return .none
    }
}

//MARK: MFMailComposerDelegate
extension SettingsViewController: MFMailComposeViewControllerDelegate {
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
            DispatchQueue.main.async {
                self.mailSentSuccessfully(songName: self.exportedUrl!)
            }
        default:
            break
        }
        self.dismiss(animated: true, completion: nil)
    }
}

extension SettingsViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
}
