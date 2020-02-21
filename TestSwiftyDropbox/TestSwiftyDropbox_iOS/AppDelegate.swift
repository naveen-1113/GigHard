///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

import UIKit
import SwiftyDropbox
import CoreData
import CloudKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    //MARK: MANAGE LANDSCAPE MODE
    var orientationLockiPhone = UIInterfaceOrientationMask.portrait
    var orientationLockiPad = UIInterfaceOrientationMask.all
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        UIApplication.shared.isStatusBarHidden = true
        if UserDefaults.standard.bool(forKey: "HasLaunchedOnce") {
          // App already launched
        } else {
          // This is the first launch ever
            UserDefaults.standard.set(true, forKey: "HasLaunchedOnce")
            UserDefaults.standard.synchronize()
            self.fetchNotes()
        }
        DatabaseHelper.shareInstance.fetchIcloudPlaylists { (ckRecords) in
            print(ckRecords)
        }
        DropboxClientsManager.setupWithAppKey("aive1dyoxj4jbeu")
        return true
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        if ( UI_USER_INTERFACE_IDIOM() == .pad) {
            return self.orientationLockiPad
        } else {
            return self.orientationLockiPhone
        }
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        switch(appPermission) {
        case .fullDropbox:
            if let authResult = DropboxClientsManager.handleRedirectURL(url) {
                switch authResult {
                case .success:
                    print("Success! User is logged into DropboxClientsManager.")
                case .cancel:
                    print("Authorization flow was manually canceled by user!")
                case .error(_, let description):
                    print("Error: \(description)")
                }
            }
        case .teamMemberFileAccess:
            if let authResult = DropboxClientsManager.handleRedirectURLTeam(url) {
                switch authResult {
                case .success:
                    print("Success! User is logged into DropboxClientsManager.")
                case .cancel:
                    print("Authorization flow was manually canceled by user!")
                case .error(_, let description):
                    print("Error: \(description)")
                }
            }
        case .teamMemberManagement:
            if let authResult = DropboxClientsManager.handleRedirectURLTeam(url) {
                switch authResult {
                case .success:
                    print("Success! User is logged into DropboxClientsManager.")
                case .cancel:
                    print("Authorization flow was manually canceled by user!")
                case .error(_, let description):
                    print("Error: \(description)")
                }
            }
        }

        return true
    }

    
    // MARK: - Private Methods
    func fetchNotes() {
        let container = CKContainer.default()
        let privateDatabase = container.privateCloudDatabase
        let predicate = NSPredicate(value: true)
        
        let query = CKQuery(recordType: "PromptDocuments", predicate: predicate)
        
        privateDatabase.perform(query, inZoneWith: nil) { (results, error) -> Void in
            if error != nil {
                print(error!)
            }
            else {
                DatabaseHelper.shareInstance.allNotes.removeAll()
                for result in results! {
                    DatabaseHelper.shareInstance.allNotes.append(result)
                }
                if results?.count == 0 {
                    DatabaseHelper.shareInstance.saveWelcomeText()
                }
            }
        }
    }
    
    
    // MARK: - Core Data stack

    
    lazy var persistentContainer: NSPersistentContainer = {
         if #available(iOS 13.0, *) {
                   let container = NSPersistentCloudKitContainer(name: "PromptDataModel")
                   container.loadPersistentStores(completionHandler: { (storeDescription, error) in
                       if let error = error as NSError? {
                           fatalError("Unresolved error \(error), \(error.userInfo)")
                       }
                   })
                   return container
               } else {
                   let container = NSPersistentContainer(name: "PromptDataModel")
                   container.loadPersistentStores(completionHandler: { (storeDescription, error) in
                       if let error = error as NSError? {
                           fatalError("Unresolved error \(error), \(error.userInfo)")
                       }
                   })
                   return container
               }
//        let container = NSPersistentContainer(name: "PromptDataModel")
//        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
//            if let error = error as NSError? {
//                fatalError("Unresolved error \(error), \(error.userInfo)")
//            }
//        })
//        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
