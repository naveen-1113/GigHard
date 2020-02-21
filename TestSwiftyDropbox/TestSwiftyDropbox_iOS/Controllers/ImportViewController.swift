//
//  ImportViewController.swift
//  GigHard_Swift
//
//  Created by osx on 28/11/19.
//  Copyright © 2019 osx. All rights reserved.
//

import UIKit
import SwiftyDropbox
import WebKit

class ImportViewController: UIViewController,WKNavigationDelegate {
//    MARK:- VARIABLES AND OUTLET(S)
    @IBOutlet weak var importfromDBBtnOutlet: UIButton!
    @IBOutlet weak var importFromiTunesBtnOutlet: UIButton!
    @IBOutlet weak var webView: UIView!
    var wkWebView: WKWebView?
    var arrAllFiles = [String]()

    //    MARK:- VIEW LIFE CYCLE METHOD(S)
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = true
        self.webView.isHidden = true
        self.setLayout()
        self.checkButtons()
    }
    override func viewDidAppear(_ animated: Bool) {
           super.viewDidAppear(animated)
           self.checkButtons()
       }
    
    //    MARK:- PRIVATE METHOD(S)
    func setLayout() {
        self.importfromDBBtnOutlet.layer.cornerRadius = 10.0
        self.importFromiTunesBtnOutlet.layer.cornerRadius = 10.0
    }
    func setCancelBtnOnNavigationBar() {
        let doneBtn = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(handleDoneAction))
        self.navigationItem.rightBarButtonItem = doneBtn
    }
        
    
    //    MARK:- IBACTION(S)
    @objc func handleDoneAction() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func doneBtn(_ sender: UIButton) {
//        self.navigationController?.popViewController(animated: true)
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func importFromDBBtn(_ sender: UIButton) {
        print(DropboxClientsManager.authorizedTeamClient as Any)
        print(DropboxClientsManager.authorizedClient as Any)
        if DropboxClientsManager.authorizedClient != nil {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "DropBoxTableViewControllerID") as! DropBoxTableViewController
            
            self.navigationController?.pushViewController(vc, animated: true)
            
        } else {
            DropboxClientsManager.authorizeFromController(UIApplication.shared, controller: self, openURL: {(url: URL) -> Void in  UIApplication.shared.open(url)})
        }

    }

    @IBAction func importFromiTunesBtn(_ sender: UIButton) {

        let vc = self.storyboard?.instantiateViewController(withIdentifier: "ItunesTableViewControllerID") as! ItunesTableViewController
        
        self.navigationController?.pushViewController(vc, animated: true)


    }
   
//    MARK:- SHOULD BE CHANGE LATER
    func getAllFilesFromDocumentDirectory() {
        arrAllFiles = listFilesFromDocumentFolder()
    }
    
    func listFilesFromDocumentFolder() -> [String] {
        let dirs = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        if dirs.count != 0 {
            let dir = dirs[0]
            let fileList = try! FileManager.default .contentsOfDirectory(atPath: dir)
            return fileList
        } else {
            let fileList = ["No Any File Found"]
            return fileList
        }
    }
    
    func checkButtons() {
        if DropboxClientsManager.authorizedClient != nil || DropboxClientsManager.authorizedTeamClient != nil {

        } else {

        }
    }
    
}
