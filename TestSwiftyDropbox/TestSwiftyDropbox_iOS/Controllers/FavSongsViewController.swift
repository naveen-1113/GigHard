//
//  FavSongsViewController.swift
//  GigHard_Swift
//
//  Created by osx on 16/12/19.
//  Copyright © 2019 osx. All rights reserved.
//

import UIKit
import CloudKit
import MBProgressHUD

class FavSongsViewController: UIViewController {

//    MARK:- VARIABLE(S) AND OUTLET(S)
//    var indexOfPlayList:Int?
//    var favSongsArr = [PromptDocument]()
    @IBOutlet weak var lblPlaylistTitle: UILabel!
    @IBOutlet weak var searchBarOutlet: UISearchBar!
    @IBOutlet weak var tblFavSongs: UITableView!
    @IBOutlet weak var selectBtnOutlet: UIButton!
    @IBOutlet weak var selectAllBtnOutlet: UIButton!
    @IBOutlet weak var removeBtnOutlet: UIButton!
    @IBOutlet weak var doneBtnOutlet: UIButton!
    @IBOutlet weak var moveBtnOutlet: UIButton!
    @IBOutlet weak var cancelOutlet: UIButton!
    @IBOutlet weak var backBtnOutlet: UIButton!
    var promPlaylist: CKRecord!
    var songsArr:[[String:Any]]!
    var filteredArr:[[String:Any]]!
    var favSongsArr:[[String:Any]]!
    var selectedSongs = [[String:Any]]()
    var allIndexesArr = [Int]()
    
    //search control
    var searchEnabled = Bool()
    var searchSongs = [[String:Any]]()
    var isSelect:Bool? = false
    var isMove:Bool! = false
    
//    MARK:- VIEW LIFE CYCLE METHOD(S)
    override func viewDidLoad() {
        super.viewDidLoad()
        
        MBProgressHUD.showAdded(to: self.view, animated: true)
        self.lblPlaylistTitle.text = self.promPlaylist.value(forKey: "playlistName") as! String
        if self.promPlaylist.value(forKey: "playlistData") != nil {
            let data = self.promPlaylist.value(forKey: "playlistData") as! Data
            let arr = NSKeyedUnarchiver.unarchiveObject(with: data) as! [[String:Any]]
            self.songsArr = arr
        }
        let orderedSet : NSOrderedSet = NSOrderedSet(array: songsArr ?? [])
        self.filteredArr = orderedSet.array as! [[String : Any]]
        if filteredArr.count > 0 {
            self.songsArr?.removeAll()
            for record in filteredArr {
                let docName = "\(record["documentName"]!)"
                let docDescription = "\(record["documentDescription"]!)"
                let promptSpeed = record["promptDocumentSpeed"] as! Int
                let promptSize = record["promptDocumentTextSize"] as! Int
                let editDocumentSize = record["editDocumentSize"] as! Int
//                let docUpdateDate = record["docUpdateDate"] as! Date
                var attributedStr = NSAttributedString()
                if record["documentAttrText"] is Data {
                    let attributedData = record["documentAttrText"] as! Data
                    guard let attrStr = NSKeyedUnarchiver.unarchiveObject(with: attributedData) as? NSAttributedString else { return }
                    attributedStr = attrStr
                } else if record["documentAttrText"] is NSAttributedString {
                    attributedStr = record["documentAttrText"] as! NSAttributedString
                }
                let dict = ["documentName":docName,"documentDescription":docDescription,"promptDocumentSpeed":promptSpeed,"promptDocumentTextSize":promptSize,"editDocumentSize":editDocumentSize,"documentAttrText":attributedStr] as [String : Any]  // remove as[String : Any] if optional error occurs
                songsArr?.append(dict)
            }
        }
//        self.filteredArr = songsArr
        
        if self.filteredArr != nil {
            let sortedSongs = self.filteredArr.sorted { a, b in
                
                return (a["documentName"] as! String)
                    .localizedStandardCompare(b["documentName"] as! String)
                    == ComparisonResult.orderedAscending
            }
            self.filteredArr = sortedSongs
            self.filterSongs()
//            if self.filteredArr.count > 0 {
//                for index in 0...self.filteredArr.count - 1 {
//                    self.allIndexesArr.append(index)
//                }
//            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
            MBProgressHUD.hide(for: self.view, animated: true)
        }
        
        self.isMove = true
        self.tblFavSongs.reloadData()
    }
    
    //    MARK:- IBACTION(S)
    @IBAction func backAction(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func selectAction(_ sender: UIButton) {
        if self.favSongsArr.count == 0 {
            print("no data!")
        } else {
            self.selectBtnOutlet.isHidden = true
            self.moveBtnOutlet.isHidden = true
            self.doneBtnOutlet.isHidden = true
            self.backBtnOutlet.isHidden = true
            self.cancelOutlet.isHidden = false
            self.selectAllBtnOutlet.isHidden = false
            self.tblFavSongs.isEditing = false
            self.tblFavSongs.dragDelegate = nil
            self.isMove = false
            if isSelect! {
                isSelect = false
            } else {
                isSelect = true
            }
            self.tblFavSongs.reloadData()
        }
    }
    
    @IBAction func selectAllAction(_ sender: UIButton) {
        isSelect = true
        self.removeBtnOutlet.isHidden = false
        let totalRows = tblFavSongs.numberOfRows(inSection: 0)
        for row in 0..<totalRows {
            tblFavSongs.selectRow(at: IndexPath(row: row, section: 0), animated: false, scrollPosition: UITableView.ScrollPosition.none)
        }
        self.allIndexesArr.removeAll()
    }
    
    @IBAction func removeAction(_ sender: UIButton) {
        if searchEnabled {
            self.searchBarOutlet.searchTextField.resignFirstResponder()
            self.searchBarOutlet.searchTextField.text = ""
        }
        self.searchEnabled = false
        let alertController = UIAlertController(title: "Gig Hard!", message: "Are you sure that you want to remove the selected songs.", preferredStyle: .alert)
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { (alertAction) in
            MBProgressHUD.showAdded(to: self.view, animated: true)
            var newList = [[String:Any]]()
            for value in self.allIndexesArr {
                newList.append(self.favSongsArr[value])
            }
//            print(newList)  // may be optional values create issue here
            self.allIndexesArr.removeAll()
            if newList.count > 0 {
                for index in 0...newList.count - 1 {
                    self.allIndexesArr.append(index)
                }
            } else {
                self.allIndexesArr.removeAll()
            }
            self.favSongsArr = newList
            let dict = ["playlistName":"\(self.promPlaylist.value(forKey: "playlistName") as! String)","playlistData":newList] as [String : Any]
            DatabaseHelper.shareInstance.savingPlaylist(editRecord: self.promPlaylist, documentObj: dict) { (ckRecord) in
                
                self.favSongsArr = newList
                self.isSelect = false
                self.isMove = false
                
                DispatchQueue.main.async {
                    self.cancelOutlet.isHidden = true
                    self.removeBtnOutlet.isHidden = true
                    self.selectAllBtnOutlet.isHidden = true
                    self.doneBtnOutlet.isHidden = true
                    self.backBtnOutlet.isHidden = false
                    self.moveBtnOutlet.isHidden = true
                    self.selectBtnOutlet.isHidden = false
                    self.tblFavSongs.isEditing = false
                    MBProgressHUD.hide(for: self.view, animated: true)
                    self.tblFavSongs.reloadData()
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
                MBProgressHUD.hide(for: self.view, animated: true)
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        alertController.addAction(deleteAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func moveAction(_ sender: UIButton) {
        self.isMove = true
        self.isSelect = false
        self.selectBtnOutlet.isHidden = true
        self.selectAllBtnOutlet.isHidden = true
        self.removeBtnOutlet.isHidden = true
        self.doneBtnOutlet.isHidden = false
        self.tblFavSongs.reloadData()
    }
    
    // also a cancel action
    @IBAction func doneAction(_ sender: UIButton) {
        isSelect = false
        isMove = true
        if searchEnabled {
            self.searchBarOutlet.searchTextField.resignFirstResponder()
            self.searchBarOutlet.searchTextField.text = ""
        }
        self.searchEnabled = false
        self.cancelOutlet.isHidden = true
        self.doneBtnOutlet.isHidden = true
        self.removeBtnOutlet.isHidden = true
        self.selectAllBtnOutlet.isHidden = true
        self.backBtnOutlet.isHidden = false
        self.moveBtnOutlet.isHidden = true
        self.selectBtnOutlet.isHidden = false
        self.tblFavSongs.isEditing = false
//        self.selectedSongs.removeAll()
        self.allIndexesArr.removeAll()
        self.tblFavSongs.reloadData()
    }
    
    @IBAction func gigAction(_ sender: Any) {
        if favSongsArr?.count == 0 {
            
        } else {
            let promptVC = self.storyboard?.instantiateViewController(withIdentifier: "PromptDocumentViewControllerID") as! PromptDocumentViewController
            promptVC.playlistName = self.promPlaylist.value(forKey: "playlistName") as! String
            promptVC.playlistData = self.favSongsArr
            promptVC.isGigPressed = true
            self.navigationController?.pushViewController(promptVC, animated: true)
        }
    }
//    MARK:- PRIVATE METHODS
    
    func filterSongs() {
        var newArr = [[String:Any]]()
        DatabaseHelper.shareInstance.fetchNotes { (allSongs) in
//            print(self.filteredArr)
            if allSongs.count == 0 {
                self.favSongsArr.removeAll()
            } else {
                for element in self.filteredArr {
                    for song in allSongs {
                        if song.value(forKey: "documentName")  as! String == "\(element["documentName"]!)" {
                            let docName = "\(element["documentName"]!)"
                            let docDescription = "\(element["documentDescription"]!)"
                            let promptSpeed = element["promptDocumentSpeed"] as! Int
                            let promptSize = element["promptDocumentTextSize"] as! Int
                            let editDocumentSize = element["editDocumentSize"] as! Int
//                            let docUpdateDate = element["docUpdateDate"] as! Date
                            var attributedStr = NSAttributedString()
                            if element["documentAttrText"] is Data {
                                let attributedData = element["documentAttrText"] as! Data
                                guard let attrStr = NSKeyedUnarchiver.unarchiveObject(with: attributedData) as? NSAttributedString else { return }
                                attributedStr = attrStr
                            } else if element["documentAttrText"] is NSAttributedString {
                                attributedStr = element["documentAttrText"] as! NSAttributedString
                            }
                            let dict = ["documentName":docName,"documentDescription":docDescription,"promptDocumentSpeed":promptSpeed,"promptDocumentTextSize":promptSize,"editDocumentSize":editDocumentSize,"documentAttrText":attributedStr] as [String : Any]
                            newArr.append(dict)
                        }
                    }
                }
                self.favSongsArr = newArr
                let orderedSet : NSOrderedSet = NSOrderedSet(array: newArr)
                 let finalArr = orderedSet.array as? [[String : Any]] ?? []
                self.favSongsArr = orderedSet.array as? [[String : Any]] ?? []
                var namesArr = [String]()
                for item in finalArr {
                    namesArr.append(item["documentName"] as! String)
                }
                
                let neworderset : NSOrderedSet = NSOrderedSet(array: namesArr)
                namesArr = neworderset.array as? [String] ?? []
                
                self.favSongsArr.removeAll()
                for item in namesArr {
                    for dict in finalArr {
                        if item == dict["documentName"] as! String {
                            self.favSongsArr.append(dict)
                            break
                        }
                    }
                }
                print(self.favSongsArr)

                if self.favSongsArr != nil {
                    if self.favSongsArr.count > 0 {
                        for index in 0...self.favSongsArr.count - 1 {
                            self.allIndexesArr.append(index)
                        }
                    }
                }
            }
            let dict = ["playlistName":"\(self.promPlaylist.value(forKey: "playlistName") as! String)","playlistData":newArr] as [String : Any]
            DatabaseHelper.shareInstance.savingPlaylist(editRecord: self.promPlaylist, documentObj: dict) { (playlist) in
                print("Data is saved")
            }
            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.view, animated: true)
                self.tblFavSongs.reloadData()
            }
        }
    }
}

//    MARK:- TABLEVIEW DELEGATE AND DATASOURCES
extension FavSongsViewController: UITableViewDelegate,UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchEnabled {
            return searchSongs.count
        }
        else {
            return self.favSongsArr?.count ?? 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tblFavSongs.dequeueReusableCell(withIdentifier: "defaultCell", for: indexPath)
        
        if searchEnabled {
            cell.textLabel?.text = searchSongs[indexPath.row]["documentName"] as? String
        } else {
            cell.textLabel?.text = self.favSongsArr?[indexPath.row]["documentName"] as? String
        }
        if isSelect! {
            self.tblFavSongs.isEditing = true
            self.tblFavSongs.allowsMultipleSelectionDuringEditing = true
        }else if isMove{
            self.tblFavSongs.isEditing = true
            self.tblFavSongs.allowsMultipleSelectionDuringEditing = false
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }

    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if isMove {
            let movingSong = self.favSongsArr?[sourceIndexPath.row]
            favSongsArr?.remove(at: sourceIndexPath.row)
            favSongsArr?.insert(movingSong!, at: destinationIndexPath.row)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isSelect! {
            if searchEnabled {
                print("searchEnabled")
                let selectedName = searchSongs[indexPath.row]["documentName"] as? String
                for row in 0...self.favSongsArr.count - 1 {
                    if "\(selectedName!)" == "\(self.favSongsArr[row]["documentName"] as! String)" {
                        if self.allIndexesArr.contains(row) {
                            self.allIndexesArr.removeAll { $0 as Int == row as Int }
                        }
                    }
                }
            } else {
                
                let plylistIndxObj = indexPath.row
                if self.allIndexesArr.contains(plylistIndxObj) {
                    self.allIndexesArr.removeAll { $0 as Int == plylistIndxObj as Int }
                }
            }
            self.removeBtnOutlet.isHidden = false
        }
    }
    

    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if isSelect! {
            if searchEnabled {
                print("searchEnabled")
                let selectedName = searchSongs[indexPath.row]["documentName"] as? String
                for row in 0...self.favSongsArr.count - 1 {
                    if "\(selectedName!)" == "\(self.favSongsArr[row]["documentName"] as! String)" {
                        self.allIndexesArr.append(row)
                    }
                }
            } else {
                self.allIndexesArr.append(indexPath.row)
            }
        }
        if self.allIndexesArr.count == self.favSongsArr.count {
            self.removeBtnOutlet.isHidden = true
        }
    }
}

extension FavSongsViewController: UISearchBarDelegate {
    func filterContent(forSearchText searchText: String)
    {
        self.searchSongs.removeAll()

        for candidate in self.favSongsArr ?? []
        {
            let names = "\((candidate as AnyObject).value(forKey: "documentName")!)"

            if((names).lowercased().contains(searchText.lowercased()))
            {
                searchSongs.append(candidate)
            }

            self.tblFavSongs.reloadData()
        }
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        if searchBar.text == "" {
            searchEnabled = false
            self.tblFavSongs.reloadData()
        }
        else {
            searchEnabled = true
            filterContent(forSearchText: searchBar.text!)
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
        tblFavSongs.reloadData()
    }
}
/*
 //MARK: UISearchbar delegate
 func filterContent(forSearchText searchText: String)
 {

     self.searchResult.removeAllObjects()
     
     
     for candidate in self.manageDropezoneList
     {
         if ((candidate as! NSDictionary) != nil) {
             let names = "\((candidate as AnyObject).value(forKey: "dropzone_name")!)"
             
             if((names).lowercased().contains(searchText.lowercased()))
             {
                 searchResult.add(candidate)
             }

             self.manageDropzoneTableView.reloadData()
             
         }
     }
 }
  //MARK:UITableViewDelegate & UITableViewDataSource Methods
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        if searchEnabled
        {
            tableView.deselectRow(at: indexPath as IndexPath, animated: true)
            let dropzoneId = "\((self.searchResult.object(at: indexPath.row) as AnyObject) .value(forKey:"dropzone_id")!)"
            let dropzoneName = "\((self.searchResult.object(at: indexPath.row) as AnyObject) .value(forKey:"dropzone_name")!)"
            
            UserDefaults.standard.removeObject(forKey: "dropzone_name")
            UserDefaults.standard.removeObject(forKey: "dropzone_id")
            
            UserDefaults.standard.set(dropzoneName, forKey: "dropzone_name")
            UserDefaults.standard.set(dropzoneId, forKey: "dropzone_id")
            UserDefaults.standard.synchronize()
            let access_key = "\(UserDefaults.standard.value(forKey: "access_key")!)"
            print(access_key )
            let str = "/cfe_auth/select_dropzone?access_key=\(access_key)&dropzone_id=\(dropzoneId)"
            print(str)
            manageDropzoneTableView.reloadData()
       DispatchQueue.global(qos: .background).async {
                self.webservice.getRequest(parameterString: str , type: "ManageDropzoneSelectDZ")
            }
          
            
        }
        else
        {
            tableView.deselectRow(at: indexPath as IndexPath, animated: true)
            let dropzoneId = "\((self.manageDropezoneList.object(at: indexPath.row) as AnyObject) .value(forKey:"dropzone_id")!)"
            let dropzoneName = "\((self.manageDropezoneList.object(at: indexPath.row) as AnyObject) .value(forKey:"dropzone_name")!)"
            
            UserDefaults.standard.removeObject(forKey: "dropzone_name")
            UserDefaults.standard.removeObject(forKey: "dropzone_id")
            
            UserDefaults.standard.set(dropzoneName, forKey: "dropzone_name")
            UserDefaults.standard.set(dropzoneId, forKey: "dropzone_id")
            UserDefaults.standard.synchronize()
            let access_key = "\(UserDefaults.standard.value(forKey: "access_key")!)"
            print(access_key )
            let str = "/cfe_auth/select_dropzone?access_key=\(access_key)&dropzone_id=\(dropzoneId)"
            print(str)
            manageDropzoneTableView.reloadData()
   DispatchQueue.global(qos: .background).async {
                self.webservice.getRequest(parameterString: str , type: "ManageDropzoneSelectDZ")
            }
            
        }

    }*/
