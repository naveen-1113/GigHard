//
//  AllSongsTableViewCell.swift
//  GigHard_Swift
//
//  Created by osx on 10/12/19.
//  Copyright © 2019 osx. All rights reserved.
//

import UIKit

class AllSongsTableViewCell: UITableViewCell {

    @IBOutlet weak var lblSongName: UILabel!
    @IBOutlet weak var checkMarkImgView: UIImageView!
    @IBOutlet weak var checkMarkWidthConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.checkMarkImgView.isHidden = true
        self.checkMarkWidthConstraint.constant = 0
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    @IBAction func selectDeselectBtn(_ sender: UIButton) {
    }
    
}
