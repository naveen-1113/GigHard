//
//  PopOverViewController.swift
//  GigHard_Swift
//
//  Created by osx on 26/12/19.
//  Copyright © 2019 osx. All rights reserved.
//

import UIKit

protocol PopOverViewContollerFontDelegate {
    func fontSelectionViewController(controller: UIViewController, font:String)
}
protocol PopOverViewControllerAlignmentDelegate {
    func alignmentSelectionViewController(controller: UIViewController, alignment:NSTextAlignment)
}
protocol PopOverViewControllerTextSizeDelegate {
    func textSizeSelectionViewController(controller: UIViewController, withSize: Int)
}
class PopOverViewController: UIViewController {

    @IBOutlet weak var popOverTitle: UILabel!
    @IBOutlet weak var tblPopOver: UITableView!
    var isAlignment = Bool()
    var isCustomText = Bool()
    var isTextSize = Bool()
    var customFonts = [String]()
    var textSize = [Int]()
    var docTxtSize = Int()
    var alignDelegate: PopOverViewControllerAlignmentDelegate?
    var txtSizeDelegate: PopOverViewControllerTextSizeDelegate?
    var fontDelegate: PopOverViewContollerFontDelegate?
    override func viewDidLoad() {
        super.viewDidLoad()
        if isTextSize {
            self.textSize = [10,12,14,18,24,32,40]
            self.popOverTitle.text = "Size"
        } else if isCustomText {
            customFonts = ["Arial","Courier","Courier New","Georgia","Gill Sans","Helvetica","Helvetica Neue","Palatino","Times New Roman","Verdana"]
            self.popOverTitle.text = "Select Font"
        }else if isAlignment {
            self.popOverTitle.text = "Set Alignment"
        } else {
            self.popOverTitle.text = ""
        }
    }
}

extension PopOverViewController: UITableViewDelegate,UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isAlignment {
            return 4
        }else if isCustomText {
            return customFonts.count
        }else if isTextSize {
            return textSize.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tblPopOver.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! UITableViewCell
        if isAlignment {
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Align Left"
            case 1:
                cell.textLabel?.text = "Center"
            case 2:
                cell.textLabel?.text = "Align Right"
            case 3:
                cell.textLabel?.text = "Justify"
            default:
                cell.textLabel?.text = ""
            }
        }else if isCustomText {
            cell.textLabel?.text = self.customFonts[indexPath.row]
            cell.textLabel?.font = UIFont(name: self.customFonts[indexPath.row], size: 20.0)
        }else if isTextSize {
            cell.textLabel?.text = "\(self.textSize[indexPath.row])"
        } else {
            cell.textLabel?.text = ""
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isAlignment {
            switch indexPath.row {
            case 0:
                self.alignDelegate?.alignmentSelectionViewController(controller: self, alignment: NSTextAlignment.left)
            case 1:
                self.alignDelegate?.alignmentSelectionViewController(controller: self, alignment: NSTextAlignment.center)
            case 2:
                self.alignDelegate?.alignmentSelectionViewController(controller: self, alignment: NSTextAlignment.right)
            case 3:
                self.alignDelegate?.alignmentSelectionViewController(controller: self, alignment: NSTextAlignment.justified)
            default:
                break
            }
        }else if isCustomText {
            self.fontDelegate?.fontSelectionViewController(controller: self, font: self.customFonts[indexPath.row])
        }else if isTextSize {
            self.txtSizeDelegate?.textSizeSelectionViewController(controller: self, withSize: self.textSize[indexPath.row])
        } else {
            
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
}
