///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

import Cocoa
import SwiftyDropbox

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var viewController: ViewController? = nil;

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if (TestData.fullDropboxAppKey.range(of:"<") != nil || TestData.teamMemberFileAccessAppKey.range(of:"<") != nil || TestData.teamMemberManagementAppKey.range(of:"<") != nil) {
            print("\n\n\nMust set test data (in TestData.swift) before launching app.\n\n\nTerminating.....\n\n")
            exit(0);
        }
        switch(appPermission) {
        case .fullDropbox:
            DropboxClientsManager.setupWithAppKeyDesktop(TestData.fullDropboxAppKey)
        case .teamMemberFileAccess:
            DropboxClientsManager.setupWithTeamAppKeyDesktop(TestData.teamMemberFileAccessAppKey)
        case .teamMemberManagement:
            DropboxClientsManager.setupWithTeamAppKeyDesktop(TestData.teamMemberManagementAppKey)
        }
        NSAppleEventManager.shared().setEventHandler(self, andSelector: #selector(handleGetURLEvent), forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))

        viewController = NSApplication.shared.windows[0].contentViewController as? ViewController
        self.checkButtons()
    }

    @objc func handleGetURLEvent(_ event: NSAppleEventDescriptor?, replyEvent: NSAppleEventDescriptor?) {
        if let aeEventDescriptor = event?.paramDescriptor(forKeyword: AEKeyword(keyDirectObject)) {
            if let urlStr = aeEventDescriptor.stringValue {
                let url = URL(string: urlStr)!
                
                switch(appPermission) {
                case .fullDropbox:
                    if let authResult = DropboxClientsManager.handleRedirectURL(url) {
                        switch authResult {
                        case .success:
                            print("Success! User is logged into Dropbox.")
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
                            print("Success! User is logged into Dropbox.")
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
                            print("Success! User is logged into Dropbox.")
                        case .cancel:
                            print("Authorization flow was manually canceled by user!")
                        case .error(_, let description):
                            print("Error: \(description)")
                        }
                    }
                }
            }
        }
        self.checkButtons()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationDidResignActive(_ notification: Notification) {
        
    }
    func applicationWillBecomeActive(_ notification: Notification) {
        
    }
    
    func applicationWillEnterBackground(_ application: UIApplication) {
        
    }
    
    func checkButtons() {
        viewController?.checkButtons()
    }
}

