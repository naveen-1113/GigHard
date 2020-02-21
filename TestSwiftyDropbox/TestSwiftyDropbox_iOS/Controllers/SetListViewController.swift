//
//  SetListViewController.swift
//  GigHard_Swift
//
//  Created by osx on 27/11/19.
//  Copyright © 2019 osx. All rights reserved.
//

import UIKit
import CoreData
import CloudKit
import MBProgressHUD

protocol PromptSongDelegate {
//    func selectedPromptSong(promptSong: PromptDocument, indexValue:Int?)
    func selectPromptRecord(promptRecord: CKRecord, indexValue: Int?)
    func selectSongFromSortedList(song: [String:Any], indexValue:Int?)
}
class SetListViewController: UIViewController, UIScrollViewDelegate {

//    MARK:- VARIABLE(S) AND OUTLET(S)

    @IBOutlet weak var setListTableView: UITableView!
    @IBOutlet weak var segmentOutlet: UISegmentedControl!
    @IBOutlet weak var topBarSelect: UIView!
    @IBOutlet weak var settingsBtn: UIButton!
    @IBOutlet weak var addBtn: UIButton!
    @IBOutlet weak var selectBtn: UIButton!
    @IBOutlet weak var cancelBtn: UIButton!
    @IBOutlet weak var deleteBtn: UIButton!
    @IBOutlet weak var moveBtn: UIButton!
    @IBOutlet weak var DoneBtn: UIButton!
    @IBOutlet weak var selectAllBtn: UIButton!
    @IBOutlet weak var searchBarOutlet: UISearchBar!
    @IBOutlet weak var allPlaylistLbl: UILabel!
    
    var allIcloudSongs = [CKRecord]()
    var allIcloudPlaylists = [CKRecord]()
    var playListsIndexValues = [Int]()
    var selectedSongs = [CKRecord]()
    var selectedPlayListArr = [CKRecord]()
    var updatePlaylist: CKRecord?
    var selectedPlyListIndexs = [Int]()
    var selectedSearchedPlaylistIndexes = [Int]()
    var tempSortedListArr = [[String:Any]]()
    var filteredUpdatedData = [[String:Any]]()
    var delegate:PromptSongDelegate?
    var isSelect = false
    var isMove = Bool()
    var isPrompt:Bool = false
    
    var plylistIndex: Int?
    var searchEnabled = Bool()
    var searchSongss = [CKRecord]()
    var searchPlaylists = [CKRecord]()
    var isDocExist:Bool! = false
    var isPlayListExist:Bool! = false
    var staticPlaylistArr = [CKRecord]()
    
    lazy var refreshing: UIRefreshControl = {
      let refreshControl = UIRefreshControl()
        refreshControl.tintColor = .darkGray
        refreshControl.addTarget(self, action: #selector(requestData), for: .valueChanged)
        return refreshControl
    }()
    
//    MARK:- VIEW LIFECYCLE METHOD(S)
    override func viewDidLoad() {
        super.viewDidLoad()
//        MBProgressHUD.showAdded(to: self.view, animated: true)
        self.checkInternetConnection()
        isMove = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.fetchNotes(completion: { (allNotes) in
                if let data = allNotes {
                    DispatchQueue.main.async {
                        self.allIcloudSongs = data
                        let sortedSongs = self.allIcloudSongs.sorted { a, b in
                            
                            return (a.value(forKey: "documentName") as! String)
                                .localizedStandardCompare(b.value(forKey: "documentName") as! String)
                                == ComparisonResult.orderedAscending
                        }
                        self.allIcloudSongs = sortedSongs
                        self.setListTableView.reloadData()
                    }
                }
            })
        }
        self.allIcloudPlaylists = self.fetchPlaylists(completion: { (allList) in
            if allList?.count ?? 0 > 0 {
                self.allIcloudPlaylists = allList!
                self.playListsIndexValues.removeAll()
                if self.allIcloudPlaylists.count != 0 {
                    for index in 0...self.allIcloudPlaylists.count - 1 {
                        self.playListsIndexValues.append(index)
                    }
                }
            }
        })
        
        if isSelect {
            self.tempSortedListArr = UserDefaults.standard.array(forKey: "sortedListArr") as! [[String : Any]]
        }
        self.setupSetListLayout()
        self.setListTableView.refreshControl = refreshing
        self.setListTableView.register(UINib(nibName: "AllSongsTableViewCell", bundle: nil), forCellReuseIdentifier: "AllSongsTableViewCellReuse")
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
            MBProgressHUD.hide(for: self.view, animated: true)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.fetchNotes { (allDocuments) in
            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.view, animated: true)
            }
        }
        self.hideLayouts()
        if self.segmentOutlet.selectedSegmentIndex == 0 {
            self.addBtn.isHidden = false
            self.selectBtn.isHidden = false
            self.settingsBtn.isHidden = false
        }else if segmentOutlet.selectedSegmentIndex == 1 {
            self.addBtn.isHidden = false
            self.settingsBtn.isHidden = false
        }
        self.isSelect = false
        self.setListTableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.selectedSearchedPlaylistIndexes.removeAll()
        self.selectedSongs.removeAll()
        self.selectedPlayListArr.removeAll()
        self.selectedPlyListIndexs.removeAll()
        if searchEnabled {
            self.searchBarOutlet.searchTextField.resignFirstResponder()
            self.searchBarOutlet.searchTextField.text = ""
        }
        self.searchEnabled = false
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.view.endEditing(true)
    }
    
    //    MARK:- IBACTIONS
    @IBAction func segmentAction(_ sender: UISegmentedControl) {
        selectedSearchedPlaylistIndexes.removeAll()
        self.allIcloudPlaylists = self.fetchPlaylists(completion: { (allList) in
            if allList?.count ?? 0 > 0 {
                self.allIcloudPlaylists = allList!
                if self.allIcloudPlaylists.count != 0 {
                    self.playListsIndexValues.removeAll()
                    for index in 0...self.allIcloudPlaylists.count - 1 {
                        self.playListsIndexValues.append(index)
                    }
                }
            }
        })
        if segmentOutlet.selectedSegmentIndex == 0 {
            self.cancelBtn.isHidden = true
            self.deleteBtn.isHidden = true
            self.moveBtn.isHidden = true
            self.DoneBtn.isHidden = true
            self.selectAllBtn.isHidden = true
            self.addBtn.isHidden = false
            self.settingsBtn.isHidden = false
            self.selectBtn.isHidden = false
            if searchEnabled {
                self.searchBarOutlet.searchTextField.resignFirstResponder()
                self.searchBarOutlet.searchTextField.text = ""
            }
            self.searchEnabled = false
        }else if segmentOutlet.selectedSegmentIndex == 1 {
            MBProgressHUD.showAdded(to: self.view, animated: true)
            self.selectBtn.isHidden = true
            self.cancelBtn.isHidden = true
            self.deleteBtn.isHidden = true
            self.moveBtn.isHidden = true
            self.DoneBtn.isHidden = true
            self.selectAllBtn.isHidden = true
            self.addBtn.isHidden = false
            self.settingsBtn.isHidden = false
            self.setListTableView.isEditing = false
            if searchEnabled {
                self.searchBarOutlet.searchTextField.resignFirstResponder()
                self.searchBarOutlet.searchTextField.text = ""
            }
            self.searchEnabled = false
        }
        isSelect = false
        self.setListTableView.reloadData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            MBProgressHUD.hide(for: self.view, animated: true)
        }
    }
    
    @IBAction func settingsAction(_ sender: Any) {
        let settingsVC = self.storyboard?.instantiateViewController(withIdentifier: "SettingsViewControllerID") as! SettingsViewController
        settingsVC.isDismissFromSetList = true
        self.navigationController?.pushViewController(settingsVC, animated: true)
    }
    
    @IBAction func selectAction(_ sender: UIButton) {
        self.selectedSongs.removeAll()
        self.selectBtn.isHidden = true
        self.addBtn.isHidden = true
        self.selectAllBtn.isHidden = false
        if isSelect {
            isSelect = false
//            self.setListTableView.reloadData()
            for song in selectedSongs {
                let dict = ["docName": song.value(forKey: "documentName"),"docDescription":song.value(forKey: "documentDescription")]
                self.tempSortedListArr.append(dict as [String : Any])
            }
            UserDefaults.standard.set(tempSortedListArr, forKey: "sortedListArr")
        } else {
            isSelect = true
            self.setListTableView.reloadData()
        }
//        self.setListTableView.isEditing = true
//        self.setListTableView.allowsMultipleSelection = true
//        self.setListTableView.allowsMultipleSelectionDuringEditing = true
    }
    
    @IBAction func cancelAction(_ sender: UIButton) {
        self.selectedSearchedPlaylistIndexes.removeAll()
        self.selectedSongs.removeAll()
        self.selectedPlayListArr.removeAll()
        self.selectedPlyListIndexs.removeAll()
        if segmentOutlet.selectedSegmentIndex == 0 {
            self.hideLayouts()
            self.settingsBtn.isHidden = false
            self.selectBtn.isHidden = false
            self.addBtn.isHidden = false
        } else if segmentOutlet.selectedSegmentIndex == 1 {
            self.hideLayouts()
            self.addBtn.isHidden = false
            self.settingsBtn.isHidden = false
        }
        self.segmentOutlet.isHidden = false
        self.allPlaylistLbl.isHidden = true
        isSelect = false
        isMove = false
        setListTableView.reloadData()
    }
    
    @IBAction func deleteAction(_ sender: UIButton) {
        let msg = "Permanently delete and remove selected song(s) from all Set Lists?"
        let alertController = UIAlertController(title: "Gig Hard!", message: msg, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "No", style: .cancel, handler: nil)
        let doneAction = UIAlertAction(title: "Yes", style: .default) { UIAlertAction in
//            let deletedSongs = self.selectedSongsArr
            MBProgressHUD.showAdded(to: self.view, animated: true)
            let deletedSongs = self.selectedSongs  // MARK: - while change to icloud
            
            for sng in deletedSongs {
                DatabaseHelper.shareInstance.deleteSongInPlaylist(editRecord: sng)
            }
            
            for song in deletedSongs {
                
                DatabaseHelper.shareInstance.deleteSong(recordName: song) { (isSuccess) in
                    DispatchQueue.main.async {
                        MBProgressHUD.hide(for: self.view, animated: true)
                        self.fetchNotes { (allRecords) in
                            DispatchQueue.main.async {
                                self.allIcloudSongs = allRecords ?? []
                                let sortedSongs = self.allIcloudSongs.sorted { a, b in
                                    return (a.value(forKey: "documentName") as! String)
                                        .localizedStandardCompare(b.value(forKey: "documentName") as! String)
                                        == ComparisonResult.orderedAscending
                                }
                                self.allIcloudSongs = sortedSongs
                                self.setListTableView.reloadData()
                            }
                        }
                    }
                }
                MBProgressHUD.hide(for: self.view, animated: true)
            }
            // Initialize Fetch Request
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "PromptDocument")
            let managedObjectContext = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext
            // Configure Fetch Request
            fetchRequest.includesPropertyValues = false

            do {
                for item in deletedSongs {
//                    managedObjectContext?.delete(item)
                }

                // Save Changes
                try managedObjectContext?.save()

            } catch {
                // Error Handling
                // ...
            }
            
            self.fetchNotes(completion: { (allNotes) in
                if let data = allNotes {
                    DispatchQueue.main.async {
                        self.allIcloudSongs = data
                        let sortedSongs = self.allIcloudSongs.sorted { a, b in
                            
                            return (a.value(forKey: "documentName") as! String)
                                .localizedStandardCompare(b.value(forKey: "documentName") as! String)
                                == ComparisonResult.orderedAscending
                        }
                        self.allIcloudSongs = sortedSongs
                        self.setListTableView.reloadData()
                    }
                }
            })
//            self.selectedSongsArr.removeAll()
            self.selectedSongs.removeAll()
            self.isSelect = false
            self.hideLayouts()
            self.settingsBtn.isHidden = false
            self.selectBtn.isHidden = false
            self.addBtn.isHidden = false
            DispatchQueue.main.async {
                self.setListTableView.reloadData()
            }
        }
        alertController.addAction(cancelAction)
        alertController.addAction(doneAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func moveAction(_ sender: UIButton) {
        selectedSearchedPlaylistIndexes.removeAll()
        self.hideLayouts()
        self.segmentOutlet.isHidden = true
        self.cancelBtn.isHidden = false
        self.allPlaylistLbl.isHidden = false
        self.isMove = true
        isSelect = false
        self.setListTableView.allowsMultipleSelection = true
        self.setListTableView.allowsMultipleSelectionDuringEditing = true
        if searchEnabled {
//            self.searchBarOutlet.searchTextField.text = ""
        }
        self.searchEnabled = false
        self.segmentOutlet.selectedSegmentIndex = 1
        self.setListTableView.reloadData()
    }
    
    @IBAction func doneAction(_ sender: UIButton) {
        //worked
        self.hideLayouts()
        self.isMove = false
        self.segmentOutlet.isHidden = false
        self.settingsBtn.isHidden = false
        self.selectBtn.isHidden = true
        self.addBtn.isHidden = false
        self.allPlaylistLbl.isHidden = true
        MBProgressHUD.showAdded(to: self.view, animated: true)
        var updateData = [[String:Any]]()

            for song in selectedSongs {
                
                let songName = "\(song.value(forKey: "documentName")!)"
                let songDes = "\(song.value(forKey: "documentDescription")!)"
                let songEditTxtSize = song.value(forKey: "editDocumentSize")
                let songPromptTxtSize = song.value(forKey: "promptDocumentTextSize")
                let songPromptSpeed = song.value(forKey: "promptDocumentSpeed")
                let songAttrText = song.value(forKey: "documentAttrText") as! Data
                let songDate = song.value(forKey: "docUpdateDate")
                let songDict =  ["documentName":songName,"documentDescription":songDes,"documentAttrText":songAttrText,"editDocumentSize":songEditTxtSize!,"promptDocumentTextSize":songPromptTxtSize!,"promptDocumentSpeed":songPromptSpeed!,"docUpdateDate":songDate!] as [String : Any]
                updateData.append(songDict)
            }
            for plalst in selectedPlayListArr {
//                print(plalst)
                self.updatePlaylist = plalst
                let playlistName = updatePlaylist?.value(forKey: "playlistName")
                if updatePlaylist!.value(forKey: "playlistData") == nil {
                        
                } else {
                    let data = plalst.value(forKey: "playlistData") as! Data
                    let arr = NSKeyedUnarchiver.unarchiveObject(with: data) as! [[String:Any]]
                    for data in arr {
                        updateData.append(data)
                    }
                }
                let orderedSet : NSOrderedSet = NSOrderedSet(array: updateData)
                filteredUpdatedData = orderedSet.array as! [[String : Any]]
                
                if selectedPlayListArr.count == 0 {

                }else{
                    let movingDict = ["playlistData":filteredUpdatedData, "playlistName": playlistName!]
                    DatabaseHelper.shareInstance.savingPlaylist(editRecord: plalst, documentObj: movingDict) { (record) in
                        DispatchQueue.main.async {
                            MBProgressHUD.hide(for: self.view, animated: true)
                            self.fetchPlaylists { (allList) in
                                if allList?.count ?? 0 > 0 {
                                    self.allIcloudPlaylists = allList!
                                    self.playListsIndexValues.removeAll()
                                    if self.allIcloudPlaylists.count != 0 {
                                        for index in 0...self.allIcloudPlaylists.count - 1 {
                                            self.playListsIndexValues.append(index)
                                        }
                                    }
                                }
                            }
                        }
                    }
//                    for index in self.selectedPlyListIndexs {
//                        if updatePlaylist != nil {
//
//                            let movingDict = ["playlistData":filteredUpdatedData, "playlistName": playlistName!]
//                            if updatePlaylist!.value(forKey: "playlistData") == nil {
//                                DatabaseHelper.shareInstance.savingPlaylist(editRecord: updatePlaylist, documentObj: movingDict) { (plyRecord) in
//                                    DispatchQueue.main.async {
//                                        MBProgressHUD.hide(for: self.view, animated: true)
//                                        self.fetchPlaylists()
//                                    }
//                                }
//                            } else {
//                                DatabaseHelper.shareInstance.savingPlaylist(editRecord: updatePlaylist, documentObj: movingDict) { (plyRecord) in
//                                    DispatchQueue.main.async {
//                                        MBProgressHUD.hide(for: self.view, animated: true)
//                                        self.fetchPlaylists()
//                                    }
//                                }
//                            }
//                        }
//                    }
                }
            }

        
        self.selectedSongs.removeAll()
        self.searchEnabled = false
        
        if selectedPlayListArr.count == 1 {          // MARK:FOR MOVE TO NEXT SCREEN (selectedPlyListIndexs)
            for index in 0...self.allIcloudPlaylists.count - 1 {
                if self.selectedPlayListArr[0].value(forKey: "playlistName") as! String == self.allIcloudPlaylists[index].value(forKey: "playlistName") as! String {
                    self.plylistIndex = index
                }
            }
            
            self.selectedPlyListIndexs.removeAll()
            self.selectedPlayListArr.removeAll()
            let favSongsVC = self.storyboard?.instantiateViewController(withIdentifier: "FavSongsViewControllerID") as! FavSongsViewController
            favSongsVC.promPlaylist = self.allIcloudPlaylists[self.plylistIndex!]
            self.navigationController?.pushViewController(favSongsVC, animated: true)
        } else {
            self.selectedPlayListArr.removeAll()
            self.selectedPlyListIndexs.removeAll()
            isSelect = false
            self.segmentOutlet.selectedSegmentIndex = 1
            self.setListTableView.reloadData()
        }
    }
    
    @IBAction func selectAllAction(_ sender: UIButton) {
        self.selectAllBtn.isHidden = true
        self.settingsBtn.isHidden = true
        self.cancelBtn.isHidden = false
        self.deleteBtn.isHidden = false
        self.moveBtn.isHidden = false
        isSelect = true
        let totalRows = setListTableView.numberOfRows(inSection: 0)
        for row in 0..<totalRows {
            setListTableView.selectRow(at: IndexPath(row: row, section: 0), animated: false, scrollPosition: UITableView.ScrollPosition.none)
        }
//        selectedSongsArr = allSongsArr
        self.selectedSongs = self.allIcloudSongs
    }
    
    @IBAction func addAction(_ sender: UIButton) {
        if segmentOutlet.selectedSegmentIndex == 0 {
            let addNewDocVC = self.storyboard?.instantiateViewController(withIdentifier: "NewDocumentViewControllerID") as! NewDocumentViewController
            addNewDocVC.delegate = self
            self.navigationController?.pushViewController(addNewDocVC, animated: true)
        }else if segmentOutlet.selectedSegmentIndex == 1 {
            let alertAddList = UIAlertController(title: nil, message: "Add Set List", preferredStyle: .alert)
            alertAddList.addTextField { (textField) in
                textField.delegate = self
                textField.placeholder = "Set List Name"
                textField.layer.cornerRadius = 4
                textField.autocapitalizationType = .words
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            let okAction = UIAlertAction(title: "OK", style: .default) { UIAlertAction in
                MBProgressHUD.showAdded(to: self.view, animated: true)
                let playlistName = alertAddList.textFields![0].text
                let arr = [String:Any]()
                if playlistName == "" {
                    
                }else{
                    DatabaseHelper.shareInstance.fetchIcloudPlaylists { (allPlaylists) in
                        DispatchQueue.main.async {
                            let allPlLists = allPlaylists
                            for playlist in allPlLists {
                                if playlist.value(forKey: "playlistName") as! String == "\(alertAddList.textFields![0].text!)" {
                                    self.isPlayListExist = true
                                }
                            }
                            if self.isPlayListExist {
                                self.isPlayListExist = false
                                let alert = UIAlertController(title: "Gig Hards!", message: "This name is already exist in your list please choose different name for your playlist.", preferredStyle: .alert)
                                //                                let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                                alert.addAction(cancelAction)
                                DispatchQueue.main.async {
                                    MBProgressHUD.hide(for: self.view, animated: true)
                                    self.present(alert, animated: true, completion: nil)
                                }
                            } else {
                                let playlistDict = ["playlistName": playlistName!,"playlistData":arr ] as [String: Any]
                                DatabaseHelper.shareInstance.savingPlaylist(editRecord: nil, documentObj: playlistDict) { (plyRecord) in
                                    DispatchQueue.main.async {
                                        MBProgressHUD.hide(for: self.view, animated: true)
                                        self.fetchPlaylists { (allList) in
                                            if allList?.count ?? 0 > 0 {
                                                self.allIcloudPlaylists = allList!
                                                self.playListsIndexValues.removeAll()
                                                if self.allIcloudPlaylists.count != 0 {
                                                    for index in 0...self.allIcloudPlaylists.count - 1 {
                                                        self.playListsIndexValues.append(index)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                self.allIcloudPlaylists = self.fetchPlaylists(completion: { (allList) in
                                    if allList?.count ?? 0 > 0 {
                                        self.allIcloudPlaylists = allList!
                                        self.playListsIndexValues.removeAll()
                                        if self.allIcloudPlaylists.count != 0 {
                                            for index in 0...self.allIcloudPlaylists.count - 1 {
                                                self.playListsIndexValues.append(index)
                                            }
                                        }
                                    }
                                })
                                if self.allIcloudPlaylists.count != 0 {
                                    for index in 0...self.allIcloudPlaylists.count - 1 {
                                        self.playListsIndexValues.append(index)
                                    }
                                }
                                DispatchQueue.main.async {
                                    self.setListTableView.reloadData()
                                }
                            }
                        }
                    }
                }
            }
            alertAddList.addAction(cancelAction)
            alertAddList.addAction(okAction)
            self.present(alertAddList, animated: true, completion: nil)
        }
    }
//    MARK:- PRIVATE METHOD(S)
    @objc func requestData() {
        if self.segmentOutlet.selectedSegmentIndex == 0 {
            self.fetchNotes(completion: { (allNotes) in
                if let data = allNotes {
                    DispatchQueue.main.async {
                        self.allIcloudSongs = data
                        let sortedSongs = self.allIcloudSongs.sorted { a, b in
                            
                            return (a.value(forKey: "documentName") as! String)
                                .localizedStandardCompare(b.value(forKey: "documentName") as! String)
                                == ComparisonResult.orderedAscending
                        }
                        self.allIcloudSongs = sortedSongs
                        self.setListTableView.reloadData()
                    }
                }
            })
        } else if self.segmentOutlet.selectedSegmentIndex == 1 {
            self.fetchPlaylists { (allList) in
                if allList?.count ?? 0 > 0 {
                    self.allIcloudPlaylists = allList!
                    self.playListsIndexValues.removeAll()
                    if self.allIcloudPlaylists.count != 0 {
                        for index in 0...self.allIcloudPlaylists.count - 1 {
                            self.playListsIndexValues.append(index)
                        }
                    }
                }
            }
        } else {
            self.refreshing.endRefreshing()
        }
        
    }
    
    func fetchNotes(completion: @escaping(_ success: [CKRecord]?) -> Void) {
        MBProgressHUD.showAdded(to: self.view, animated: true)
        let container = CKContainer.default()
        let privateDatabase = container.privateCloudDatabase
        let predicate = NSPredicate(value: true)
        
        let query = CKQuery(recordType: "PromptDocuments", predicate: predicate)
        
        privateDatabase.perform(query, inZoneWith: nil) { (results, error) -> Void in
            if error != nil {
                print(error!)
                OperationQueue.main.addOperation({ () -> Void in
                        self.refreshing.endRefreshing()
                        MBProgressHUD.hide(for: self.view, animated: true)
                        self.setListTableView.reloadData()
                })
            }
            else {
                self.allIcloudSongs.removeAll()
                for result in results! {
                    self.allIcloudSongs.append(result)
                }
                let sortedSongs = self.allIcloudSongs.sorted { a, b in
                    
                    return (a.value(forKey: "documentName") as! String)
                        .localizedStandardCompare(b.value(forKey: "documentName") as! String)
                        == ComparisonResult.orderedAscending
                }
                self.allIcloudSongs = sortedSongs
                OperationQueue.main.addOperation({ () -> Void in
                        self.refreshing.endRefreshing()
                        MBProgressHUD.hide(for: self.view, animated: true)
                        self.setListTableView.reloadData()
                })
                completion(self.allIcloudSongs)
            }
        }
    }
    
    func fetchPlaylists(completion: @escaping(_ success: [CKRecord]?) -> Void) -> [CKRecord] {
        MBProgressHUD.showAdded(to: self.view, animated: true)
        let allNotes = [CKRecord]()
        let container = CKContainer.default()
        let privateDatabase = container.privateCloudDatabase
        let predicate = NSPredicate(value: true)
        
        let query = CKQuery(recordType: "PromptPlaylist", predicate: predicate)
        
        privateDatabase.perform(query, inZoneWith: nil) { (results, error) -> Void in
            if error != nil {
                print(error!)
                OperationQueue.main.addOperation({ () -> Void in
                        self.refreshing.endRefreshing()
                        MBProgressHUD.hide(for: self.view, animated: true)
                        self.setListTableView.reloadData()
                })
            }
            else {
                self.allIcloudPlaylists.removeAll()
                for result in results! {
                    self.allIcloudPlaylists.append(result)
                    self.staticPlaylistArr.append(result)
                }
                let sortedPlaylists = self.allIcloudPlaylists.sorted { a, b in
                    
                    return (a.value(forKey: "playlistName") as! String)
                        .localizedStandardCompare(b.value(forKey: "playlistName") as! String)
                        == ComparisonResult.orderedAscending
                }
                self.allIcloudPlaylists = sortedPlaylists
                self.playListsIndexValues.removeAll()
                if self.allIcloudPlaylists.count != 0 {
                    for index in 0...self.allIcloudPlaylists.count - 1 {
                        self.playListsIndexValues.append(index)
                    }
                }
                completion(self.allIcloudPlaylists)
                OperationQueue.main.addOperation({ () -> Void in
                    DispatchQueue.main.async {
                        self.refreshing.endRefreshing()
                        MBProgressHUD.hide(for: self.view, animated: true)
                        self.setListTableView.reloadData()
                    }
                })
            }
        }
        return allNotes
    }
    
    func setupSetListLayout() {
        //self.searchBarOutlet.searchTextField.backgroundColor = UIColor.white // Sam
        self.navigationController?.navigationBar.isHidden = true
        self.segmentOutlet.layer.borderWidth = 1.0
        self.segmentOutlet.layer.borderColor = UIColor.white.cgColor
        self.segmentOutlet.layer.cornerRadius = 4.0
        self.segmentOutlet.setSelectedSegmentColor(with: .gray, and: .gray)
        UISegmentedControl.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)

    }
    
    func hideContentOnselectRow() {
        self.cancelBtn.isHidden = false
        self.deleteBtn.isHidden = false
        self.moveBtn.isHidden = false
        self.settingsBtn.isHidden = true
        self.selectAllBtn.isHidden = true
        self.selectBtn.isHidden = true
        self.addBtn.isHidden = true
    }
    
    func checkInternetConnection() {
        if Reachability.isConnectedToNetwork() {
            print("Internet connection available")
        }
        else{
            let alertController = UIAlertController(title: "Gig Hard!", message: "Please check your internet connetion!", preferredStyle: .alert)
            let dismissAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alertController.addAction(dismissAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func hideLayouts() {
        self.navigationController?.navigationBar.isHidden = true
        self.settingsBtn.isHidden = true
        self.addBtn.isHidden = true
        self.selectBtn.isHidden = true
        self.cancelBtn.isHidden = true
        self.deleteBtn.isHidden = true
        self.moveBtn.isHidden = true
        self.DoneBtn.isHidden = true
        self.selectAllBtn.isHidden = true
    }
}

//    MARK:- TABLEVIEW DELEGATE AND DATASOURCES
extension SetListViewController: UITableViewDelegate,UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if isMove {
            if searchEnabled {
                 return searchPlaylists.count
            } else {
                return allIcloudPlaylists.count
            }
        } else {
            switch  segmentOutlet.selectedSegmentIndex {
               
            case 0:
                if searchEnabled {
                     return searchSongss.count
                } else {
                    return self.allIcloudSongs.count
                }
            case 1:
                if searchEnabled {
                     return searchPlaylists.count
                } else {
                return allIcloudPlaylists.count
                }
                
            default:
                return 0
        }
    }
}
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = setListTableView.dequeueReusableCell(withIdentifier: "AllSongsTableViewCellReuse", for: indexPath) as! AllSongsTableViewCell
        if isMove {
            if searchEnabled {
                
                if searchPlaylists.count > 0
                {
                cell.lblSongName.text = "\(searchPlaylists[indexPath.row].value(forKey: "playlistName")!)"
               
                self.setListTableView.isEditing = false
                self.setListTableView.allowsMultipleSelectionDuringEditing = true
                }
                else
                {
                    cell.lblSongName.text = ""
                }
              
            }
            else {
                if allIcloudPlaylists.count > 0
                {
                cell.lblSongName.text = "\(allIcloudPlaylists[indexPath.row].value(forKey: "playlistName")!)"
                self.setListTableView.isEditing = false
                self.setListTableView.allowsMultipleSelectionDuringEditing = true
                }
                else
                {
                    cell.lblSongName.text = ""
                }
            }
        }else {
            cell.checkMarkImgView.isHidden = true
            cell.checkMarkWidthConstraint.constant = 0
            if segmentOutlet.selectedSegmentIndex == 0 {
                if searchEnabled {
                     if searchSongss.count > 0
                     {
                    cell.lblSongName.text = "\(searchSongss[indexPath.row].value(forKey: "documentName")!)"
                    }
                    else
                     {
                        cell.lblSongName.text = ""
                    }
                } else {
                    if allIcloudSongs.count > 0
                    {
                    cell.lblSongName.text = "\(allIcloudSongs[indexPath.row].value(forKey: "documentName")!)"
                    }
                    else
                    {
                        cell.lblSongName.text = ""
                    }
                }
                if isSelect {
                    self.setListTableView.isEditing = true
                    self.setListTableView.allowsMultipleSelectionDuringEditing = true
                }else{
                    self.setListTableView.isEditing = false
                }
            } else if segmentOutlet.selectedSegmentIndex == 1{
                if searchEnabled {
                    if searchPlaylists.count > 0
                    {
                    cell.lblSongName.text = "\(searchPlaylists[indexPath.row].value(forKey: "playlistName")!)"
                    }
                    else
                    {
                        cell.lblSongName.text = ""
                    }
                } else {
                    if allIcloudPlaylists.count > 0
                    {
                         cell.lblSongName.text = "\(allIcloudPlaylists[indexPath.row].value(forKey: "playlistName")!)"
                    }
                    else
                    {
                         cell.lblSongName.text = ""
                    }
                   
                }
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        64
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.hideContentOnselectRow()
        if isMove {
            self.hideLayouts()
            self.cancelBtn.isHidden = false
            self.DoneBtn.isHidden = false
            let cell = setListTableView.cellForRow(at: [0, indexPath.row]) as! AllSongsTableViewCell
            if searchEnabled {
                self.selectedPlayListArr.append(self.searchPlaylists[indexPath.row])
                self.selectedSearchedPlaylistIndexes.append(indexPath.row)
            } else {
                self.selectedPlayListArr.append(self.allIcloudPlaylists[indexPath.row])
                self.selectedPlyListIndexs.append(indexPath.row)
            }
            if selectedPlyListIndexs.count == 1 || selectedSearchedPlaylistIndexes.count == 1{
                self.plylistIndex = indexPath.row
            }
            cell.checkMarkImgView.isHidden = false
            cell.checkMarkWidthConstraint.constant = 18.0
        } else {
            if searchEnabled {
                if isSelect {
                    let item = self.searchSongss[indexPath.row]
                    self.selectedSongs.append(item)
                } else {
                    if segmentOutlet.selectedSegmentIndex == 0 {
                        self.hideLayouts()
                        self.addBtn.isHidden = false
                        self.selectBtn.isHidden = false
                        self.settingsBtn.isHidden = false
                        if isPrompt {
                            let editVC = self.storyboard?.instantiateViewController(withIdentifier: "EditViewControllerID") as! EditViewController
                            editVC.ckrecord = self.searchSongss[indexPath.row]
                            editVC.docIndexValue = indexPath.row
                            self.navigationController?.pushViewController(editVC, animated: true)
                        } else {
                            self.delegate?.selectPromptRecord(promptRecord: self.searchSongss[indexPath.row], indexValue: indexPath.row)
                            
                            self.navigationController?.popToRootViewController(animated: true)
                        }
                    }else if segmentOutlet.selectedSegmentIndex == 1 {
                        self.hideLayouts()
                        self.addBtn.isHidden = false
                        self.settingsBtn.isHidden = false
                        self.plylistIndex = indexPath.row
                        if searchPlaylists.count > 1 {
                            let favSongVC = self.storyboard?.instantiateViewController(withIdentifier: "FavSongsViewControllerID") as! FavSongsViewController
                            favSongVC.promPlaylist = self.searchPlaylists[indexPath.row]
                            self.navigationController?.pushViewController(favSongVC, animated: true)
                        }
                    }
                }
            } else {
                if isSelect {
                self.selectedSongs.append(self.allIcloudSongs[indexPath.row])
            } else {
                if segmentOutlet.selectedSegmentIndex == 0 {
                    self.hideLayouts()
                    self.addBtn.isHidden = false
                    self.selectBtn.isHidden = false
                    self.settingsBtn.isHidden = false
                    if isPrompt {
                        let editVC = self.storyboard?.instantiateViewController(withIdentifier: "EditViewControllerID") as! EditViewController
                        //MARK:- pass ckrecord 22-1-20
                        editVC.ckrecord = self.allIcloudSongs[indexPath.row]
                        editVC.docIndexValue = indexPath.row
                        self.navigationController?.pushViewController(editVC, animated: true)
                    } else {
                        self.delegate?.selectPromptRecord(promptRecord: self.allIcloudSongs[indexPath.row], indexValue: indexPath.row)
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                    
                }else if segmentOutlet.selectedSegmentIndex == 1 {
                    self.hideLayouts()
                    self.addBtn.isHidden = false
                    self.settingsBtn.isHidden = false
                    //add index
                    self.plylistIndex = indexPath.row
                    let favSongsVC = self.storyboard?.instantiateViewController(withIdentifier: "FavSongsViewControllerID") as! FavSongsViewController
                    favSongsVC.promPlaylist = self.allIcloudPlaylists[indexPath.row]
                    self.navigationController?.pushViewController(favSongsVC, animated: true)
                }
            }
        }
        }
    }
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if isMove {
            let cell = setListTableView.cellForRow(at: [0, indexPath.row]) as! AllSongsTableViewCell
            
            if searchEnabled {
//                MARK:7-2-20
                let playlistObj = self.searchPlaylists[indexPath.row]
                if self.selectedPlayListArr.contains(playlistObj) {
                    self.selectedPlayListArr.removeAll { $0 as CKRecord === playlistObj as CKRecord }
                }
                let plylistIndxObj = self.playListsIndexValues[indexPath.row]
                if self.selectedSearchedPlaylistIndexes.contains(plylistIndxObj) {
                    self.selectedSearchedPlaylistIndexes.removeAll { $0 as Int == plylistIndxObj as Int }
                }
            } else {
                let playlistObj = self.allIcloudPlaylists[indexPath.row]
                if self.selectedPlayListArr.contains(playlistObj) {
                    self.selectedPlayListArr.removeAll { $0 as CKRecord === playlistObj as CKRecord }
                }
                let plylistIndxObj = self.playListsIndexValues[indexPath.row]
                if self.selectedPlyListIndexs.contains(plylistIndxObj) {
                    self.selectedPlyListIndexs.removeAll { $0 as Int == plylistIndxObj as Int }
                }
            }
            cell.checkMarkImgView.isHidden = true
            cell.checkMarkWidthConstraint.constant = 0
            
            if selectedPlayListArr.count == 0 {
                self.DoneBtn.isHidden = true
            }
        } else {
            if searchEnabled {
                if isSelect {
                    if selectedSongs.count > 0 {
                        let object = self.searchSongss[indexPath.row]
                        if self.selectedSongs.contains(object) {
                            self.selectedSongs.removeAll { $0 as CKRecord === object as CKRecord }
                        }
                    }
                    if selectedSongs.count == 0 {
                        self.selectAllBtn.isHidden = false
                        self.settingsBtn.isHidden = false
                        self.hideLayouts()
                    }
                }
            } else {
            if isSelect {
                if selectedSongs.count > 0 {
                    let object = self.allIcloudSongs[indexPath.row]
                    if self.selectedSongs.contains(object) {
                        self.selectedSongs.removeAll { $0 as CKRecord === object as CKRecord }
                    }
                }
                if selectedSongs.count == 0 {
                    self.selectAllBtn.isHidden = false
                    self.settingsBtn.isHidden = false
                    self.hideLayouts()
                }
            }
            }
        }
    }
    @available(iOS 11.0, *)
         func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if segmentOutlet.selectedSegmentIndex == 0 {
            let delete = UIContextualAction(style: .destructive, title: "Delete") { (action, sourceView, completionHandler) in
                let deletedSong = self.allIcloudSongs[indexPath.row]
                //deleteFrom icloud
                DatabaseHelper.shareInstance.deleteSongInPlaylist(editRecord: deletedSong)
                DatabaseHelper.shareInstance.deleteiCloudRecord(recordName: "\(deletedSong.value(forKey: "documentName")!)")
                
                // Initialize Fetch Request
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "PromptDocument")
                let managedObjectContext = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext
                // Configure Fetch Request
                fetchRequest.includesPropertyValues = false
                do {
//                    managedObjectContext?.delete(deletedSong)  // if using coredata
                    // Save Changes
                    try managedObjectContext?.save()
                    self.allIcloudSongs.remove(at: indexPath.row)
                    DispatchQueue.main.async {
                        self.setListTableView.reloadData()
                    }
                } catch {
                    // Error Handling
                    // ...
                }
            }

            let rename = UIContextualAction(style: .normal, title: "Rename") { (action, sourceView, completionHandler) in
//                let updatedSong = self.allSongsArr[indexPath.row]
                let updatedSong = self.allIcloudSongs[indexPath.row]
                let alertAddList = UIAlertController(title: "Gig Hard!", message: "Please enter new name for song.", preferredStyle: .alert)
                alertAddList.addTextField { (textField) in
                    textField.delegate = self as UITextFieldDelegate
                    textField.layer.cornerRadius = 4
                    textField.autocapitalizationType = .words
                }
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                let okAction = UIAlertAction(title: "OK", style: .default) { UIAlertAction in
                    DispatchQueue.main.async {
                        MBProgressHUD.showAdded(to: self.view, animated: true)
                    }
                    let answer = alertAddList.textFields![0]
                    
                    if answer.text!.count > 0
                    {
                        let docName = "\(answer.text!)"
                        let docDescription = "\(updatedSong.value(forKey: "documentDescription")!)"
                        let editSize = "\(updatedSong.value(forKey: "editDocumentSize")!)"
                        let editDocSize = Int(editSize)!
                        let promptSize = "\(updatedSong.value(forKey: "promptDocumentTextSize")!)"
                        let promptTextSize = Int(promptSize)!
                        // convert attributed data to string
                        var docAttrText = NSAttributedString()
                        let attrData = updatedSong.value(forKey: "documentAttrText") as! Data
                        let attrStr = NSKeyedUnarchiver.unarchiveObject(with: attrData)
                        docAttrText = attrStr as! NSAttributedString
                        let speed = "\(updatedSong.value(forKey: "promptDocumentSpeed")!)"
                        let promptSpeed = Int(speed)!
                        let updateDate = updatedSong.value(forKey: "docUpdateDate")
                        let docDict = ["documentName": docName,"documentDescription": docDescription,"documentAttrText": docAttrText,"editDocumentSize": editDocSize,"promptDocumentTextSize": promptTextSize,"promptDocumentSpeed": promptSpeed, "docUpdateDate": updateDate] as [String : Any]
                        
//                        DatabaseHelper.shareInstance.updateRecordInPlaylist(editRecord: updatedSong, documentObj: docDict)
                        
                        DatabaseHelper.shareInstance.fetchNotes { (allDocuments) in
                            let documents = allDocuments
                            for document in documents {
                                if document.value(forKey: "documentName") as! String == docName {
                                    self.isDocExist = true
                                }
                            }
                            if self.isDocExist == true {
                                self.isDocExist = false
                                let alert = UIAlertController(title: "Gig Hards!", message: "This document is already exist in your list please choose different name for your document.", preferredStyle: .alert)
                                //                                let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                                alert.addAction(cancelAction)
                                DispatchQueue.main.async {
                                    MBProgressHUD.hide(for: self.view, animated: true)
                                    self.present(alert, animated: true, completion: nil)
                                }
                            } else {
                                DatabaseHelper.shareInstance.updateNameInPlaylistData(oldName: "\(updatedSong.value(forKey: "documentName")!)", newName: docName) { (bool) in
                                    DispatchQueue.main.async {
                                        self.fetchPlaylists { (allList) in
                                            if allList?.count ?? 0 > 0 {
                                                self.allIcloudPlaylists = allList!
                                                self.playListsIndexValues.removeAll()
                                                if self.allIcloudPlaylists.count != 0 {
                                                    for index in 0...self.allIcloudPlaylists.count - 1 {
                                                        self.playListsIndexValues.append(index)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                //                        MARK: for update in allsongs
                                DatabaseHelper.shareInstance.savingNote(editRecord: updatedSong, documentObj: docDict) { (record) in
                                    DispatchQueue.main.async {
                                        
                                        self.fetchNotes(completion: { (allNotes) in
                                            if let data = allNotes {
                                                DispatchQueue.main.async {
                                                    self.allIcloudSongs = data
                                                    let sortedSongs = self.allIcloudSongs.sorted { a, b in
                                                        
                                                        return (a.value(forKey: "documentName") as! String)
                                                            .localizedStandardCompare(b.value(forKey: "documentName") as! String)
                                                            == ComparisonResult.orderedAscending
                                                    }
                                                    self.allIcloudSongs = sortedSongs
                                                    self.setListTableView.reloadData()
                                                }
                                            }
                                        })
                                        MBProgressHUD.hide(for: self.view, animated: true)
                                    }
                                }
                            }
                        }
//
                    }
//
                }
                alertAddList.addAction(cancelAction)
                alertAddList.addAction(okAction)
                self.present(alertAddList, animated: true, completion: nil)
            }
            let swipeActionConfig = UISwipeActionsConfiguration(actions: [rename, delete])
            swipeActionConfig.performsFirstActionWithFullSwipe = false
            return swipeActionConfig
        } else if segmentOutlet.selectedSegmentIndex == 1 {
                    let delete = UIContextualAction(style: .destructive, title: "Delete") { (action, sourceView, completionHandler) in
                        let deletedPlaylist = self.allIcloudPlaylists[indexPath.row]
                        DatabaseHelper.shareInstance.deleteiCloudPlaylist(recordName: deletedPlaylist)
                        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "PromptPlaylist")
                        let managedObjectContext = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext
                        fetchRequest.includesPropertyValues = false
                        do {
//                            managedObjectContext?.delete(deletedPlaylist)
//                            // Save Changes
                            try managedObjectContext?.save()
                            self.allIcloudPlaylists.remove(at: indexPath.row)
                            DispatchQueue.main.async {
                                self.setListTableView.reloadData()
                            }
                        } catch {
//                            // Error Handling
//                            // ...
                        }
                    }

            let rename = UIContextualAction(style: .normal, title: "Rename") { (action, sourceView, completionHandler) in
                let alertAddList = UIAlertController(title: "Gig Hard!", message: "Please enter new name for Playlist.", preferredStyle: .alert)
                alertAddList.addTextField { (textField) in
                    textField.delegate = self as UITextFieldDelegate
                    textField.layer.cornerRadius = 4
                    textField.autocapitalizationType = .words
                }
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                let okAction = UIAlertAction(title: "OK", style: .default) { UIAlertAction in
                    MBProgressHUD.hide(for: self.view, animated: true)
                    let answer = alertAddList.textFields![0]
                    //
                    if answer.text!.count > 0
                    {
                        
                        DatabaseHelper.shareInstance.fetchIcloudPlaylists { (allPlaylists) in
                            DispatchQueue.main.async {
                                let allPlaylists = allPlaylists
                                for playlist in allPlaylists {
                                    if playlist.value(forKey: "playlistName") as! String == "\(alertAddList.textFields![0].text!)" {
                                        self.isPlayListExist = true
                                    }
                                }
                                if self.isPlayListExist {
                                    self.isPlayListExist = false
                                    let alert = UIAlertController(title: "Gig Hards!", message: "This name is already exist in your list please choose different name for your playlist.", preferredStyle: .alert)
                                    //                                let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                                    alert.addAction(cancelAction)
                                    DispatchQueue.main.async {
                                        MBProgressHUD.hide(for: self.view, animated: true)
                                        self.present(alert, animated: true, completion: nil)
                                    }
                                } else {
                                    DatabaseHelper.shareInstance.updatePlaylistName(editRecord: self.allIcloudPlaylists[indexPath.row], playlistname: answer.text) { (isSuccess) in
                                        if isSuccess! {
                                            DispatchQueue.main.async {
                                                MBProgressHUD.hide(for: self.view, animated: true)
                                                self.fetchPlaylists { (allList) in
                                                    if allList?.count ?? 0 > 0 {
                                                        self.allIcloudPlaylists = allList!
                                                        self.playListsIndexValues.removeAll()
                                                        if self.allIcloudPlaylists.count != 0 {
                                                            for index in 0...self.allIcloudPlaylists.count - 1 {
                                                                self.playListsIndexValues.append(index)
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    DispatchQueue.main.async {
                                        self.setListTableView.reloadData()
                                    }
                                }
                            }
                        }
                        
                    } else {
                        let alert = UIAlertController(title: "Gig Hards!", message: "Please enter something.", preferredStyle: .alert)
                        //                                let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                        alert.addAction(cancelAction)
                        DispatchQueue.main.async {
                            MBProgressHUD.hide(for: self.view, animated: true)
                            self.present(alert, animated: true, completion: nil)
                        }
                    }
                    
                }
                alertAddList.addAction(cancelAction)
                alertAddList.addAction(okAction)
                self.present(alertAddList, animated: true, completion: nil)
            }
                    let swipeActionConfig = UISwipeActionsConfiguration(actions: [rename, delete])
                    swipeActionConfig.performsFirstActionWithFullSwipe = false
                    return swipeActionConfig
                }
            return nil
        }

}
//    MARK:- TEXTFIELD DELEGATE
extension SetListViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
}

//    MARK:- DATAPASS DELEGATE
extension SetListViewController: DataPassDelegate {
    func passDocumentArr(document: [[String : Any]]) {
        self.fetchNotes(completion: { (allNotes) in
            if let data = allNotes {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.allIcloudSongs = data
                    let sortedSongs = self.allIcloudSongs.sorted { a, b in
                        
                        return (a.value(forKey: "documentName") as! String)
                            .localizedStandardCompare(b.value(forKey: "documentName") as! String)
                            == ComparisonResult.orderedAscending
                    }
                    self.allIcloudSongs = sortedSongs
                    self.setListTableView.reloadData()
                }
            }
        })
    }
}

//    MARK:- EXTENSION UISEGMENT CONTROL
extension UISegmentedControl{
    func setSelectedSegmentColor(with foregroundColor: UIColor, and tintColor: UIColor) {
        if #available(iOS 13.0, *) {
        self.setTitleTextAttributes([.foregroundColor: foregroundColor], for: .selected)
            self.selectedSegmentTintColor = UIColor.white;
        } else {
            self.tintColor = UIColor.white;
        }
    }
}

extension SetListViewController : UISearchBarDelegate{
    //MARK: UISearchbar delegate
       func filterContent(forSearchText searchText: String)
       {
        
        if segmentOutlet.selectedSegmentIndex == 0 {
           self.searchSongss.removeAll()
//           for candidate in self.allSongsArr
            for candidate in self.allIcloudSongs
           {
                   let names = "\((candidate as AnyObject).value(forKey: "documentName")!)"
                   
                   if((names).lowercased().contains(searchText.lowercased()))
                   {
//                       searchSongs.append(candidate)
                    searchSongss.append(candidate)
                   }

                   self.setListTableView.reloadData()
           }
        } else if segmentOutlet.selectedSegmentIndex == 1 {
            self.searchPlaylists.removeAll()
            for candidate in self.allIcloudPlaylists
            {
                let names = "\((candidate as AnyObject).value(forKey: "playlistName")!)"
                if((names).lowercased().contains(searchText.lowercased()) )
                {
                    searchPlaylists.append(candidate)
                }
                self.selectedSearchedPlaylistIndexes.removeAll()
                if self.searchPlaylists.count != 0 {
                    for index in 0...self.searchPlaylists.count - 1 {
                        self.selectedSearchedPlaylistIndexes.append(index)
                    }
                }
                self.setListTableView.reloadData()
            }
        }
       }
       
       func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {

        if searchBar.text == "" {
               self.searchBarOutlet.searchTextField.resignFirstResponder()
                self.searchBarOutlet.searchTextField.text = ""
               self.searchEnabled = false
                self.setListTableView.reloadData()
           }
           else {
               searchEnabled = true
               filterContent(forSearchText: searchBar.text!)
            if segmentOutlet.selectedSegmentIndex == 0 {
                self.selectedSongs.removeAll()
            } else if segmentOutlet.selectedSegmentIndex == 1 {
                self.selectedPlayListArr.removeAll()
                self.selectedPlyListIndexs.removeAll()
                self.selectedSearchedPlaylistIndexes.removeAll()
            }
                self.setListTableView.reloadData()
           }
       }
       
       func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
           searchBar.resignFirstResponder()
           searchEnabled = true
           filterContent(forSearchText: searchBar.text!)
       }
       
       func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
           self.searchBarOutlet.resignFirstResponder()
           self.searchBarOutlet.showsCancelButton = false
           self.searchBarOutlet.searchTextField.text = ""
           searchEnabled = false
           setListTableView.reloadData()
       }
}
