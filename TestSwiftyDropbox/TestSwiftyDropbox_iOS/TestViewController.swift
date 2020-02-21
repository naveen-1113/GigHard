//
//  TestViewController.swift
//  TestSwiftyDropbox_iOS
//
//  Created by osx on 14/01/20.
//  Copyright © 2020 Dropbox. All rights reserved.
//

import UIKit
import SwiftyDropbox

class TestViewController: UIViewController {

    @IBOutlet weak var appsTxtView: UITextView!
    var txtViewFtSize:Int!
    var lineRanges = [NSRange]()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.popViewController(animated: false)
        
//        PlaygroundPage.current.liveView = textView
}
        
        func setBackgroundColor(_ color: UIColor?, forLine line: Int) {
            let textStorage = NSMutableAttributedString(attributedString: self.appsTxtView.attributedText)
            if let color = color {
                textStorage.addAttribute(.backgroundColor, value: color, range: self.appsTxtView.selectedRange)
            } else {
                textStorage.removeAttribute(.backgroundColor, range: self.appsTxtView.selectedRange)
            }
        }
        
        func scheduleHighlighting(ofLine line: Int) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                if line > 0 { self.setBackgroundColor(nil, forLine: line - 1) }
//                guard line < self.lineRanges.count else { return }
//                self.setBackgroundColor(.yellow, forLine: line)
//                self.scheduleHighlighting(ofLine: line + 1)
                if line > 0 {
                    self.setBackgroundColor(nil, forLine: line - 1)
                }
                line < self.lineRanges.count
                self.setBackgroundColor(.yellow, forLine: line)
                self.scheduleHighlighting(ofLine: line + 1)
            }
        }
        
        

    @IBAction func decAction(_ sender: UIButton) {
//        let text = "This is\n some placeholder\n text\nwith newlines."
//        let textView = UITextView(frame: CGRect(x: 0, y:0, width: 200, height: 100))
//        textView.backgroundColor = .white
//        textView.text = text
        
        let textStorage = self.appsTxtView.textStorage
        
        // Use NSString here because textStorage expects the kind of ranges returned by NSString,
        // not the kind of ranges returned by String.
        let storageString = textStorage.string as NSString
        //        var lineRanges = [NSRange]()
        storageString.enumerateSubstrings(in: NSMakeRange(0, storageString.length), options: .byLines, using: { (_, lineRange, _, _) in
            self.lineRanges.append(lineRange)
        })
        scheduleHighlighting(ofLine: 0)
    }
    
    
    @IBAction func incAction(_ sender: UIButton) {
        
        self.txtViewFtSize += 1
        let textRange = appsTxtView.selectedRange
        appsTxtView.isScrollEnabled = false
        let attrStr:NSMutableAttributedString = appsTxtView.attributedText.mutableCopy() as! NSMutableAttributedString

        attrStr.enumerateAttributes(in: NSMakeRange(0, attrStr.length), options: NSAttributedString.EnumerationOptions.reverse) { (attributes, range, stop) in
            let mutableAttributes = attributes
            var currentFont:UIFont = mutableAttributes[NSAttributedString.Key("NSFont")] as! UIFont
            currentFont = currentFont.withSize(CGFloat(txtViewFtSize))
            attrStr.addAttribute(.font, value: currentFont, range: range)
        }
        
        self.appsTxtView.attributedText = attrStr
        self.appsTxtView.isScrollEnabled = true
        self.appsTxtView.selectedRange = textRange
        
    }
    
    func showAttrText(textView: UITextView ,attributedText: NSAttributedString, withSize: Int) {

        let textRange = textView.selectedRange
        textView.isScrollEnabled = false
        let attrStr:NSMutableAttributedString = attributedText.mutableCopy() as! NSMutableAttributedString

        attrStr.enumerateAttributes(in: NSMakeRange(0, attrStr.length), options: NSAttributedString.EnumerationOptions.reverse) { (attributes, range, stop) in
                let mutableAttributes = attributes
                print(mutableAttributes)
            if mutableAttributes[NSAttributedString.Key("NSFont")] != nil {
                var currentFont:UIFont = mutableAttributes[NSAttributedString.Key("NSFont")] as! UIFont
                currentFont = currentFont.withSize(CGFloat(txtViewFtSize))
                attrStr.addAttribute(.font, value: currentFont, range: range)
            } else {
                attrStr.addAttributes([NSAttributedString.Key.font: UIFont.init(name: "Helvetica Neue", size: CGFloat(withSize))], range: range)
            }
        }
        
        textView.attributedText = attrStr
        textView.isScrollEnabled = true
        textView.selectedRange = textRange
    }
    
    
    func getData() {
        // Verify user is logged into Dropbox
        if let client = DropboxClientsManager.authorizedClient {
            // Get the current user's account info
            client.users.getCurrentAccount().response { (response, error) in
                if let account = response {
                    print("Hello \(account.name.givenName)")
                } else {
                    print(error!)
                }
            }
            // List folder
            client.files.listFolder(path: "").response { (response, error) in
                if let result = response {
                    print("Folder contents:")
                    for entry in result.entries {
                        print(entry.name)
                    }
                } else {
                    print(error!)
                }
            }
            // Upload a file
            let fileData = "Hello!".data(using: String.Encoding.utf8, allowLossyConversion: false)
            client.files.upload(path: "/hello.txt", input: fileData!).response { (response, error) in
                if let metadata = response {
                    print("Uploaded file name: \(metadata.name)")
                    print("Uploaded file revision: \(metadata.rev)")
                    // Get file (or folder) metadata
                    client.files.getMetadata(path: "/hello.txt").response { (response, error) in
                        if let metadata = response {
                            print("Name: \(metadata.name)")
                            if let file = metadata as? Files.FileMetadata {
                                print("This is a file.")
                                print("File size: \(file.size)")
                            } else if metadata is Files.FolderMetadata {
                                print("This is a folder.")
                            }
                        } else {
                            print(error!)
                        }
                    }
                }
                // Download a file
                client.files.download(path: "/hello.txt").response { (response, error) in
                    if let (metadata, data) = response {
                        print("Dowloaded file name: \(metadata.name)")
                        print("Downloaded file data: \(data)")
                    } else {
                        print(error!)
                    }
                }
            }
        }
    }
}
/*
 self.txtViewFtSize += 1
 let textRange = textView.selectedRange
 textView.isScrollEnabled = false
 let attrStr:NSMutableAttributedString = textView.attributedText.mutableCopy() as! NSMutableAttributedString
 
 attrStr.enumerateAttributes(in: NSMakeRange(0, attrStr.length), options: NSAttributedString.EnumerationOptions.reverse) { (attributes, range, stop) in
     var mutableAttributes = attributes
     var currentFont:UIFont = mutableAttributes[NSAttributedString.Key("NSFont")] as! UIFont
     currentFont = currentFont.withSize(CGFloat(txtViewFtSize))
     attrStr.addAttribute(.font, value: currentFont, range: range)

     var paragraphStyle = mutableAttributes[.paragraphStyle] as? NSMutableParagraphStyle
     if !(paragraphStyle != nil) {
         paragraphStyle = NSMutableParagraphStyle.default as? NSMutableParagraphStyle
     }
     paragraphStyle?.minimumLineHeight = CGFloat(txtViewFtSize)
     attrStr.addAttribute(.paragraphStyle, value: paragraphStyle ?? nil, range: range)
 }
 self.textView.attributedText = attrStr
 self.textView.isScrollEnabled = true
 self.textView.selectedRange = textRange
 */



/*
PromptDoc *currentDoc = [[DocumentManager sharedManager] selectedDocument];
    int fontSize = [[currentDoc editTextSize] integerValue];
    fontSize++;
    [currentDoc setEditTextSize:@(fontSize)];
    
    NSRange textRange = [docText selectedRange];
    [docText setScrollEnabled:NO];
    NSMutableAttributedString *attString = [[docText attributedText] mutableCopy];
    [attString enumerateAttributesInRange:NSMakeRange(0, attString.length) options:NSAttributedStringEnumerationReverse usingBlock:
            ^(NSDictionary *attributes, NSRange range, BOOL *stop){
                NSMutableDictionary *mutableAttributes = [NSMutableDictionary dictionaryWithDictionary:attributes];
                UIFont *currentFont = [mutableAttributes valueForKey:@"NSFont"];
                currentFont = [currentFont fontWithSize:fontSize];
                [attString addAttribute:NSFontAttributeName value:currentFont range:range];
                
                NSMutableParagraphStyle *paragraphStyle = [[mutableAttributes valueForKey:NSParagraphStyleAttributeName] mutableCopy];
                if (!paragraphStyle){
                    paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
                }
//                paragraphStyle.lineSpacing = 60 * currentFont.pointSize * 0.01;
                paragraphStyle.minimumLineHeight = fontSize + DefaultLineHeightIncreamentValue;
                [attString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:range];
            }];

    [docText setAttributedText:attString];
    [docText setScrollEnabled:YES];
    [docText setSelectedRange:textRange];

    [self updateEditInfo];
*/
