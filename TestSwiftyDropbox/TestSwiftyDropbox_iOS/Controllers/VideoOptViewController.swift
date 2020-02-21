//
//  VideoOptViewController.swift
//  GigHard_Swift
//
//  Created by osx on 06/12/19.
//  Copyright © 2019 osx. All rights reserved.
//

import UIKit

protocol VideoOptViewControllerDelegate{
    func featureSelected(cameraSel:Bool?,videoRecSel:Bool?)
}
class VideoOptViewController: UIViewController {
//    MARK:- IBOUTLETS AND VARIABLES
    @IBOutlet weak var showMeSwitch: UISwitch!
    @IBOutlet weak var recordMeSwitch: UISwitch!
    var isCameraSelected:Bool?
    var isShowMe:Bool?
    var isVideoRecSelected:Bool?
    var isRecordMe:Bool?
    var delegate:VideoOptViewControllerDelegate? = nil
    
    //    MARK:- VIEW LIFE CYCLE METHODS
    override func viewDidLoad() {
        super.viewDidLoad()
        let doneBtn = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(handleDoneAction))
        self.setupLayouts()
        doneBtn.tintColor = .white
        self.navigationItem.rightBarButtonItem = doneBtn
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(red: 25/255.0, green: 185/255.0, blue: 242/255.0, alpha: 1)]
        
        // used for remain the previous state of switch
        isShowMe =  UserDefaults.standard.bool(forKey: "isShowMe")
        if isShowMe ?? false {
            showMeSwitch.isOn = true
        }else{
            showMeSwitch.isOn = false
        }
        
        isRecordMe = UserDefaults.standard.bool(forKey: "isRecordMe")
        if isRecordMe ?? false {
            recordMeSwitch.isOn = true
        }else{
            recordMeSwitch.isOn = false
        }
    }
//    MARK:- PRIVATE METHODS
    func setupLayouts() {
//        self.navigationController?.navigationBar.isHidden = false
        self.navigationController?.navigationBar.barTintColor = .black
        self.navigationItem.title = "Video Options"
        self.showMeSwitch.layer.borderWidth = 2.0
        self.showMeSwitch.clipsToBounds = true
        self.showMeSwitch.layer.cornerRadius = 15
        self.showMeSwitch.layer.borderColor = UIColor.white.cgColor
        self.recordMeSwitch.layer.borderWidth = 2.0
        self.recordMeSwitch.clipsToBounds = true
        self.recordMeSwitch.layer.cornerRadius = 15
        self.recordMeSwitch.layer.borderColor = UIColor.white.cgColor
    }
    
//    MARK:- IBACTIONS
    @objc func handleDoneAction() {
        UserDefaults.standard.set(isShowMe, forKey: "isShowMe")
        UserDefaults.standard.set(isRecordMe, forKey: "isRecordMe")
        print()
        self.delegate?.featureSelected(cameraSel: isShowMe, videoRecSel: isRecordMe)
        self.dismiss(animated: true, completion: nil)
//        self.navigationController?.popViewController(animated: true)
    }
//    MARK:- IBACTION(S)
    @IBAction func showMeAction(_ sender: UISwitch) {
        if showMeSwitch.isOn {
            isShowMe = true
        }else{
            isShowMe = false
        }
    }
    
    @IBAction func recordMeAction(_ sender: UISwitch) {
        if recordMeSwitch.isOn {
            isRecordMe = true
        }else{
            isRecordMe = false
        }
    }
    
}

