//
//  NewDocumentViewController.swift
//  GigHard_Swift
//
//  Created by osx on 26/11/19.
//  Copyright © 2019 osx. All rights reserved.
//

import UIKit
import MBProgressHUD

protocol DataPassDelegate {
    func passDocumentArr(document: [[String:Any]])
}
class NewDocumentViewController: UIViewController {

    //    MARK:- IBOUTLET(S) AND VARIABLE(S)
    @IBOutlet weak var addSongTitleTxtField: UITextField!
    @IBOutlet weak var createBtnOutlet: UIButton!
    var delegate:DataPassDelegate?
    var isDocExist:Bool! = false
    
    //    MARK:- VIEW LIFE CYCLE METHODS
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = false
        self.navigationItem.title = "Add Song"
        let cancelBtn = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelBtnPressed))
        self.navigationItem.setLeftBarButton(cancelBtn, animated: true)
        self.createBtnOutlet.layer.cornerRadius = 5.0
        self.createBtnOutlet.layer.borderWidth = 1.0
        self.createBtnOutlet.layer.borderColor = UIColor.darkGray.cgColor
    }
    
    //    MARK:- IBACTION(S)
    @objc func cancelBtnPressed() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func createAction(_ sender: UIButton) {
        MBProgressHUD.showAdded(to: self.view, animated: true)
        let docName = "\(self.addSongTitleTxtField.text!)"
        let docAttrText = NSAttributedString(string: " ")
        let docDescription = ""
        let editDocSize = 14
        let promptTextSize = 20
        let promptSpeed = 1
        let docDict = ["documentName": docName,"documentDescription": docDescription,"editDocumentSize": editDocSize,"promptDocumentTextSize": promptTextSize,"promptDocumentSpeed": promptSpeed,"documentAttrText": docAttrText] as! [String : Any]
        if docName == "" {
            MBProgressHUD.hide(for: self.view, animated: true)
            let alert = UIAlertController(title: "Error", message: "You must enter a title to create a new song", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
        }
        else {
            DatabaseHelper.shareInstance.fetchNotes { (allDocuments) in
                let documents = allDocuments
                for document in documents {
                    if document.value(forKey: "documentName") as! String == docName {
                        self.isDocExist = true
                    }
                }
                if self.isDocExist == true {
                    self.isDocExist = false
                    let alert = UIAlertController(title: "Gig Hards!", message: "This document is already created please choose different name to create new document.", preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                    alert.addAction(cancelAction)
                    DispatchQueue.main.async {
                        MBProgressHUD.hide(for: self.view, animated: true)
                        self.present(alert, animated: true, completion: nil)
                    }
                } else {
                    DatabaseHelper.shareInstance.savingNote(editRecord: nil, documentObj: docDict) { (record) in
                        DispatchQueue.main.async {
                            MBProgressHUD.hide(for: self.view, animated: true)
                            self.navigationController?.popViewController(animated: true)
                        }
                    }
//                    DatabaseHelper.shareInstance.saveDocToCoreData(documentObj: docDict)
                }
            }
            self.delegate?.passDocumentArr(document: [docDict])
        }
    }
}
