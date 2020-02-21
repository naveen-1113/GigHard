//
//  DocumentListViewController.swift
//  GigHard_Swift
//
//  Created by osx on 27/11/19.
//  Copyright © 2019 osx. All rights reserved.
//

import UIKit
import CoreData
import CloudKit
import MBProgressHUD

protocol PromptDocumentDelegate {
    
    func selectedDoc(promptDoc: CKRecord, indexValue:Int?)
}
class DocumentListViewController: UIViewController {

//    MARK:- IBOUTLET(S) AND VARIABLES
    @IBOutlet weak var documentsListTableView: UITableView!
    @IBOutlet weak var addNewDocumentView: UIView!
    var delegate:PromptDocumentDelegate?
    var docDescription:String?
    var documentsArr = [CKRecord]()
    var selectedDoc:CKRecord?
    var editButton:UIBarButtonItem?
    var deleteBtnIsHidden:Bool? = true
    var isAddDocument:Bool?
    var coreDataObj = NSManagedObject()
    var isDocExist:Bool! = false
    
    // pull to refresh
    lazy var refreshing: UIRefreshControl = {
      let refreshControl = UIRefreshControl()
        refreshControl.tintColor = .darkGray
        refreshControl.addTarget(self, action: #selector(fetchNotes), for: .valueChanged)
        return refreshControl
    }()
    
    //    MARK:- VIEW LIFE CYCLE METHODS
    override func viewDidLoad() {
        super.viewDidLoad()
        self.handleNavigationBar()
        self.isAddDocument = false
        self.documentsListTableView.refreshControl = refreshing
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleAddNewDocView))
        self.addNewDocumentView.addGestureRecognizer(tapGesture)
//        self.documentsArr = DatabaseHelper.shareInstance.fetchNotes(completionHandler: { (ckRecords) in
//            DispatchQueue.main.async {
//                self.documentsListTableView.reloadData()
//            }
//        })
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.fetchNotes()
        }
        
        if self.documentsArr.count == 0 {
            let gigDict = ["documentName": "About Gig Hards","documentDescription": self.docDescription ?? "","editDocumentSize": 14,"promptDocumentTextSize": 14,"promptDocumentSpeed": 1] as [String : Any]
//            DatabaseHelper.shareInstance.saveNotes(editRecord: nil, documentObj: gigDict)
//            DatabaseHelper.shareInstance.savingNote(editRecord: nil, documentObj: gigDict) { (record) in
//                print("saved..")
//            }
            
            DispatchQueue.main.async {
                self.documentsListTableView.reloadData()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.fetchNotes()
    }
    
//        MARK:- PRIVATE METHODS
    @objc func fetchNotes() -> [CKRecord] {
            MBProgressHUD.showAdded(to: self.view, animated: true)
            let container = CKContainer.default()
            let privateDatabase = container.privateCloudDatabase
            let predicate = NSPredicate(value: true)
            
            let query = CKQuery(recordType: "PromptDocuments", predicate: predicate)
            
            privateDatabase.perform(query, inZoneWith: nil) { (results, error) -> Void in
                if error != nil {
                    DispatchQueue.main.async {
                        MBProgressHUD.hide(for: self.view, animated: true)
                        self.refreshing.endRefreshing()
                    }
                }
                else {
                    self.documentsArr.removeAll()
                    for result in results! {
                        self.documentsArr.append(result)
                    }
                    let sortedSongs = self.documentsArr.sorted { a, b in
                        
                        return (a.value(forKey: "documentName") as! String)
                            .localizedStandardCompare(b.value(forKey: "documentName") as! String)
                            == ComparisonResult.orderedAscending
                    }
                    self.documentsArr = sortedSongs
                    OperationQueue.main.addOperation({ () -> Void in
                        self.refreshing.endRefreshing()
                        MBProgressHUD.hide(for: self.view, animated: true)
                        self.documentsListTableView.reloadData()
                    })
                }
            }
            return self.documentsArr
        }
    
    @objc func handleAddNewDocView() {
        let newDocVC = self.storyboard?.instantiateViewController(withIdentifier: "NewDocumentViewControllerID") as! NewDocumentViewController
        newDocVC.delegate = self
        self.navigationController?.pushViewController(newDocVC, animated: true)
    }
    
    func handleNavigationBar() {
        
        self.navigationItem.title = "My Documents"
        let cancelBtn = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(handleCancelAction))
        editButton = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(handleEditAction))
        self.navigationItem.leftBarButtonItem = cancelBtn
        self.navigationItem.rightBarButtonItem = editButton
        self.navigationController?.navigationBar.backgroundColor = .white
    }
    
    @objc func handleCancelAction() {
        if selectedDoc == nil {
            
        } else {
            if self.documentsArr.contains(selectedDoc!) {
            } else {
            }
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func handleEditAction() {
        self.documentsListTableView.isEditing = !self.documentsListTableView.isEditing
        self.editButton?.title = self.documentsListTableView.isEditing ? "Done" : "Edit"

//        self.documentsListTableView.reloadData()
    }
    
    func usingPromtDelegateMethod() {
        let docVC = self.storyboard?.instantiateViewController(withIdentifier: "DocumentListViewControllerID") as! DocumentListViewController
        docVC.delegate = self as! PromptDocumentDelegate
    }
}

//    MARK:- TABLEVIEW DELEGATE AND DATASOURCES
extension DocumentListViewController:UITableViewDelegate,UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.documentsArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

            let cell = documentsListTableView.dequeueReusableCell(withIdentifier: "defaultCellReuse", for: indexPath)
        if self.documentsArr.count > 0 {
            cell.textLabel?.text = self.documentsArr[indexPath.row].value(forKey: "documentName") as! String
        } else {
            cell.textLabel?.text = ""
        }
        
            return cell        
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if indexPath.row == self.documentsArr.count {
            UITableViewCell.EditingStyle.none
        }else{
            UITableViewCell.EditingStyle.delete
        }
        if editingStyle == .delete {
            
            //delete from icloud
            DatabaseHelper.shareInstance.deleteiCloudRecord(recordName: self.documentsArr[indexPath.row].value(forKey: "documentName") as! String)
            documentsArr.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        if editingStyle == .none {
            let alert = UIAlertController(title: "Failed", message: "Cannot delete item.", preferredStyle: .alert)
            let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
            alert.addAction(dismissAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == self.documentsArr.count {
//            print("\(indexPath)")
            let newDocVC = self.storyboard?.instantiateViewController(withIdentifier: "NewDocumentViewControllerID") as! NewDocumentViewController
            newDocVC.delegate = self
            self.navigationController?.pushViewController(newDocVC, animated: true)
        }else{

            delegate?.selectedDoc(promptDoc: self.documentsArr[indexPath.row], indexValue: indexPath.row)
            self.dismiss(animated: true, completion: nil)
        }
    }
    @available(iOS 11.0, *)
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "Delete") { (action, sourceView, completionHandler) in
                        let deletedSong = self.documentsArr[indexPath.row]
                        //deleteFrom icloud
                        DatabaseHelper.shareInstance.deleteiCloudRecord(recordName: "\(deletedSong.value(forKey: "documentName")!)")
                        // Initialize Fetch Request
                        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "PromptDocument")
                        let managedObjectContext = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext
                        // Configure Fetch Request
                        fetchRequest.includesPropertyValues = false
                        do {
        //                    managedObjectContext?.delete(deletedSong)  // if using coredata
                            // Save Changes
                            try managedObjectContext?.save()
                            self.documentsArr.remove(at: indexPath.row)
        //                    self.allSongsArr = DatabaseHelper.shareInstance.fetchDocuments()
        //                    self.allIcloudSongs = self.fetchNotes()
                            
                            DispatchQueue.main.async {
                                self.documentsListTableView.reloadData()
                            }
                        } catch {
                            // Error Handling
                            // ...
                        }
                    }

                    let rename = UIContextualAction(style: .normal, title: "Rename") { (action, sourceView, completionHandler) in
        //                let updatedSong = self.allSongsArr[indexPath.row]
                        let updatedSong = self.documentsArr[indexPath.row]
                        let alertAddList = UIAlertController(title: "Gig Hard!", message: "Please enter new name for song.", preferredStyle: .alert)
                        alertAddList.addTextField { (textField) in
                            textField.delegate = self as! UITextFieldDelegate
                           // textField.text = "\(self.allRecordings[(indexPath as NSIndexPath).row].lastPathComponent)"
                            textField.layer.cornerRadius = 4
                            textField.autocapitalizationType = .words
                        }
                        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                        let okAction = UIAlertAction(title: "OK", style: .default) { UIAlertAction in
                            // do rename stuff here
                            MBProgressHUD.showAdded(to: self.view, animated: true)
                            let answer = alertAddList.textFields![0]
                            
                            if answer.text!.count > 0
                            {
                                let docName = "\(answer.text!)"
                                let docDescription = "\(updatedSong.value(forKey: "documentDescription")!)"
                                let editSize = "\(updatedSong.value(forKey: "editDocumentSize")!)"
                                let editDocSize = Int(editSize)!
                                let promptSize = "\(updatedSong.value(forKey: "promptDocumentTextSize")!)"
                                let promptTextSize = Int(promptSize)!
                                // convert attributed data to string
                                var docAttrText = NSAttributedString()
                                let attrData = updatedSong.value(forKey: "documentAttrText") as! Data
                                let attrStr = NSKeyedUnarchiver.unarchiveObject(with: attrData)
                                docAttrText = attrStr as! NSAttributedString
                                
                                let speed = "\(updatedSong.value(forKey: "promptDocumentSpeed")!)"
                                let promptSpeed = Int(speed)!
                                let updateDate = updatedSong.value(forKey: "docUpdateDate")
                                let docDict = ["documentName": docName,"documentDescription": docDescription,"documentAttrText": docAttrText,"editDocumentSize": editDocSize,"promptDocumentTextSize": promptTextSize,"promptDocumentSpeed": promptSpeed, "docUpdateDate": updateDate] as [String : Any]
        
                                DatabaseHelper.shareInstance.fetchNotes { (allDocuments) in
                                    let documents = allDocuments
                                    for document in documents {
                                        if document.value(forKey: "documentName") as! String == docName {
                                            self.isDocExist = true
                                        }
                                    }
                                    if self.isDocExist == true {
                                        self.isDocExist = false
                                        let alert = UIAlertController(title: "Gig Hards!", message: "This document is already exist in your list please choose different name for your document.", preferredStyle: .alert)
                                        //                                let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                                        alert.addAction(cancelAction)
                                        DispatchQueue.main.async {
                                            MBProgressHUD.hide(for: self.view, animated: true)
                                            self.present(alert, animated: true, completion: nil)
                                        }
                                    } else {
                                        DatabaseHelper.shareInstance.savingNote(editRecord: updatedSong, documentObj: docDict) { (record) in
                                            DispatchQueue.main.async {
                                                MBProgressHUD.hide(for: self.view, animated: true)
                                                self.fetchNotes()
                                            }
                                        }
                                    }
                                }
                            }
                            DispatchQueue.main.async {
                                self.documentsListTableView.reloadData()
                            }
                        }
                        alertAddList.addAction(cancelAction)
                        alertAddList.addAction(okAction)
                        self.present(alertAddList, animated: true, completion: nil)
                    }
                    let swipeActionConfig = UISwipeActionsConfiguration(actions: [rename, delete])
                    swipeActionConfig.performsFirstActionWithFullSwipe = false
                    return swipeActionConfig
    }
}
//MARK:- TextFieldDelegate
extension DocumentListViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
}
//MARK:- DataPassDelegate
extension DocumentListViewController: DataPassDelegate {
    func passDocumentArr(document: [[String : Any]]) {
//        self.documentDBArr = DatabaseHelper.shareInstance.fetchDocuments()
        self.documentsArr = DatabaseHelper.shareInstance.fetchNotes(completionHandler: { (ckRecords) in
            DispatchQueue.main.async {
                self.documentsListTableView.reloadData()
            }
        })
    }
}
