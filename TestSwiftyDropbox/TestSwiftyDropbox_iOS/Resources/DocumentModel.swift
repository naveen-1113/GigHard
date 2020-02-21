//
//  DocumentModel.swift
//  GigHard_Swift
//
//  Created by osx on 09/12/19.
//  Copyright © 2019 osx. All rights reserved.
//

import Foundation
struct Document {
    var docAttText: NSObject?
    var docDescription: String?
    var docName: String?
    var editTextSize: Int16
    var promptSpeed: Int16
    var promptTextSize: Int16
    var updateDate: Date?
    
    init(docAttText:NSObject?,docDescription:String?,docName:String?,editTextSize:Int16,promptSpeed:Int16,promptTextSize:Int16,updateDate:Date?) {
        self.docAttText = docAttText
        self.docDescription = docDescription
        self.docName = docName
        self.editTextSize = editTextSize
        self.promptSpeed = promptSpeed
        self.promptTextSize = promptTextSize
        self.updateDate = updateDate
    }
}
