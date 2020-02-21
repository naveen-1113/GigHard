//
//  SettingsTableViewCell.swift
//  GigHard_Swift
//
//  Created by osx on 29/11/19.
//  Copyright © 2019 osx. All rights reserved.
//

import UIKit

class SettingsTableViewCell: UITableViewCell {

//    @IBOutlet weak var lblNavigate: UILabel!
    @IBOutlet weak var lblDetail: UILabel!
    @IBOutlet weak var lblHeightContraintOutlet: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
