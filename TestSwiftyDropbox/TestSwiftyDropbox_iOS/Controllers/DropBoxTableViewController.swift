//
//  DropBoxTableViewController.swift
//  GigHard_Swift
//
//  Created by osx on 27/11/19.
//  Copyright © 2019 osx. All rights reserved.
//

import UIKit
import SwiftyDropbox
import MBProgressHUD

class DropBoxTableViewController: UIViewController {

//    var directoryData = NSMutableArray()    20-1-20
    
    //    MARK:- IBOUTLET(S) AND VARIABLES
    @IBOutlet weak var resetBtnOutlet: UIButton!
    @IBOutlet weak var refreshIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tblViewDropBox: UITableView!
    var allFilesData = [Files.Metadata]()
    var dropBoxData = [String]()
    var vSpinner : UIView?
    
//    var filePath = String()   20-1-20
    
    //    MARK:- VIEW LIFE CYCLE METHODS
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = true
        MBProgressHUD.showAdded(to: self.view, animated: true)
        self.refreshIndicator.isHidden = true
        self.tblViewDropBox.register(UINib(nibName: "DropboxTableViewCell", bundle: nil), forCellReuseIdentifier: "DropboxTableViewCellReuse")
        self.tblViewDropBox.rowHeight = UITableView.automaticDimension
        self.tblViewDropBox.estimatedRowHeight = 44.0
        self.getDBData()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
    }
    
    //    MARK:- IBACTION(S)
    @IBAction func backBtn(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func doneBtn(_ sender: UIButton) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    @IBAction func logOffBtn(_ sender: Any) {
        DropboxClientsManager.unlinkClients()
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func resetBtn(_ sender: UIButton) {
        self.allFilesData.removeAll()
        MBProgressHUD.showAdded(to: self.view, animated: true)
        self.getDBData()
    }
    
    func alertController() {
        let alertController = UIAlertController(title: "Gig Hard!", message: "There is no files in your dropbox with .txt extensions", preferredStyle: .alert)
        let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
        alertController.addAction(dismissAction)
        self.present(alertController, animated: true, completion: nil)
    }
    func getDBData() {
        // Verify user is logged into Dropbox
        if let client = DropboxClientsManager.authorizedClient {
            // Get the current user's account info
            client.users.getCurrentAccount().response { (response, error) in
                if let account = response {
                    print("Hello \(account.name.givenName)")
                } else {
                    print(error!)
                }
            }
            // List folder
            client.files.listFolder(path: "").response { (response, error) in
                if let result = response {
                    print("Folder contents:")
                    for entry in result.entries {
                        let data = result.entries
                        print(entry.name)
                         self.allFilesData.append(entry)
                    }
                    print(self.allFilesData.count)
                    DispatchQueue.main.async {
                        MBProgressHUD.hide(for: self.view, animated: true)
                        self.tblViewDropBox.reloadData()
                        if self.allFilesData.count == 0 {
                            self.alertController()
                        }
                    }
                } else {
                    print(error!)
                }
            }
            // Upload a file
                // Download a file
        }
    }
    
}

//MARK:- TABLEVIEW DELEGATE AND DATASOURCE METHODS
extension DropBoxTableViewController: UITableViewDelegate,UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.allFilesData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DropboxTableViewCellReuse", for: indexPath) as! DropboxTableViewCell
        
        
        if let file = (self.allFilesData[indexPath.row] as AnyObject) as? Files.FileMetadata {
            
            cell.lblFileName.text = self.allFilesData[indexPath.row].name
            cell.accessoryType = .none
            cell.importBtnOutlet.isHidden = false
            
//            print("This is a file.")
//            print("File size: \(file.size)")
        } else if (self.allFilesData[indexPath.row] as AnyObject) is Files.FolderMetadata {
             cell.lblFileName.text = self.allFilesData[indexPath.row].name
             cell.accessoryType = .disclosureIndicator
             cell.importBtnOutlet.isHidden = true
            
//            print("This is a folder.")
        }
        
        cell.importBtnOutlet.tag = indexPath.row
        cell.importBtnOutlet.addTarget(self, action: #selector(self.importFile), for: .touchUpInside)
        
        cell.indexPath = indexPath.row
        cell.isDropbox = true
        cell.allFilesData = allFilesData
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !self.tblViewDropBox.isEditing {
            
            let fileMetadata = self.allFilesData[indexPath.row].self
            if (fileMetadata is Files.FolderMetadata) {
//                let newPath = fileMetadata.pathLower
//
//                let nextFolder = DropBoxTableViewController.init(path: newPath!)
////                let nextFolder = DropBoxTableViewController.init(nibName: "DropBoxTableViewControllerID", bundle: Bundle.init(path: newPath!))
//                self.navigationController?.pushViewController(nextFolder, animated: true)
                let alertController = UIAlertController(title: "Gig Hard!", message: "You cannot move to this folder right now.", preferredStyle: .alert)
                let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
                alertController.addAction(dismissAction)
                self.present(alertController, animated: true, completion: nil)
                
            }
        }
        tblViewDropBox.deselectRow(at: indexPath, animated: true)
    }
    
     @objc func importFile(_ sender: UIButton)
     {
//        self.showIndicator(withTitle: "Downloading", and: "Downloading file.")
        MBProgressHUD.showAdded(to: self.view, animated: true)
        let path = (allFilesData[sender.tag].pathDisplay)!
        if path.hasSuffix(".txt") {
            self.downloadFile(path: (allFilesData[sender.tag].pathDisplay)!)
        } else {
            let ac = UIAlertController(title: "Gig Hard!", message: "You cannot make the gig of this type of file.", preferredStyle: .alert)
            let dismissAct = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            ac.addAction(dismissAct)
            self.present(ac, animated: true, completion: nil)
            MBProgressHUD.hide(for: self.view, animated: true)
        }
    }
    func downloadFile(path: String) {
         if let client = DropboxClientsManager.authorizedClient {
         client.files.download(path: path).response { (response, error) in
             if let (metadata, data) = response {
//                 print("Dowloaded file name: \(metadata.name)")
//                 print("Downloaded file data: \(data)")
//                 let str = String(decoding: data, as: UTF8.self)
//                 print(str)
                 let docName = "\(metadata.name.deletingSuffix(".txt"))"
                 let descriptionString = String(decoding: data, as: UTF8.self)
                 let editDocSize = 14
                 let promptTextSize = 20
                 let promptSpeed = 1
                 let docAttrText = NSAttributedString(string: descriptionString)
                 let docDict = ["documentName": docName,"documentDescription": descriptionString,"editDocumentSize": editDocSize,"promptDocumentTextSize": promptTextSize,"promptDocumentSpeed": promptSpeed,"documentAttrText": docAttrText] as [String : Any]
                 if docName == "" {
                    MBProgressHUD.hide(for: self.view, animated: true)
                 }
                 else {
//                     DatabaseHelper.shareInstance.saveDocToCoreData(documentObj: docDict)
//                    DatabaseHelper.shareInstance.saveNotes(editRecord: nil, documentObj: docDict)
                    DatabaseHelper.shareInstance.savingNote(editRecord: nil, documentObj: docDict) { (record) in
                        print("saved..")
                    }
                    MBProgressHUD.hide(for: self.view, animated: true)
                    let alertController = UIAlertController(title: "Gig Hards!", message: "Successfully imported file \("\(metadata.name)")", preferredStyle: .alert)
                    let dismissAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                    alertController.addAction(dismissAction)
                    self.present(alertController, animated: true, completion: nil)
                 }
             } else {
                 print(error!)
             }
             }
         }
     }
}

//MARK:- MB PROGRESSHUD METHODS
extension UIViewController {
    func showIndicator(withTitle title: String, and Description:String) {
        let Indicator = MBProgressHUD.showAdded(to: self.view, animated: true)
        Indicator.label.text = title
        Indicator.isUserInteractionEnabled = false
        Indicator.detailsLabel.text = Description
        Indicator.show(animated: true)
    }
    func hideIndicator() {
        MBProgressHUD.hide(for: self.view, animated: true)
    }
    
    
    
    
    
    
    
    
}

//MARK:- OTHER DELEGATE METHODS
extension DropBoxTableViewController: DropBoxTableViewCellDelegate {
    func itunesFileImport(isFileImported: Bool?, file: String?) {
    }
    
    func dropboxFileImport(isFileImported: Bool?, file: String?) {
        if isFileImported == true {
            let alertController = UIAlertController(title: "Gig Hards!", message: "Successfully imported file \(file!).txt", preferredStyle: .alert)
            let dismissAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alertController.addAction(dismissAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
}


