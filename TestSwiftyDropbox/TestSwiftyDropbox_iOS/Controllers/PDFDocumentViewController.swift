//
//  PDFDocumentViewController.swift
//  GigHard_Swift
//
//  Created by osx on 27/11/19.
//  Copyright © 2019 osx. All rights reserved.
//

import UIKit

class PDFDocumentViewController: UIViewController {
    
    //    MARK:- IBOUTLET(S) AND VARIABLE(S)
    @IBOutlet weak var pdfView: UIView!
    public var documentData: Data?
    
    //    MARK:- VIEW LIFE CYCLE METHODS
    override func viewDidLoad() {
        super.viewDidLoad()
//        self.navigationController?.popViewController(animated: false)
    }
    //    MARK:- IBACTIONS
    @IBAction func backBtn(_ sender: UIButton) {

    }
    
}
