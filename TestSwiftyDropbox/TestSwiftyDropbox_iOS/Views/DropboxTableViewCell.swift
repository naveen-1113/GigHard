//
//  DropboxTableViewCell.swift
//  GigHard_Swift
//
//  Created by osx on 18/12/19.
//  Copyright © 2019 osx. All rights reserved.
//

import UIKit
import SwiftyDropbox
import MBProgressHUD

protocol DropBoxTableViewCellDelegate {
    func itunesFileImport(isFileImported: Bool?, file: String?)
    func dropboxFileImport(isFileImported: Bool?, file: String?)
}

class DropboxTableViewCell: UITableViewCell {
    @IBOutlet weak var lblFileName: UILabel!
    @IBOutlet weak var importBtnOutlet: UIButton!
    // iTunes Variables
    var directoryData = [URL]()
    var indexPath: Int?
    var delegate: DropBoxTableViewCellDelegate?
    
    // Dropbox Variables
    var isDropbox:Bool! = false
    var allFilesData = [Files.Metadata]()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    @IBAction func importAction(_ sender: UIButton) {
        if isDropbox {

        } else {
            self.listFiles()
            let docName = "\(directoryData[indexPath!].deletingPathExtension().lastPathComponent)"
            do {
                let descriptionString = try String(contentsOf: directoryData[indexPath!])
                let editDocSize = 14
                let promptTextSize = 20
                let promptSpeed = 1
                let docAttrText = NSAttributedString(string: descriptionString)
                let docDict = ["documentName": docName,"documentDescription": descriptionString,"editDocumentSize": editDocSize,"promptDocumentTextSize": promptTextSize,"promptDocumentSpeed": promptSpeed,"documentAttrText": docAttrText] as [String : Any]
                if docName == "" {
                }
                else {
//                    DatabaseHelper.shareInstance.saveDocToCoreData(documentObj: docDict)
//                    DatabaseHelper.shareInstance.saveNotes(editRecord: nil, documentObj: docDict)
                    DatabaseHelper.shareInstance.savingNote(editRecord: nil, documentObj: docDict) { (record) in
                        print("saved..")
                    }
                    self.delegate?.itunesFileImport(isFileImported: true, file: docName)
                }
            } catch let error {
                print(error.localizedDescription)
            }
        }
    }
    
    func listFiles() {

        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        do {
            let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil)
            let txtFiles = directoryContents.filter{ $0.pathExtension == "txt" }
            directoryData = txtFiles
            _ = txtFiles.map{ $0.deletingPathExtension().lastPathComponent }
        } catch {
            print(error)
        }
    }
    func downloadFile(path: String) {
        if let client = DropboxClientsManager.authorizedClient {
        client.files.download(path: path).response { (response, error) in
            if let (metadata, data) = response {
                print("Dowloaded file name: \(metadata.name)")
                print("Downloaded file data: \(data)")
                let str = String(decoding: data, as: UTF8.self)
                print(str)
                let docName = "\(metadata.name.deletingSuffix(".txt"))"
                let descriptionString = String(decoding: data, as: UTF8.self)
                let editDocSize = 14
                let promptTextSize = 20
                let promptSpeed = 1
                let docAttrText = NSAttributedString(string: descriptionString)
                let docDict = ["documentName": docName,"documentDescription": descriptionString,"editDocumentSize": editDocSize,"promptDocumentTextSize": promptTextSize,"promptDocumentSpeed": promptSpeed,"documentAttrText": docAttrText] as [String : Any]
                if docName == "" {
                }
                else {
//                    DatabaseHelper.shareInstance.saveDocToCoreData(documentObj: docDict)
//                    DatabaseHelper.shareInstance.saveNotes(editRecord: nil, documentObj: docDict)
                    DatabaseHelper.shareInstance.savingNote(editRecord: nil, documentObj: docDict) { (record) in
                        print("saved..")
                    }
                    self.delegate?.dropboxFileImport(isFileImported: true, file: docName)
                }
            } else {
                print(error!)
            }
            }
        }
    }
}


