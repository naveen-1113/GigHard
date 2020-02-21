//
//  WebViewController.swift
//  GigHard_Swift
//
//  Created by osx on 04/12/19.
//  Copyright © 2019 osx. All rights reserved.
//

import UIKit
import WebKit
class WebViewController: UIViewController {

    @IBOutlet weak var webView: UIView!
    var wkWebview:WKWebView!
    var urlStr = ""
    var activityIndicator:UIActivityIndicatorView!
//    var isActivityView:Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let doneBtn = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(handleDoneAction))
        self.navigationItem.rightBarButtonItem = doneBtn
        self.startWebView(urlStr: urlStr)
    }
    
    @objc func handleDoneAction() {
        self.dismiss(animated: true, completion: nil)
    }
    func startWebView(urlStr: String?) {
        
        wkWebview = WKWebView()
        wkWebview.navigationDelegate = self
        self.view = wkWebview
        activityIndicator = UIActivityIndicatorView()
        
      
        
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        if #available(iOS 13.0, *) {
            activityIndicator.style = .medium
        } else {
            //activityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.medium)
        }
        self.webView.addSubview(activityIndicator)
        let url = URL(string: urlStr!)
        let request = URLRequest(url: url!)
        wkWebview.load(request)
    }

}
//MARK: WebView Delegate
extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print(error)
        if error._code == NSURLErrorNotConnectedToInternet {
            print("Not Connected to INT")
        }
        switch error._code {
        case NSURLErrorNotConnectedToInternet:
            print("Not Connected to INT")
        case NSURLErrorBadURL:
            print("Bad url")
        case NSURLErrorUnknown:
            print("Unknown:\(NSURLErrorUnknown)")
        case NSURLErrorCancelled:
            print("Cancelled")
        case NSURLErrorSecureConnectionFailed:
            print(error.localizedDescription)
        default:
            print(error.localizedDescription)
        }
        let alert = UIAlertController(title: "Failed", message: "\(error.localizedDescription)", preferredStyle: .alert)
        let dismissAction = UIAlertAction(title: "OK", style: .default) { (dismiss) in
            self.dismiss(animated: true, completion: nil)
        }
        alert.addAction(dismissAction)
        self.present(alert, animated: true, completion: nil)

    }
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        self.showSpinner(onView: self.view)
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.removeSpinner()
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.removeSpinner()
        print(error)
    }
    
}

var vSpinner: UIView?
extension WebViewController {
    @objc func showSpinner(onView : UIView) {
        let spinnerView = UIView.init(frame: onView.bounds)
        spinnerView.backgroundColor = UIColor.init(red: 34, green: 15, blue: 55, alpha: 1)
        
        var ai = UIActivityIndicatorView()
        
        if #available(iOS 13.0, *) {
             ai = UIActivityIndicatorView(style: .medium)
        } else {
            // Fallback on earlier versions
        }

        ai.startAnimating()
        ai.center = spinnerView.center
        
        DispatchQueue.main.async {
            spinnerView.addSubview(ai)
            onView.addSubview(spinnerView)
        }
        
        vSpinner = spinnerView
    }
    
    func removeSpinner() {
        DispatchQueue.main.async {
            vSpinner?.removeFromSuperview()
            vSpinner = nil
        }
    }
}
