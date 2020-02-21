//
//  DatabaseManager.swift
//  GigHard_Swift
//
//  Created by osx on 05/12/19.
//  Copyright © 2019 osx. All rights reserved.
//

import Foundation
import CoreData
import UIKit
import SwiftyDropbox
import CloudKit
import MBProgressHUD

class DatabaseHelper: NSObject {
    var allNotes = [CKRecord]()
    var allPlaylists = [CKRecord]()
    var songOldName:String?
    var songNewName:String?
    
    // export recording
    var exportRecUrl:URL?
    var exportRecData:Data?
//    MARK:- Constants and variables
    static let shareInstance = DatabaseHelper()
    let context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext

//    MARK:- Plist Private Methods
    func getDataFromP_list() -> [[String:Any]]? {
        var rootArr = [[String:Any]]()
        let path = Bundle.main.path(forResource: "IAPList", ofType: "plist")
        rootArr = NSArray(contentsOfFile: path!) as! [[String:Any]]
        return rootArr
    }
    
//MARK: CORE DATA PRIVATE METHODS
    
    func saveDocToCoreData(documentObj: [String:Any]) {
        let document = NSEntityDescription.insertNewObject(forEntityName: "PromptDoc", into: context!) as! PromptDoc
        document.docTitle = "\(documentObj["documentName"]!)"
        document.docText = "\(documentObj["documentDescription"]!)"
        document.docAttText = documentObj["documentAttrText"] as! NSAttributedString
        document.editTextSize = Int16(documentObj["editDocumentSize"] as! Int)
        document.proptSpeed = Int16(documentObj["promptDocumentSpeed"] as! Int)
        document.promptTextSize = Int16(documentObj["promptDocumentTextSize"] as! Int)
        document.updateDate = Date() as Date
        do {
            try context?.save()
            print("saved to the coreData")
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    /**
     can be used in done action in setlistVC
     
     let context = PrompsterAppDelegate.appDelegateReference().managedObjectContext

     let songsToBeAdded = selectedSongs.sortedArray(using: [NSSortDescriptor(key: "docTitle", ascending: true)])

     for docSet in selectedSetsForMove {
     let allSongsForGivenSet = docSet.fixedSortingIndexArray().value(forKey: "promptDoc") as? [AnyHashable]
     let sortIndex = allSongsForGivenSet != nil ? allSongsForGivenSet?.count : 0 ?? 0
     for song in songsToBeAdded {
     if !allSongsForGivenSet.contains(song) {
     let rel = NSEntityDescription.insertNewObject(forEntityName: NSStringFromClass(DocSetRelation.self.self), into: context) as? DocSetRelation
     rel?.docSet = docSet
     rel?.promptDoc = song
     rel?.index = NSNumber(value: sortIndex)
     
     song.addDocSetRelationObject(rel)
     docSet.addDocSetRelationObject(rel)
     
     sortIndex += 1
     } else {
     print("song is already exist in setlist")
     }
     }
     */
    
    
    func getAllDocumentsFromEntity() -> [PromptDoc] {
        // Create Fetch Request
        var arr = [PromptDoc]()
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "PromptDoc")

        // Add Sort Descriptor
        let sortDescriptor = NSSortDescriptor(key: "docTitle", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]

        do {
            let records = try context!.fetch(fetchRequest) as! [NSManagedObject]
            arr = records as! [PromptDoc]
            for record in records {
                print(record.value(forKey: "docTitle") ?? "no name")
            }

        } catch {
            print(error)
        }
        return arr
    }
    
    
    
    func setWelcomeText() -> String{
        let path = Bundle.main.url(forResource: "welcome", withExtension: "txt")
        var string = ""
        do {
            string = try String(contentsOf: path!)
        } catch let err {
            print(err.localizedDescription)
        }
        return string
    }
    
    //    MARK:- Manage iCloud Data
    
    func saveWelcomeText() {
        let welcomeText = self.setWelcomeText()
        var gigAttrText = NSAttributedString()
        gigAttrText = NSAttributedString(string: welcomeText)
        
        let dict = ["documentName": "About Gig Hards","documentDescription": welcomeText ,"documentAttrText": gigAttrText,"editDocumentSize": 14,"promptDocumentTextSize": 20,"promptDocumentSpeed": 1] as [String : Any]
        
        var noteRecord: CKRecord!
        let date = Date()
        let noteID = CKRecord.ID(recordName: "\(date)")
        noteRecord = CKRecord(recordType: "PromptDocuments", recordID: noteID)
        
        noteRecord.setObject("\(dict["documentName"]!)" as __CKRecordObjCValue?, forKey: "documentName")
        noteRecord.setObject("\(dict["documentDescription"]!)" as __CKRecordObjCValue?, forKey: "documentDescription")
        noteRecord.setObject(Int16(dict["editDocumentSize"] as! Int) as __CKRecordObjCValue?, forKey: "editDocumentSize")
        noteRecord.setObject(Int16(dict["promptDocumentSpeed"] as! Int) as __CKRecordObjCValue?, forKey: "promptDocumentSpeed")
        noteRecord.setObject(Int16(dict["promptDocumentTextSize"] as! Int) as __CKRecordObjCValue?, forKey: "promptDocumentTextSize")
        
        let data = NSKeyedArchiver.archivedData(withRootObject: dict["documentAttrText"] as! NSAttributedString)
        //        print(data)
        noteRecord.setObject(data as __CKRecordObjCValue?, forKey: "documentAttrText")
        noteRecord.setObject(NSDate(), forKey: "docUpdateDate")
        let container = CKContainer.default()
        let privateDatabase = container.privateCloudDatabase
        privateDatabase.save(noteRecord) { (record, error) in
            if let error = error {
                print(error)
//                       completionHandler(noteRecord)
            } else {
//                       completionHandler(noteRecord)
                print("Saved")
            }
        }
    }
    
    func savingNote(editRecord: CKRecord?, documentObj: [String:Any], completionHandler: @escaping(_ success: CKRecord?) -> Void) {
        var noteRecord: CKRecord!
        if let editedNote = editRecord  {
            noteRecord = editedNote
//            self.updateRecordInPlaylist(editRecord: noteRecord, documentObj: documentObj)
        }
        else {
            let date = Date()
            let noteID = CKRecord.ID(recordName: "\(date)")
            noteRecord = CKRecord(recordType: "PromptDocuments", recordID: noteID)
        }
        
        noteRecord.setObject("\(documentObj["documentName"]!)" as __CKRecordObjCValue?, forKey: "documentName")
        noteRecord.setObject("\(documentObj["documentDescription"]!)" as __CKRecordObjCValue?, forKey: "documentDescription")
        noteRecord.setObject(Int16(documentObj["editDocumentSize"] as! Int) as __CKRecordObjCValue?, forKey: "editDocumentSize")
        noteRecord.setObject(Int16(documentObj["promptDocumentSpeed"] as! Int) as __CKRecordObjCValue?, forKey: "promptDocumentSpeed")
        noteRecord.setObject(Int16(documentObj["promptDocumentTextSize"] as! Int) as __CKRecordObjCValue?, forKey: "promptDocumentTextSize")
        
        let data = NSKeyedArchiver.archivedData(withRootObject: documentObj["documentAttrText"] as! NSAttributedString)
        //        print(data)
        noteRecord.setObject(data as __CKRecordObjCValue?, forKey: "documentAttrText")
        noteRecord.setObject(NSDate(), forKey: "docUpdateDate")
        let container = CKContainer.default()
        let privateDatabase = container.privateCloudDatabase
        privateDatabase.save(noteRecord) { (record, error) in
            if let error = error {
                print(error)
                completionHandler(noteRecord)
            } else {
                completionHandler(noteRecord)
            }
        }
        
    }
    
    func updateNameInPlaylistData(oldName: String, newName: String, completionHandler: @escaping(_ success: Bool) -> Void) {
        self.fetchIcloudPlaylists { (allPlaylists) in
            let allLists = allPlaylists
            for playlist in allLists {
                var data = Data()
                var arr = [[String:Any]]()
                if playlist.value(forKey: "playlistData") != nil {
                    data = playlist.value(forKey: "playlistData") as! Data
                    arr = NSKeyedUnarchiver.unarchiveObject(with: data) as! [[String:Any]]
                } else {
                    arr.removeAll()
                }
//                let data = playlist.value(forKey: "playlistData") as! Data
//                var arr = NSKeyedUnarchiver.unarchiveObject(with: data) as! [[String:Any]]
//                var dataSongs = arr
                if arr.count > 0 {
                    for index in 0...arr.count - 1 {
                        if oldName == "\(arr[index]["documentName"]!)" {
                            arr[index]["documentName"] = newName
                        } else {
                            
                        }
                    }
                }
                let playlistName = playlist.value(forKey: "playlistName") as! String
                let playlistData = arr
                let dict = ["playlistName": playlistName, "playlistData":playlistData] as [String : Any]
                self.savingPlaylist(editRecord: playlist, documentObj: dict) { (newData) in
                    DispatchQueue.main.async {
//                        let data = newData!.value(forKey: "playlistData") as? Data
//                        var arr = NSKeyedUnarchiver.unarchiveObject(with: data) as! [[String:Any]]
//                        print(arr)
                    }
                }
            }
            completionHandler(true)
        }
    }
    
    
    
    func updateRecordInPlaylist(editRecord: CKRecord?, documentObj: [String:Any],completionHandler: @escaping(_ success: Bool) -> Void) {
        
        self.fetchIcloudPlaylists { (allPlaylistData) in
            self.allPlaylists = allPlaylistData
            if self.allPlaylists.count == 0 {
                completionHandler(true)
            } else {
                var updatedPlaylistArr = [[String:Any]]()
                for playlist in self.allPlaylists {
                    updatedPlaylistArr.removeAll()
                    if playlist.value(forKey: "playlistData") == nil {
                        
                    } else {
                        let data = playlist.value(forKey: "playlistData") as! Data
                        let arr = NSKeyedUnarchiver.unarchiveObject(with: data) as! [[String:Any]]
                        for playlistData in arr {
                            if editRecord?.value(forKey: "documentName") as! String == "\(playlistData["documentName"]!)" {
                                //                        print(playlistData)
                                updatedPlaylistArr.append(documentObj)
                            } else {
                                updatedPlaylistArr.append(playlistData)
                            }
                        }
                        if updatedPlaylistArr.count > 0 {
                            let playlistName = playlist.value(forKey: "playlistName") as! String
                            let playlistData = updatedPlaylistArr
                            let dict = ["playlistName": playlistName, "playlistData":playlistData] as [String : Any]
                            //                self.savePlaylist(editRecord: playlist, documentObj: dict)
                            self.savingPlaylist(editRecord: playlist, documentObj: dict) { (plyRecord) in
                                print("Playlist Saved Successfully")
                                completionHandler(true)
                            }
                        }
                    }
                    //            updatedPlaylistArr.removeAll()
                }
                completionHandler(false)
            }
        }
    }
    
    func fetchNotes(completionHandler: @escaping(_ success: [CKRecord]) -> Void) -> [CKRecord] {
        var allNotes = [CKRecord]()
        let container = CKContainer.default()
        let privateDatabase = container.privateCloudDatabase
        let predicate = NSPredicate(value: true)
        
        let query = CKQuery(recordType: "PromptDocuments", predicate: predicate)
        
        privateDatabase.perform(query, inZoneWith: nil) { (results, error) -> Void in
            if error != nil {
                print(error!)
            }
            else {
                self.allNotes.removeAll()
                for result in results! {
                    self.allNotes.append(result)
                }
                completionHandler(self.allNotes)
            }
        }
        return allNotes
    }
    
    func deleteiCloudRecord(recordName: String?) {
        var ckRecord : CKRecord?
        let container = CKContainer.default()
        let privateDatabase = container.privateCloudDatabase
        let predicate = NSPredicate(value: true)
        
        let query = CKQuery(recordType: "PromptDocuments", predicate: predicate)
        privateDatabase.perform(query, inZoneWith: nil) { (results, error) -> Void in
            if error != nil {
                print(error!)
            }
            else {
                for result in results! {
                    if recordName != nil {
                        if "\(result.value(forKey: "documentName")!)" == "\(recordName!)" {
                            ckRecord = result
                            let selectedRecordID = ckRecord!.recordID
                            
                            let container = CKContainer.default()
                            let privateDatabase = container.privateCloudDatabase
                            
                            privateDatabase.delete(withRecordID: selectedRecordID) { (recordID, error) in
                                if error != nil {
                                    print(error?.localizedDescription)
                                } else {
                                    print("Record Deleted Successfully")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func savingPlaylist(editRecord: CKRecord?, documentObj: [String:Any], completionHandler: @escaping(_ success: CKRecord?) -> Void) {
        var noteRecord: CKRecord!
        if let editedNote = editRecord  {
            noteRecord = editedNote
        }
        else {
            let date = Date()
            let noteID = CKRecord.ID(recordName: "\(date)")
            noteRecord = CKRecord(recordType: "PromptPlaylist", recordID: noteID)
        }
        
        noteRecord.setObject("\(documentObj["playlistName"]!)" as __CKRecordObjCValue?, forKey: "playlistName")
    if editRecord != nil {
        let arrData = NSMutableData()
        let arr = documentObj["playlistData"] as! [[String:Any]]
        let data: Data = NSKeyedArchiver.archivedData(withRootObject: arr)
//        print(data)
        noteRecord.setObject(data as! __CKRecordObjCValue, forKey: "playlistData")
    } else {
        noteRecord.setObject(nil, forKey: "playlistData")
    }
    
    let container = CKContainer.default()
        let privateDatabase = container.privateCloudDatabase
        privateDatabase.save(noteRecord) { (record, error) in
            if let error = error {
                print(error)
                completionHandler(nil)
            } else {
                print("saved: \(record!)")
                completionHandler(noteRecord)
            }
        }
    }
    
    func updatePlaylistName(editRecord: CKRecord?, playlistname: String?, completionHandler: @escaping(_ success: Bool?) -> Void) {
        var noteRecord: CKRecord!
        if let editedNote = editRecord  {
            noteRecord = editedNote
        }
        else {
            let date = Date()
            let noteID = CKRecord.ID(recordName: "\(date)")
            noteRecord = CKRecord(recordType: "PromptPlaylist", recordID: noteID)
        }
        noteRecord.setObject("\(playlistname!)" as __CKRecordObjCValue?, forKey: "playlistName")
        let container = CKContainer.default()
        let privateDatabase = container.privateCloudDatabase
        privateDatabase.save(noteRecord) { (record, error) in
            if let error = error {
                print(error)
                completionHandler(false)
            } else {
                print("saved: \(record!)")
                completionHandler(true)
            }
        }
    }
    
    func fetchIcloudPlaylists(completionHandler: @escaping(_ success: [CKRecord]) -> Void) -> [CKRecord] {
        var allNotes = [CKRecord]()
        let container = CKContainer.default()
        let privateDatabase = container.privateCloudDatabase
        let predicate = NSPredicate(value: true)
        
        let query = CKQuery(recordType: "PromptPlaylist", predicate: predicate)
        
        privateDatabase.perform(query, inZoneWith: nil) { (results, error) -> Void in
            if error != nil {
                print(error!)
            }
            else {
                self.allPlaylists.removeAll()
                for result in results! {
                    self.allPlaylists.append(result)
                }
                completionHandler(self.allPlaylists)
            }
        }
        return allNotes
    }
    
    func deleteiCloudPlaylist(recordName: CKRecord) {
        let selectedRecordID = recordName.recordID
        
        let container = CKContainer.default()
        let privateDatabase = container.privateCloudDatabase
        
        privateDatabase.delete(withRecordID: selectedRecordID) { (recordID, error) in
            if error != nil {
                print(error?.localizedDescription)
            } else {
                print("delete success!")
            }
        }
    }
    
    func deleteSong(recordName: CKRecord, completionHandler: @escaping(_ success: Bool?) -> Void) {
        let selectedRecordID = recordName.recordID
        
        let container = CKContainer.default()
        let privateDatabase = container.privateCloudDatabase
        
//        self.deleteSongInPlaylist(editRecord: recordName)
        privateDatabase.delete(withRecordID: selectedRecordID) { (recordID, error) in
            if error != nil {
                print(error?.localizedDescription)
                completionHandler(false)
            } else {
                print("delete success from all songs!")
                completionHandler(true)
            }
        }
    }
    
    func deleteSongInPlaylist(editRecord: CKRecord?) {
      self.fetchIcloudPlaylists { (ckrecords) in
            self.allPlaylists = ckrecords

            var updatedPlaylistArr = [[String:Any]]()
            for playlist in self.allPlaylists {
                updatedPlaylistArr.removeAll()
                if playlist.value(forKey: "playlistData") == nil {

                } else {
                    let data = playlist.value(forKey: "playlistData") as! Data
                    let arr = NSKeyedUnarchiver.unarchiveObject(with: data) as! [[String:Any]]
                    for playlistData in arr {
                        if editRecord?.value(forKey: "documentName") as! String == "\(playlistData["documentName"]!)" {
//                            print(playlistData)

                        } else {
                            updatedPlaylistArr.append(playlistData)
                        }
                    }

                }
                let playlistName = playlist.value(forKey: "playlistName") as! String
                let playlistData = updatedPlaylistArr
                let dict = ["playlistName": playlistName, "playlistData":playlistData] as [String : Any]
                self.savingPlaylist(editRecord: playlist, documentObj: dict) { (plyRecord) in
                    print("Song deleted from playlist")
                }
            }
        }
    }
    
    
    func saveRecToIcloud(editRecord: CKRecord?,recData: Data,recUrl:String, completionHandler: @escaping(_ success: Bool?) -> Void) {
        var noteRecord: CKRecord!
        if let editedNote = editRecord  {
            noteRecord = editedNote
        }
        else {
            let date = Date()
            let noteID = CKRecord.ID(recordName: "\(date)")
            noteRecord = CKRecord(recordType: "Recordings", recordID: noteID)
        }
        do {
            noteRecord.setObject(recUrl as __CKRecordObjCValue?, forKey: "recordingStr")
            noteRecord.setObject(recData as __CKRecordObjCValue?, forKey: "recordingData")
            let container = CKContainer.default()
            let privateDatabase = container.privateCloudDatabase
            privateDatabase.save(noteRecord) { (record, error) in
                if let error = error {
                    print(error)
                    completionHandler(false)
                } else {
                    print("saved: \(record!)")
                    completionHandler(true)
                }
            }
        } catch {
            print("Unable to load data: \(error)")
        }
    }
    
    func fetchAllRecordings(completionHandler: @escaping(_ recordedUrls: [CKRecord]) -> Void) {
        var allRecordings = [CKRecord]()
        let container = CKContainer.default()
        let privateDatabase = container.privateCloudDatabase
        let predicate = NSPredicate(value: true)
        
        let query = CKQuery(recordType: "Recordings", predicate: predicate)
        
        privateDatabase.perform(query, inZoneWith: nil) { (results, error) -> Void in
            if error != nil {
                print(error!)
            }
            else {
                allRecordings.removeAll()
                for result in results! {
                    allRecordings.append(result)
                }
                completionHandler(allRecordings)
            }
        }
    }
    
    func deleteRecording(selectedRecording: CKRecord, completionHandler: @escaping(_ success: Bool?) -> Void) {
        let selectedRecordID = selectedRecording.recordID
        
        let container = CKContainer.default()
        let privateDatabase = container.privateCloudDatabase
        
        privateDatabase.delete(withRecordID: selectedRecordID) { (recordID, error) in
            if error != nil {
                print(error?.localizedDescription)
                completionHandler(false)
            } else {
                print("recording deleted!")
                completionHandler(true)
            }
        }
    }
    
}
