//
//  ItunesTableViewController.swift
//  
//
//  Created by osx on 08/01/20.
//

import UIKit
import MBProgressHUD

class ItunesTableViewController: UIViewController {
//    MARK: - IBOUTLETS AND VARIABLES
    @IBOutlet weak var tblItunes: UITableView!
    var directoryData = [URL]()
    var isItunesImported:Bool = false
    
    //    MARK: - VIEW LIFE CYCLE METHODS
    override func viewDidLoad() {
        super.viewDidLoad()
        MBProgressHUD.showAdded(to: self.view, animated: true)
        self.tblItunes.register(UINib(nibName: "DropboxTableViewCell", bundle: nil), forCellReuseIdentifier: "DropboxTableViewCellReuse")
        self.listFiles()
        
    }

    //    MARK: - IBACTIONS
    @IBAction func backAction(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func doneAction(_ sender: UIButton) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    //    MARK: - PRIVATE METHODS
    func listFiles() {

        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

        do {
            // Get the directory contents urls (including subfolders urls)
            let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil)
            print(directoryContents)

            // if you want to filter the directory contents you can do like this:
            let txtFiles = directoryContents.filter{ $0.pathExtension == "txt" }
            directoryData = txtFiles
//            print("mp3 urls:",txtFiles)
            let txtFilesNames = txtFiles.map{ $0.deletingPathExtension().lastPathComponent }
//            print("mp3 list:", txtFilesNames)
        } catch {
            print(error)
        }
        MBProgressHUD.hide(for: self.view, animated: true)
        self.tblItunes.reloadData()
    }
    
    func saveImageDocumentDirectory(){
        let fileManager = FileManager.default
        let paths = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("icon.png")
        let image = UIImage(named: "btn_play_on")
        let imageData = image!.jpegData(compressionQuality: 0.5)
        fileManager.createFile(atPath: paths as String, contents: imageData, attributes: nil)
        print(imageData!)
    }
    
    func saveTextDocumentDirectory() {
        let fileManager = FileManager.default
        let paths = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("file3.txt")
        let str = "Text Message 3 Text Message 3Text Message 3Text Message Text Message 3"
        print(paths)
        let strData = str.data(using: .utf8, allowLossyConversion: false)
        fileManager.createFile(atPath: paths as String, contents: strData, attributes: nil)
        print(strData!)
        
    }
    
    func getDirectoryPath() -> String {
    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    func getImage(){
        let fileManager = FileManager.default
        let imagePAth = (self.getDirectoryPath() as NSString).appendingPathComponent("icon1.png")
        if fileManager.fileExists(atPath: imagePAth){
//    self.imageView.image = UIImage(contentsOfFile: imagePAth)
            print(imagePAth)
    }else{
    print("“No Image”")
    }
    }

    func getTextFiles(){
        let fileManager = FileManager.default
        let textPath = (self.getDirectoryPath() as NSString).appendingPathComponent("file3.txt")
        if fileManager.fileExists(atPath: textPath){
            print(textPath)
        }else{
            print("“No Image”")
        }
    }
}

//MARK: - TABLEVIEW DELEGATE AND DATASOURCES METHODS
extension ItunesTableViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.directoryData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tblItunes.dequeueReusableCell(withIdentifier: "DropboxTableViewCellReuse", for: indexPath) as! DropboxTableViewCell
        cell.lblFileName.text = directoryData[indexPath.row].deletingPathExtension().lastPathComponent
        cell.indexPath = indexPath.row
        cell.delegate = self as DropBoxTableViewCellDelegate
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
    
}

extension ItunesTableViewController: DropBoxTableViewCellDelegate {
    func dropboxFileImport(isFileImported: Bool?, file: String?) {
    }
    
    func itunesFileImport(isFileImported: Bool?, file: String?) {
        self.isItunesImported = isFileImported!
        if isFileImported! {
            let alertController = UIAlertController(title: "Gig Hards!", message: "Successfully imported file \(file!)", preferredStyle: .alert)
            let dismissAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alertController.addAction(dismissAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
}
