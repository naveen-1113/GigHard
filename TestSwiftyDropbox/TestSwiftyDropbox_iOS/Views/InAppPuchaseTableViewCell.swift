//
//  InAppPuchaseTableViewCell.swift
//  GigHard_Swift
//
//  Created by osx on 02/12/19.
//  Copyright © 2019 osx. All rights reserved.
//

import UIKit

protocol PurchasingDataDelegate {
    func purchaseProduct(purchasesProduct: [String:Any], index: Int)
}
class InAppPuchaseTableViewCell: UITableViewCell {
//    MARK:- IBOUTLET(S) AND VARIABLE(S)
    @IBOutlet weak var iconImgView: UIImageView!
    @IBOutlet weak var iapLabel: UILabel!
    @IBOutlet weak var buyBtn: UIButton!
    @IBOutlet weak var restoreBtn: UIButton!
    @IBOutlet weak var iconImgViewWidthContstraint: NSLayoutConstraint!
    @IBOutlet weak var buyBtnWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var restoreBtnWidthConstraint: NSLayoutConstraint!
    var delegate:PurchasingDataDelegate? = nil
    var indexPath: Int?
    var productAvailable = [[String:Any]]()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.restoreBtn.isHidden = true
//        print(productAvailable)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    @IBAction func buyBtn(_ sender: UIButton) {
        let selectedProduct = productAvailable[indexPath!] //DatabaseHelper.shareInstance.getDataFromP_list()![indexPath!]
        self.delegate?.purchaseProduct(purchasesProduct: selectedProduct, index: indexPath!)
    }
    @IBAction func restoreBtn(_ sender: UIButton) {
        
    }
}
