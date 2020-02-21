//
//  PromptDocumentViewController.swift
//  GigHard_Swift
//
//  Created by osx on 26/11/19.
//  Copyright © 2019 osx. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import CoreMIDI
import CloudKit
import MBProgressHUD

class PromptDocumentViewController: UIViewController {

    //    MARK:- IBOUTLETS
    @IBOutlet weak var audioTimerLbl: UILabel!
    @IBOutlet weak var scrollRateLbl: UILabel!
    @IBOutlet weak var SongTitleLbl: UILabel!
    @IBOutlet weak var titleBgImgView: UIImageView!
    @IBOutlet weak var docTitleLbl: UILabel!
    @IBOutlet weak var playlistTitleLbl: UILabel!
    @IBOutlet weak var scrollableTxtView: UITextView!
    @IBOutlet weak var adViewOutlet: UIView!
    @IBOutlet weak var setListBtnOutlet: UIButton!
    @IBOutlet weak var recorderViewOutlet: UIView!
    @IBOutlet weak var ipadRecorderView: UIView!
    @IBOutlet weak var startBtnOutlet: UIButton!
    @IBOutlet weak var stopBtnOutlet: UIButton!
    @IBOutlet weak var nextSongBtnOutlet: UIButton!
    @IBOutlet weak var previousSongBtnOutlet: UIButton!
    @IBOutlet weak var recorderViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var setListBtnWidthContraint: NSLayoutConstraint!
    @IBOutlet weak var editorBtnOutlet: UIButton!
    @IBOutlet weak var voiceBtnOutlet: UIButton!
    @IBOutlet weak var camViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var camPreview: UIView!
    @IBOutlet weak var audioTrackSlider: UISlider!
    @IBOutlet weak var audioTrackSlideriPad: UISlider!
    @IBOutlet weak var currentTimeLbl: UILabel!
    @IBOutlet weak var currentTimeLbliPad: UILabel!
    @IBOutlet weak var playBtnOutlet: UIButton!
    @IBOutlet weak var playBtnOutletiPad: UIButton!
    @IBOutlet weak var pauseBtnOutlet: UIButton!
    @IBOutlet weak var pauseBtnOutletiPad: UIButton!
    @IBOutlet weak var audioFilesBtnOutlet: UIButton!
    @IBOutlet weak var audioFilesBtnOutletiPad: UIButton!
    @IBOutlet weak var videoBtnOutlet: UIButton!
    @IBOutlet weak var audioRecViewWidthConstraint: NSLayoutConstraint!

    //    MARK:- AND VARIABLES
    let captureSession = AVCaptureSession()
    let movieOutput = AVCaptureMovieFileOutput()
    var previewLayer: AVCaptureVideoPreviewLayer!
    var activeInput: AVCaptureDeviceInput!
    var outputURL: URL!
    var currentOrientation: AVCaptureVideoOrientation?
    var videoConnection: AVCaptureConnection?
    
    var isScrolling:Bool!
    var scrollableViewFontSize:Int! = 16
    var scrollRate: Int!
    var ckRecord:CKRecord?
    var scrollableText:String?
    var documentTitle:String?
    var scrollAttrText: NSAttributedString?
    var documentIndex:Int!
    var docEditTxtSize:Int!
    
    //for countDown
    var seconds = 00
    var audioSeconds = 00
    var isTimeRunning = false
    var countTimer = Timer()
    var resumeTapped = false
    
    //after in-app-purchase
    var isPurchased:Bool!
    var isShowMeActive:Bool? = false
    var isRecordMeActive:Bool? = false
    var isAudioRecActive:Bool? = false
    var player:AVPlayer?
    var urlPath : URL?
    var isVoicePressed:Bool!
    var camCount:Int!
    let panGesture = UIPanGestureRecognizer()
    var feature:FeaturesPurchased = .None
    var selectedRecording : Any?
    var arrAllRecordings = [CKRecord]()
    var newRec:String!
    
    //on gig
    var playlistData:[[String:Any]]?
    var playlistDataIndex = Int()
    var playlistName:String?
    var isGigPressed:Bool? = false
    var isPlayOn:Bool! = false
    
    //MARK: RECORDING AUDIO VARIABLES
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var recordings = [URL]()
    var audioPlayer:AVAudioPlayer!
    var recUrl : URL? = nil
    var isRecPlaying:Bool = false
    var isDraggingTimeSlider = false
    var isFinishRec:Bool! = false
    var isRecordBtnEnable:Bool! = false
    
    var isVideoRecording:Bool! = false
    // convert url to data
    var recordedUrl:URL?
    var recordedData:Data!
    var recordingsCount:Int!
    
    var updateTimer_abh = Timer()
    var sliderTimer_abh = Timer()
    
    
    
//    MARK:- View LIFE CYCLE METHOD(S)
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.recorderViewHeightConstraint.constant = 0
        isVoicePressed = true
        self.isScrolling = true
        self.recUrl = nil
        self.setLayout()
        self.camCount = 0
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapText))
        tapGesture.numberOfTapsRequired = 1
        scrollableTxtView.addGestureRecognizer(tapGesture)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleForegroundState), name: UIApplication.willEnterForegroundNotification, object: nil)
        self.scrollableTxtView.contentInset = UIEdgeInsets(top: self.scrollableTxtView.frame.size.height * 0.4, left: 0.0, bottom: 0.0, right: 0.0)

//  Need To Uncomment before Build
        self.isPurchased = UserDefaults.standard.bool(forKey: "isPurchased")
        if let featureEnabled = UserDefaults.standard.string(forKey: "featuresEnabled") {
            if featureEnabled == "03_gig_pro"{
                feature = .All
            } else if featureEnabled == "02_gig_pro"{
                feature = .SetLists
            } else if featureEnabled == "01_gig_pro"{
                feature = .AudioVideo
            }
        }
        self.view.backgroundColor = .black
        self.hideContents()
        if isPurchased {
            self.showOptionsAfterPurchase()
        }
        if isPurchased {
            if feature == .All || feature == .AudioVideo {
                self.setupView()
            }
        }
        
        self.setCamPreviewLayer()
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
        self.updateDocument { (bool) in
            print(bool)
        }

        if isAudioRecActive == true{
            if audioRecorder != nil {
                finishRecording(success: true)
            }
        }
        if ( UI_USER_INTERFACE_IDIOM() == .pad)
        {
            self.audioTrackSlideriPad.minimumValue = 0
            self.audioTrackSlideriPad.isContinuous = false
            if  self.player != nil {

                 pauseBtnOutletiPad.setImage(UIImage(named: "iph_btn_record_off.png"), for: .normal)
                 playBtnOutletiPad.setImage(UIImage(named: "iph_btn_play_off.png"), for: .normal)
                 let totalDuration =  self.player?.currentItem?.asset.duration
                player?.pause()
                self.audioTrackSlideriPad.minimumValue = 0
                             //self.playPauseButton.setImage(UIImage(named: "play"), for: .normal)
                player?.isMuted = true
            }
        } else {
            self.audioTrackSlider.minimumValue = 0
            self.audioTrackSlider.isContinuous = false
            if  self.player != nil {

                 pauseBtnOutlet.setImage(UIImage(named: "iph_btn_record_off.png"), for: .normal)
                 playBtnOutlet.setImage(UIImage(named: "iph_btn_play_off.png"), for: .normal)
                 let totalDuration =  self.player?.currentItem?.asset.duration
                player?.pause()
                self.audioTrackSlider.minimumValue = 0
                player?.isMuted = true
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        UIApplication.shared.isIdleTimerDisabled = true
        self.getRecordings { (isSuccess) in
            print(isSuccess)
        }
//        self.setOrientation()

        self.scrollableTxtView.textColor = .white
        isShowMeActive = UserDefaults.standard.bool(forKey: "isShowMe")
        isRecordMeActive = UserDefaults.standard.bool(forKey: "isRecordMe")

        if !ipadRecorderView.isHidden {
            self.camPreview.center = CGPoint(x:100, y:self.scrollableTxtView.bounds.height - 80)
        } else {
            self.camPreview.center = CGPoint(x:100, y:self.scrollableTxtView.bounds.height)
        }
        
        videoBtnOutlet.setImage(UIImage(named: "icon_video"), for: .normal)
        videoBtnOutlet.tintColor = UIColor.white
        self.navigationController?.navigationBar.isHidden = true
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        
        if isShowMeActive == true {
            self.camPreview.isHidden = false
            camPreview.backgroundColor = .clear
            self.showMe()
        } else {
            self.camPreview.isHidden = true
        }
        
        if isGigPressed! {
            // 31-1-2020
            self.setLayoutWhenGigPressed()
        }
        self.scrollableTxtView.scrollsToTop = true
        DispatchQueue.main.async {
            MBProgressHUD.hide(for: self.view, animated: true)
        }
        
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if ( UI_USER_INTERFACE_IDIOM() == .pad) {
            var orientation: AVCaptureVideoOrientation
            switch UIDevice.current.orientation {
            case .portrait:
                orientation = .portrait
            case .landscapeLeft:
                orientation = .landscapeRight
            case .landscapeRight:
                orientation = .landscapeLeft
            case .portraitUpsideDown:
                orientation = .portraitUpsideDown
//            case .unknown:
//                orientation = .portraitUpsideDown
//            case .faceUp:
//                orientation = .portraitUpsideDown
//            case .faceDown:
//                orientation = .portraitUpsideDown
            default:
                if self.view.frame.width > self.view.frame.height {
                    orientation = .landscapeRight
                } else {
                    orientation = .portrait
                }

            }

            currentOrientation = orientation

            if !ipadRecorderView.isHidden {
                self.camPreview.center = self.camPreview.center
            } else {
                self.camPreview.center = self.camPreview.center
            }
            if previewLayer != nil {
                previewLayer.videoGravity = .resizeAspectFill
                if currentOrientation != nil{
                    previewLayer.connection?.videoOrientation = currentOrientation!
                } else {
                    previewLayer.connection?.videoOrientation = .portrait
                }
            }
          // when mode of iphone is portrait
        } else {

        }
        /**
        var orientation: AVCaptureVideoOrientation
        switch UIDevice.current.orientation {
        case .portrait:
            orientation = .portrait
        case .landscapeLeft:
            orientation = .landscapeRight
        case .landscapeRight:
            orientation = .landscapeLeft
        case .portraitUpsideDown:
            orientation = .portraitUpsideDown
//        case .unknown:
//            orientation = .portrait
//            //        case .faceDown:
//        //            orientation = .portrait
//        case .faceUp:
//            if self.view.frame.width > self.view.frame.height {
//                if isVideoRecording {
//                    orientation = .landscapeLeft
//                } else {
//                    orientation = .portrait
//                }
//            } else {
//                orientation = .portrait
//            }
//        case .faceDown:
//            orientation = .portrait
        default:
            if self.view.frame.width > self.view.frame.height {
                orientation = .landscapeRight
            } else {
                orientation = .portrait
            }
        }

        currentOrientation = orientation

        if !ipadRecorderView.isHidden {
            self.camPreview.center = self.camPreview.center
        } else {
            self.camPreview.center = self.camPreview.center
        }
        if previewLayer != nil {
            previewLayer.videoGravity = .resizeAspectFill
            if currentOrientation != nil{
                previewLayer.connection?.videoOrientation = currentOrientation!
            } else {
                previewLayer.connection?.videoOrientation = .portrait
            }
        } */

    }
    
//    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
//        coordinator.animate(alongsideTransition: { context in
//            if UIApplication.shared.statusBarOrientation.isLandscape {
//                // activate landscape changes
//                print(UIApplication.shared.statusBarOrientation)
//            } else {
//                // activate portrait changes
//                print(UIApplication.shared.statusBarOrientation)
//            }
//        })
//    }
    
//    MARK:- PRIVATE METHOD(S)
    
    @objc func handleForegroundState() {
        if isShowMeActive == true {
            self.camPreview.isHidden = false
            camPreview.backgroundColor = .clear
            self.showMe()
            self.camPreview.setNeedsLayout()
        } else {
            self.camPreview.isHidden = true
        }
    }
    
    
//    func setOrientation() {
//        var orientation: AVCaptureVideoOrientation
//        switch UIDevice.current.orientation {
//        case .portrait:
//            orientation = .portrait
//        case .landscapeLeft:
//            orientation = .landscapeRight
//        case .landscapeRight:
//            orientation = .landscapeLeft
//        case .portraitUpsideDown:
//            orientation = .portraitUpsideDown
//        case .unknown:
//            orientation = .portrait
//            //        case .faceUp:
//        //            orientation = .portrait
//        case .faceUp:
//            if self.view.frame.width > self.view.frame.height {
//                orientation = .landscapeRight
//            } else {
//                orientation = .portrait
//            }
//        case .faceDown:
//            orientation = .portrait
//        }
//        currentOrientation = orientation
//    }
        
    @objc func scrollLoop() {
        if scrollableTxtView.contentOffset.y > (scrollableTxtView.contentSize.height - scrollableTxtView.frame.size.height / 2) {
        } else {
            let newScrollRate = scrollRate / 2
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(scrollLoop), object: nil)
            UIView.beginAnimations(nil, context: nil)
            UIView.setAnimationCurve(.linear)
            UIView.animate(withDuration: 1.0,
                           delay: 0.0,
                           options: [],
                           animations: {
                            
                            var scrollPoint = self.scrollableTxtView.contentOffset
                            var scrollAmount: CGFloat
                            if ( UI_USER_INTERFACE_IDIOM() == .pad)
                            {
                                scrollAmount = CGFloat(5 * self.scrollRate)
                            } else {
                                scrollAmount = CGFloat(3 * self.scrollRate)
                            }
                            scrollPoint.y = scrollPoint.y + scrollAmount
                            self.scrollableTxtView.setContentOffset(scrollPoint, animated: true)
                            UIView.commitAnimations()
                            self.perform(#selector(self.scrollLoop), with: nil, afterDelay: TimeInterval(0.1))
            },
                           completion: nil)
            self.isScrolling = true
        }
    }
    
    func stopScrolling() {
        let newScrollRate = scrollRate / 2
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(scrollLoop), object: nil)
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationCurve(.linear)
        UIView.animate(withDuration: 0.0,
                       delay: 0.0,
                       options: [],
                       animations: {
        },completion: nil)
        self.isScrolling = false
    }

    @objc func tapText() {
        if self.startBtnOutlet.isHidden {
            if isScrolling {
                self.stopScrolling()
            } else {
                self.scrollLoop()
            }
        } else {
            self.stopScrolling()
        }
    }
    
    func updateDocument(completionHandler: @escaping(_ success: Bool?) -> Void) {
        MBProgressHUD.showAdded(to: self.view, animated: true)
        if documentIndex == nil {
            let docs = DatabaseHelper.shareInstance.fetchNotes { (documents) in
                DispatchQueue.main.async {
                    let documents = documents
                    for index in 0..<documents.count {
                        if documents[index].value(forKey: "documentDescription") as! String == "\(self.scrollableTxtView.text!)" && documents[index].value(forKey: "documentName") as! String == "\(self.SongTitleLbl.text!)" {

                            let docName = documents[index].value(forKey: "documentName") as! String
                            let docDescription = documents[index].value(forKey: "documentDescription") as! String
                            let editSize = documents[index].value(forKey: "editDocumentSize") as! Int
                            let editDocSize = Int(editSize)
                            let promptSize = "\(self.scrollableViewFontSize ?? 20)"
                            let promptTextSize = Int(promptSize)!
                            var docAttrText = NSAttributedString()
                            docAttrText = self.scrollableTxtView.attributedText!
                            let speed = "\(self.scrollRate!)"
                            let promptSpeed = Int(speed)!
                            let updateDate = Date() as Date
                            let docDict = ["documentName": docName,"documentDescription": docDescription,"documentAttrText": docAttrText,"editDocumentSize": editDocSize,"promptDocumentTextSize": promptTextSize,"promptDocumentSpeed": promptSpeed, "docUpdateDate": updateDate] as [String : Any]

                            DatabaseHelper.shareInstance.updateRecordInPlaylist(editRecord: documents[index], documentObj: docDict) { (isSuccess) in
                                }
                                DatabaseHelper.shareInstance.savingNote(editRecord: documents[index], documentObj: docDict) { (record) in
                                    print("saved..")
                                    completionHandler(true)
                                    DispatchQueue.main.async {
                                        MBProgressHUD.hide(for: self.view, animated: true)
                                    }
                                }
                        } else {
//                            DispatchQueue.main.async {
//                                MBProgressHUD.hide(for: self.view, animated: true)
//                            }
                        }
                        DispatchQueue.main.async {
                            self.scrollRateLbl.text = "\(self.scrollRate!)"
                        }
                    }
                }
            }
        } else {
        guard let docName = self.docTitleLbl.text else { return }
        guard let docDescription = self.scrollableTxtView.text else { return }
        let editSize = "\(self.docEditTxtSize!)"
        let editDocSize = Int(editSize)!
        let promptSize = "\(self.scrollableViewFontSize!)"
        let promptTextSize = Int(promptSize)!
        var docAttrText = NSAttributedString()
        docAttrText = self.scrollableTxtView.attributedText!
        let speed = "\(scrollRate!)"
        let promptSpeed = Int(speed)!
        let updateDate = Date() as Date
        let docDict = ["documentName": docName,"documentDescription": docDescription,"documentAttrText": docAttrText,"editDocumentSize": editDocSize,"promptDocumentTextSize": promptTextSize,"promptDocumentSpeed": promptSpeed, "docUpdateDate": updateDate] as [String : Any]
            if ckRecord != nil {
                DatabaseHelper.shareInstance.savingNote(editRecord: ckRecord, documentObj: docDict) { (record) in
                    completionHandler(true)
                    print("saved..")
                    DispatchQueue.main.async {
                        MBProgressHUD.hide(for: self.view, animated: true)
                    }
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
            MBProgressHUD.hide(for: self.view, animated: true)
        }
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
                currentFont = currentFont.withSize(CGFloat(withSize))
                attrStr.addAttribute(.font, value: currentFont, range: range)
            } else {
                attrStr.addAttributes([NSAttributedString.Key.font: UIFont.init(name: "Arial", size: CGFloat(14))], range: range)
            }
        }
        
        textView.attributedText = attrStr
        textView.isScrollEnabled = true
        textView.selectedRange = textRange
    }
    
    private func setUpVideoRecorder(){
        if setupSession() {
            setupPreview()
            startSession()
        }
    }
    
    @objc private func rePostionCamGesture(_ sender: UIPanGestureRecognizer){
        
        camCount += 1
        if recorderViewHeightConstraint.constant != 0 || !ipadRecorderView.isHidden{
            if camCount == 1{
                if ( UI_USER_INTERFACE_IDIOM() == .pad) {
                    sender.view!.center = CGPoint(x:100, y:self.scrollableTxtView.bounds.height - 80)
                } else {
                    sender.view!.center = CGPoint(x:100, y:self.scrollableTxtView.bounds.height)
                }
            } else if camCount == 2{
                if ( UI_USER_INTERFACE_IDIOM() == .pad) {
                    sender.view!.center = CGPoint(x:self.scrollableTxtView.bounds.width - 100, y:self.scrollableTxtView.bounds.height - 80)
                } else {
                    sender.view!.center = CGPoint(x:self.scrollableTxtView.bounds.width - 100, y:self.scrollableTxtView.bounds.height)
                }
            }else if camCount == 3{
                if ( UI_USER_INTERFACE_IDIOM() == .pad) {
                    sender.view!.center = CGPoint(x:self.scrollableTxtView.bounds.width - 100, y:210)
                } else {
                    sender.view!.center = CGPoint(x:self.scrollableTxtView.bounds.width - 100, y:190)
                }
            } else if camCount == 4{
                if ( UI_USER_INTERFACE_IDIOM() == .pad) {
                    sender.view!.center = CGPoint(x:100, y:210)
                } else {
                    sender.view!.center = CGPoint(x:100, y:190)
                }
                camCount = 0
            }
        }
        else {
            if camCount == 1{
                if ( UI_USER_INTERFACE_IDIOM() == .pad) {
                    sender.view!.center = CGPoint(x:100, y:self.scrollableTxtView.bounds.height)
                } else {
                    sender.view!.center = CGPoint(x:100, y:self.scrollableTxtView.bounds.height)
                }
            } else if camCount == 2{
                if ( UI_USER_INTERFACE_IDIOM() == .pad) {
                    sender.view!.center = CGPoint(x:self.scrollableTxtView.bounds.width - 100, y:self.scrollableTxtView.bounds.height)
                } else {
                    sender.view!.center = CGPoint(x:self.scrollableTxtView.bounds.width - 100, y:self.scrollableTxtView.bounds.height)
                }
            }else if camCount == 3{
                if ( UI_USER_INTERFACE_IDIOM() == .pad) {
                    sender.view!.center = CGPoint(x:self.scrollableTxtView.bounds.width - 100, y:210)
                } else {
                    sender.view!.center = CGPoint(x:self.scrollableTxtView.bounds.width - 100, y:190)
                }
            } else if camCount == 4{
                if ( UI_USER_INTERFACE_IDIOM() == .pad) {
                    sender.view!.center = CGPoint(x:100, y:210)
                } else {
                    sender.view!.center = CGPoint(x:100, y:190)
                }
                camCount = 0
            }
        }
    }
    
    func showMe() {
        let capSession = AVCaptureSession()
        guard let capDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: .video, position: .front) else { return }
        guard let input = try? AVCaptureDeviceInput(device: capDevice) else {
            return
        }
        //14-2-20
        guard let capAudio = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInMicrophone, for: .audio, position: .unspecified) else { return }
        guard let micInput = try? AVCaptureDeviceInput(device: capAudio) else {
            return
        }
        capSession.addInput(micInput) //14-2-20
        capSession.addInput(input)
        
        
        capSession.startRunning()
        previewLayer = AVCaptureVideoPreviewLayer(session: capSession)
        previewLayer.videoGravity = .resizeAspectFill
        //21-2-20
//        if currentOrientation != nil{
//            previewLayer.connection?.videoOrientation = currentOrientation!
//        } else {
//            previewLayer.connection?.videoOrientation = .portrait
//        }
        
        self.camPreview.layer.addSublayer(previewLayer)
        previewLayer.frame = self.camPreview.bounds
        //        capSession.commitConfiguration()
    }
    
    func addSwipeGesture() {
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipes(_:)))
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipes(_:)))

        leftSwipe.direction = .left
        rightSwipe.direction = .right
// 21-1-20
         if self.playlistData!.count > 1 {
            self.scrollableTxtView.addGestureRecognizer(leftSwipe)
            self.scrollableTxtView.addGestureRecognizer(rightSwipe)
        }
    }
    
    @objc func handleSwipes(_ sender:UISwipeGestureRecognizer) {
        if self.playlistData == nil {
            
        } else {
            if (sender.direction == .left) {
                DispatchQueue.main.async {
                    self.seconds = 00
                    self.audioTimerLbl.text = self.timeString(time: TimeInterval(self.seconds))
                    self.previousSongBtnOutlet.isHidden = false
                    if self.playlistDataIndex < self.playlistData!.count {
                        let lastDataIdx = (self.playlistData?.count ?? 0) - 2
                        if self.playlistDataIndex == lastDataIdx {
                            self.nextSongBtnOutlet.isHidden = true
                            self.playlistDataIndex += 1
                            
                            if self.playlistData![self.playlistDataIndex]["documentAttrText"] == nil {
                               self.scrollableTxtView.text = self.playlistData?[self.playlistDataIndex]["documentDescription"] as? String ?? ""
                            } else {
                                let attrStr = self.playlistData![self.playlistDataIndex]["documentAttrText"] as! NSAttributedString
                                self.scrollableViewFontSize = self.playlistData![self.playlistDataIndex]["promptDocumentTextSize"] as? Int
                                self.showAttrText(textView: self.scrollableTxtView, attributedText: attrStr, withSize: self.scrollableViewFontSize!)
                                
                                self.scrollableTxtView.textColor = .white
                            }
                            self.scrollRate = self.playlistData![self.playlistDataIndex]["promptDocumentSpeed"]! as! Int
                            self.scrollRateLbl.text = "\(self.scrollRate!)"
                            self.SongTitleLbl.text = self.playlistData?[self.playlistDataIndex]["documentName"] as? String
                        } else {
                            if self.playlistDataIndex == self.playlistData!.count - 1 {
                                
                            } else {
                                self.playlistDataIndex += 1
                                self.previousSongBtnOutlet.isHidden = false
                                if self.playlistData![self.playlistDataIndex]["documentAttrText"] == nil {
                                   self.scrollableTxtView.text = self.playlistData?[self.playlistDataIndex]["documentDescription"] as? String ?? ""
                                } else {
                                    let attrStr = self.playlistData![self.playlistDataIndex]["documentAttrText"] as! NSAttributedString
                                    self.scrollableViewFontSize = self.playlistData![self.playlistDataIndex]["promptDocumentTextSize"] as? Int
                                    self.showAttrText(textView: self.scrollableTxtView, attributedText: attrStr, withSize: self.scrollableViewFontSize!)
                                    
                                    self.scrollableTxtView.textColor = .white
                                }
                                self.scrollRate = self.playlistData![self.playlistDataIndex]["promptDocumentSpeed"]! as! Int
                                self.scrollRateLbl.text = "\(self.scrollRate!)"
                                self.SongTitleLbl.text = self.playlistData?[self.playlistDataIndex]["documentName"] as? String
                            }
                        }
                    } else {
                        self.nextSongBtnOutlet.isHidden = true
                    }
                }
            }
                
            if (sender.direction == .right) {
                DispatchQueue.main.async {
                    self.seconds = 00
                    self.audioTimerLbl.text = self.timeString(time: TimeInterval(self.seconds))
                    self.nextSongBtnOutlet.isHidden = false
                    if self.playlistDataIndex < 1 {
                        self.previousSongBtnOutlet.isHidden = true
                    } else {
                        if self.playlistDataIndex == 1 {
                            self.previousSongBtnOutlet.isHidden = true
                            self.playlistDataIndex -= 1
                            if self.playlistData![self.playlistDataIndex]["documentAttrText"] == nil {
                               self.scrollableTxtView.text = self.playlistData?[self.playlistDataIndex]["documentDescription"] as? String ?? ""
                            } else {
                                let attrStr = self.playlistData![self.playlistDataIndex]["documentAttrText"] as! NSAttributedString
                                self.scrollableViewFontSize = self.playlistData![self.playlistDataIndex]["promptDocumentTextSize"] as? Int
                                self.showAttrText(textView: self.scrollableTxtView, attributedText: attrStr, withSize: self.scrollableViewFontSize!)
                                
                                self.scrollableTxtView.textColor = .white
                            }
                            self.scrollRate = self.playlistData![self.playlistDataIndex]["promptDocumentSpeed"]! as! Int
                            self.scrollRateLbl.text = "\(self.scrollRate!)"
                            self.SongTitleLbl.text = self.playlistData?[self.playlistDataIndex]["documentName"] as? String
                        } else {
                            self.playlistDataIndex -= 1
                            if self.playlistData![self.playlistDataIndex]["documentAttrText"] == nil {
                               self.scrollableTxtView.text = self.playlistData?[self.playlistDataIndex]["documentDescription"] as? String ?? ""
                            } else {
                                let attrStr = self.playlistData![self.playlistDataIndex]["documentAttrText"] as! NSAttributedString
                                self.scrollableViewFontSize = self.playlistData![self.playlistDataIndex]["promptDocumentTextSize"] as? Int
                                self.showAttrText(textView: self.scrollableTxtView, attributedText: attrStr, withSize: self.scrollableViewFontSize!)
                                
                                self.scrollableTxtView.textColor = .white
                            }
                            self.scrollRate = self.playlistData![self.playlistDataIndex]["promptDocumentSpeed"]! as! Int
                            self.scrollRateLbl.text = "\(self.scrollRate!)"
                            self.SongTitleLbl.text = self.playlistData?[self.playlistDataIndex]["documentName"] as? String
                        }
                    }
                }
            }
        }
    }
    func hideContents() {
        self.setListBtnOutlet.isHidden = true
        self.setListBtnWidthContraint.constant = 0.0
        self.videoBtnOutlet.isHidden = true
        self.voiceBtnOutlet.isHidden = true
    }
    
    func setCamPreviewLayer() {
        camPreview.layer.cornerRadius = 12.0
        camPreview.clipsToBounds = true
        camPreview.addGestureRecognizer(panGesture)
        camPreview.isUserInteractionEnabled = true
    }
    
    func setLayout() {
        if ckRecord == nil {
            self.scrollRate = 1
        } else {
            let speed = ckRecord?.value(forKey: "promptDocumentSpeed") as! Int
            self.scrollRate = speed
        }
        
        self.scrollRateLbl.text = "\(scrollRate!)"
        if ckRecord == nil {
            self.scrollableViewFontSize = 20
        } else {
            self.scrollableViewFontSize = ckRecord?.value(forKey: "promptDocumentTextSize") as! Int
        }
        self.titleBgImgView.backgroundColor = UIColor(red: 65/255.0, green: 64/255.0, blue: 64/255.0, alpha: 1)
        if scrollableText != "" {
            if isGigPressed! {
                if self.playlistData![self.playlistDataIndex]["documentAttrText"] == nil {
                   self.scrollableTxtView.text = self.playlistData?[self.playlistDataIndex]["documentDescription"] as? String ?? ""
                } else {
                    // convert data to attributed string
//                    let data = self.playlistData![self.playlistDataIndex]["documentAttrText"] as! Data
//                    let attrString = NSKeyedUnarchiver.unarchiveObject(with: data) as! NSAttributedString
                    let attrStr = self.playlistData![self.playlistDataIndex]["documentAttrText"] as! NSAttributedString
                    self.scrollRate = self.playlistData![self.playlistDataIndex]["promptDocumentSpeed"]! as! Int
                    self.scrollableViewFontSize = self.playlistData![self.playlistDataIndex]["promptDocumentTextSize"] as? Int

                    self.showAttrText(textView: self.scrollableTxtView, attributedText: attrStr, withSize: self.scrollableViewFontSize!)
                    self.scrollRateLbl.text = "\(self.scrollRate!)"
                }
            } else {
                self.docTitleLbl.text = self.documentTitle
                if self.scrollAttrText == nil {
                    self.scrollableTxtView.text = self.scrollableText
                } else {
                    self.scrollableTxtView.attributedText = self.scrollAttrText
                    if self.ckRecord != nil {
                      self.showAttrText(textView: self.scrollableTxtView, attributedText: self.scrollAttrText!, withSize: self.scrollableViewFontSize!)
                    } else {
                        self.scrollableTxtView.font = scrollableTxtView.font?.withSize(CGFloat(scrollableViewFontSize))
                    }
                }
//
                self.scrollableTxtView.textColor = .white
            }
        
        self.stopBtnOutlet.isHidden = true
        self.navigationController?.navigationBar.isHidden = true
        self.scrollableTxtView.textColor = .white
        }
    }
    
    func setLayoutWhenGigPressed() {
        self.addSwipeGesture()
        self.docTitleLbl.isHidden = true
        self.SongTitleLbl.isHidden = false
        self.playlistTitleLbl.isHidden = false
        self.nextSongBtnOutlet.isHidden = false
        self.playlistTitleLbl.text = self.playlistName
        self.playlistDataIndex = 0
        if self.playlistData?.count == 1 || self.playlistData?.count == 0 {
            self.previousSongBtnOutlet.isHidden = true
            self.nextSongBtnOutlet.isHidden = true
        } else {
            self.nextSongBtnOutlet.isHidden = false
        }
        if self.playlistData![self.playlistDataIndex]["documentAttrText"] == nil {
            self.scrollableTxtView.text = self.playlistData?[self.playlistDataIndex]["documentDescription"] as? String ?? ""
        } else {
//            let data = self.playlistData![self.playlistDataIndex]["documentAttrText"] as! Data
//            let attrString = NSKeyedUnarchiver.unarchiveObject(with: data) as! NSAttributedString
            let attrStr = self.playlistData![self.playlistDataIndex]["documentAttrText"] as! NSAttributedString
            self.scrollableViewFontSize = self.playlistData![self.playlistDataIndex]["promptDocumentTextSize"] as? Int
            self.showAttrText(textView: self.scrollableTxtView, attributedText: attrStr, withSize: self.scrollableViewFontSize!)
            self.scrollableTxtView.textColor = .white
        }
        self.SongTitleLbl.text = self.playlistData?[self.playlistDataIndex]["documentName"] as? String
    }
    
    func showOptionsAfterPurchase() {
        if feature == .All {
            self.videoBtnOutlet.isHidden = false
            self.voiceBtnOutlet.isHidden = false
            self.setListBtnOutlet.isHidden = false
            self.setListBtnWidthContraint.constant = 32.0
        } else if feature == .SetLists {
            self.videoBtnOutlet.isHidden = true
            self.voiceBtnOutlet.isHidden = true
            self.setListBtnOutlet.isHidden = false
            self.setListBtnWidthContraint.constant = 32.0
        } else if feature == .AudioVideo {
//            self.stackViewOutlet.isHidden = true
            self.videoBtnOutlet.isHidden = false
            self.voiceBtnOutlet.isHidden = false
            self.setListBtnOutlet.isHidden = true
            self.setListBtnWidthContraint.constant = 0.0
        } else if feature == .None {
            self.videoBtnOutlet.isHidden = true
            self.voiceBtnOutlet.isHidden = true
            self.setListBtnOutlet.isHidden = true
            self.setListBtnWidthContraint.constant = 0.0
        }
    }
    
    func timeString(time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        return String(format: "%02i:%02i:%02i",hours,minutes,seconds)
    }
    
    private func hideCamView(showCamera:Bool){
        camPreview.isHidden = showCamera
        if showCamera == true {
            if let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front) {
            do {
                let input = try AVCaptureDeviceInput(device: camera)
                if captureSession.canAddInput(input) {
                    captureSession.addInput(input)
                    activeInput = input
                }
            } catch {
                print("Error setting device video input: \(error)")
            }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = VideoOptViewController()
        vc.delegate = self
    }
    
//    MARK: AUDIO RECORDING METHODS
    func setupView() {
        recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] allowed in
            }
        } catch {
            // failed to record
        }
    }
    
    func startRecTapped() {
        if audioRecorder == nil {
            startRecording()
        } else {
            finishRecording(success: true)
        }
    }
    
    func startRecording() {
        let audioFilename = getFileURL()
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
            
            self.recordedUrl = audioFilename
        } catch {
            finishRecording(success: false)
        }
    }
    
    func getFileURL() -> URL {
        let path = self.getDocumentsDirectory().appendingPathComponent(newRec+".m4a")
        return path as URL
    }
    
    func checkSongNameExist(name : String) -> Bool {
        var arrOfRecNames = [String]()
        for name in arrAllRecordings {
            let urlStr = name.value(forKey: "recordingStr") as! String
            var recUrl = URL(string: urlStr)
            let recName = recUrl?.lastPathComponent
            arrOfRecNames.append(recName!)
        }

        if arrOfRecNames.contains(name) {
            return true
        }
        else
        {
             return false
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    func finishRecording(success: Bool) {
//        MBProgressHUD.showAdded(to: self.view, animated: true)
//        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
//            MBProgressHUD.hide(for: self.view, animated: true)
//        }
        audioRecorder.stop()
        audioRecorder = nil
        countTimer.invalidate()
        if success {
            
            guard let data = try? Data(contentsOf:self.recordedUrl!) else { return }
//            print(data)
            self.recordedData = data
            let urlStr = self.recordedUrl!.absoluteString
            self.recUrl = self.recordedUrl!
            DatabaseHelper.shareInstance.saveRecToIcloud(editRecord: nil, recData: self.recordedData, recUrl: urlStr) { (isSuccess) in
                if isSuccess! {
                    print("Recprding Saved")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        MBProgressHUD.hide(for: self.view, animated: true)
                        let alertController = UIAlertController(title: "Gig Hard!", message: "Recording is saving to the iCloud drive.", preferredStyle: .alert)
                        let dismissAction = UIAlertAction(title: "OK", style: .cancel) { (alertAction) in
                            DispatchQueue.main.async {
                                self.showIndicator(withTitle: "Gig Hard!", and: "Your recording is saving to the iCloud drive.")
                            }
                            self.getRecordings { (isSuccess) in
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                    self.hideIndicator()
                                    if ( UI_USER_INTERFACE_IDIOM() == .pad) {
                                        self.audioFilesBtnOutletiPad.setTitle(self.recUrl!.lastPathComponent.deletingSuffix(".m4a"), for: .normal)
                                    } else {
                                        self.audioFilesBtnOutlet.setTitle(self.recUrl!.lastPathComponent.deletingSuffix(".m4a"), for: .normal)
                                    }
                                }
                            }
                        }
                        alertController.addAction(dismissAction)
                        self.present(alertController, animated: true, completion: nil)
//                        self.getRecordings()
                    }
                } else {
                    DispatchQueue.main.async {
                        MBProgressHUD.hide(for: self.view, animated: true)
                        self.getRecordings { (isSuccess) in
                            print(isSuccess)
                        }
                    }
                    print("Recording Not Saved")
                }
            }
            
            self.isAudioRecActive = false
//            seconds = 00
            audioSeconds = 00
            self.isFinishRec = true
            if ( UI_USER_INTERFACE_IDIOM() == .pad) {
                self.playBtnOutletiPad.isEnabled = true
                self.currentTimeLbliPad.text = timeString(time: TimeInterval(audioSeconds))
            } else {
                self.playBtnOutlet.isEnabled = true
                self.currentTimeLbl.text = timeString(time: TimeInterval(audioSeconds))
            }
            
        } else {
            print("Recording is not saved")
        }
        
    }
    
    func getRecordings(completionHandler: @escaping(_ success: Bool) -> Void) {
        MBProgressHUD.showAdded(to: self.view, animated: true)
        DatabaseHelper.shareInstance.fetchAllRecordings { (allRecordings) in
            
            self.arrAllRecordings = allRecordings
            self.recordingsCount = allRecordings.count
            self.recFileName()
            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.view, animated: true)
            }
            completionHandler(true)
        }
    }
    
    func listRecordings() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let urls = try FileManager.default.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)
//            print(urls)
            self.recordings = urls.filter( { (name: URL) -> Bool in
                return name.lastPathComponent.hasSuffix("m4a")
            })

        } catch let error as NSError {
            print(error.localizedDescription)
        } catch {
            print("something went wrong listing recordings")
        }
        //dispatch queue
        let sortedRecordings = recordings.sorted { a, b in
            return a.lastPathComponent
                .localizedStandardCompare(b.lastPathComponent)
                    == ComparisonResult.orderedDescending
        }
        if self.isFinishRec {
            if sortedRecordings.count > 0 {
//                self.recUrl = sortedRecordings[0]
            }
            self.isRecPlaying = false
            self.isFinishRec = false
            if ( UI_USER_INTERFACE_IDIOM() == .pad) {
                self.audioFilesBtnOutletiPad.setTitle(self.newRec ?? "Audio Files", for: .normal)
                if audioPlayer != nil {
                    audioPlayer.currentTime = 0.0
                    self.audioTrackSlideriPad.value = Float(audioPlayer.currentTime)
                }
            } else {
                self.audioFilesBtnOutlet.setTitle(self.newRec ?? "Audio Files", for: .normal)
                if audioPlayer != nil {
                    audioPlayer.currentTime = 0.0
                    self.audioTrackSlider.value = Float(audioPlayer.currentTime)
                }
            }
        }
    }
    
    @objc func upSlider() {
        if ( UI_USER_INTERFACE_IDIOM() == .pad) {
            audioTrackSlideriPad.value = Float(audioPlayer.currentTime)
        } else
        {
            audioTrackSlider.value = Float(audioPlayer.currentTime)
        }
    }
    
    func play(_ url:URL, _ data:Data) {
            if isAudioRecActive == true {
                
            } else {
                self.updateTimer_abh = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
            }
            
            self.sliderTimer_abh = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(upSlider), userInfo: nil, repeats: true)


            if ( UI_USER_INTERFACE_IDIOM() == .pad) {
                self.audioFilesBtnOutletiPad.setTitle(url.lastPathComponent.deletingSuffix(".m4a"), for: .normal)
            } else {
                self.audioFilesBtnOutlet.setTitle(url.lastPathComponent.deletingSuffix(".m4a"), for: .normal)
            }
            do {
                if data != nil {
                    self.audioPlayer = try AVAudioPlayer(data: data)
                } else {
                    self.audioPlayer = try AVAudioPlayer(contentsOf: url)
                }
                audioPlayer.prepareToPlay()
                audioPlayer.volume = 10.0
                audioPlayer.play()
                self.isRecPlaying = true
            } catch let error as NSError {
                self.audioPlayer = nil
                print(error.localizedDescription)
            } catch {
                print("AVAudioPlayer init failed")
            }
            if ( UI_USER_INTERFACE_IDIOM() == .pad) {
                audioTrackSlideriPad.maximumValue = Float(audioPlayer.duration)

            } else {
               audioTrackSlider.maximumValue = Float(audioPlayer.duration)
            }
        }

    @objc func playerDidFinishPlaying(sender: Notification) {
        // Your code here
        print("finish playing")
        /**
         if audioPlayer != nil {
             audioPlayer.pause()
         }
         self.isPlayOn = false
         if ( UI_USER_INTERFACE_IDIOM() == .pad) {
             self.playBtnOutletiPad.setImage(#imageLiteral(resourceName: "btn_play_off"), for: .normal)
             self.playBtnOutletiPad.isSelected = false
         } else {
             self.playBtnOutlet.setImage(#imageLiteral(resourceName: "btn_play_off"), for: .normal)
             self.playBtnOutlet.isSelected = false
         }
         
         NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
         */
    }
    
    
    func stringFromTimeInterval(interval: TimeInterval) -> String {
        let interval = Int(interval)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        let hours = (interval / 3600)
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    @objc func updateTime() {
        if audioPlayer != nil {
            let currentTime = Int(audioPlayer.currentTime)
            let duration = Int(audioPlayer.duration)
            let interval = Int(currentTime)
            let seconds = currentTime % 60
            let minutes = (currentTime / 60) % 60
            let hours = (currentTime / 3600)
            if isAudioRecActive == false {
                if ( UI_USER_INTERFACE_IDIOM() == .pad) {
                    currentTimeLbliPad.text = NSString(format: "%02d:%02d:%02d",hours, minutes,seconds) as String
                } else {
                    currentTimeLbl.text = NSString(format: "%02d:%02d:%02d",hours, minutes,seconds) as String
                }
            }
        }

    }
    
    @objc func updateTimer() {
        seconds += 1
        audioSeconds += 1
        self.audioTimerLbl.text = timeString(time: TimeInterval(seconds))
        if isAudioRecActive == true {
            if ( UI_USER_INTERFACE_IDIOM() == .pad) {
                self.currentTimeLbliPad.text = timeString(time: TimeInterval(audioSeconds))
            } else {
                self.currentTimeLbl.text = timeString(time: TimeInterval(audioSeconds))
            }
        }
    }
    
    func randomString(length: Int) -> String {
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)
        var randomString = ""
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        return randomString
    }
    
    func recFileName() -> String {
        var name:String!
        var arrOfRecNames = [String]()
        for name in arrAllRecordings {
            let urlStr = name.value(forKey: "recordingStr") as! String
            var recUrl = URL(string: urlStr)
            let recName = recUrl?.lastPathComponent
            arrOfRecNames.append(recName!)
        }
        if arrOfRecNames.contains("Take \(self.recordingsCount + 1).m4a") {
            name = self.getDocumentsDirectory().appendingPathComponent("Take \(self.recordingsCount + 1) \(self.randomString(length: 2)).m4a").lastPathComponent.deletingSuffix(".m4a")
        } else {
            name = self.getDocumentsDirectory().appendingPathComponent("Take \(self.recordingsCount + 1).m4a").lastPathComponent.deletingSuffix(".m4a")
        }
        self.checkSongNameExist(name: name)
        if self.checkSongNameExist(name: name) {
            self.newRec = "\(name)_\(self.randomString(length: 1))"
        } else {
            self.newRec = name
        }
        return name as String
    }

    //    MARK:- Top Bar IBACTION(S)
    @IBAction func setListBtn(_ sender: UIButton) {
        if audioPlayer != nil {
            audioPlayer.stop()
            self.playBtnOutlet.setImage(#imageLiteral(resourceName: "btn_play_off"), for: .normal)
        }
        
        if isGigPressed! {
            MBProgressHUD.showAdded(to: self.view, animated: true)
            self.updateDocument { (bool) in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    MBProgressHUD.hide(for: self.view, animated: true)
                    let setListVC = self.storyboard?.instantiateViewController(withIdentifier: "SetListViewControllerID") as! SetListViewController
                    setListVC.delegate = self
                    setListVC.isPrompt = true
                    self.navigationController?.pushViewController(setListVC, animated: true)
                }
            }
        } else {
            MBProgressHUD.showAdded(to: self.view, animated: true)
            guard let docName = self.docTitleLbl.text else { return }
            guard let docDescription = self.scrollableTxtView.text else { return }
            let editSize = "\(self.docEditTxtSize!)"
            let editDocSize = Int(editSize)!
            let promptSize = "\(self.scrollableViewFontSize!)"
            let promptTextSize = Int(promptSize)!
            var docAttrText = NSAttributedString()
            docAttrText = self.scrollableTxtView.attributedText!
            let speed = "\(scrollRate!)"
            let promptSpeed = Int(speed)!
            let updateDate = Date() as Date
            let docDict = ["documentName": docName,"documentDescription": docDescription,"documentAttrText": docAttrText,"editDocumentSize": editDocSize,"promptDocumentTextSize": promptTextSize,"promptDocumentSpeed": promptSpeed, "docUpdateDate": updateDate] as [String : Any]
            if ckRecord != nil {
                DatabaseHelper.shareInstance.savingNote(editRecord: ckRecord, documentObj: docDict) { (record) in
                    DispatchQueue.main.async {
                        MBProgressHUD.hide(for: self.view, animated: true)
                        let setListVC = self.storyboard?.instantiateViewController(withIdentifier: "SetListViewControllerID") as! SetListViewController
                        setListVC.delegate = self
                        setListVC.isPrompt = true
                        self.navigationController?.pushViewController(setListVC, animated: true)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    MBProgressHUD.hide(for: self.view, animated: true)
                }
                let setListVC = self.storyboard?.instantiateViewController(withIdentifier: "SetListViewControllerID") as! SetListViewController
                setListVC.delegate = self
                setListVC.isPrompt = true
                self.navigationController?.pushViewController(setListVC, animated: true)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
            MBProgressHUD.hide(for: self.view, animated: true)
        }
    }
    
    @IBAction func editorBtn(_ sender: UIButton) {
        if audioPlayer != nil {
            audioPlayer.stop()
            self.playBtnOutlet.setImage(#imageLiteral(resourceName: "btn_play_off"), for: .normal)
        }
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func videoBtn(_ sender: UIButton) {
        if audioPlayer != nil {
            audioPlayer.pause()
        }
        self.isPlayOn = false
        if ( UI_USER_INTERFACE_IDIOM() == .pad) {
            self.playBtnOutletiPad.setImage(#imageLiteral(resourceName: "btn_play_off"), for: .normal)
            self.playBtnOutletiPad.isSelected = false
        } else {
            self.playBtnOutlet.setImage(#imageLiteral(resourceName: "btn_play_off"), for: .normal)
            self.playBtnOutlet.isSelected = false
        }
        
        let videoOptVC = self.storyboard?.instantiateViewController(withIdentifier: "VideoOptViewControllerID") as! VideoOptViewController
        videoOptVC.delegate = self
        let navController = UINavigationController(rootViewController: videoOptVC)
        navController.modalPresentationStyle = .fullScreen
        self.navigationController?.present(navController, animated: true, completion: nil)
//        self.navigationController?.pushViewController(videoOptVC, animated: true)
    }
    
    @IBAction func audioBtn(_ sender: UIButton) {
        self.getRecordings { (isSuccess) in
            print(isSuccess)
        }
        self.stopBtnOutlet.isHidden = true
        self.startBtnOutlet.isHidden = false
        countTimer.invalidate()
        seconds = 00
        self.audioTimerLbl.text = timeString(time: TimeInterval(seconds))
        self.isTimeRunning = false
        if isVoicePressed {
            isVoicePressed = false
            pauseBtnOutlet.setImage(UIImage(named: "iph_btn_record_off.png"), for: .normal)
            playBtnOutlet.setImage(UIImage(named: "iph_btn_play_off.png"), for: .normal)
            if ( UI_USER_INTERFACE_IDIOM() == .pad) {
                ipadRecorderView.isHidden = false
                if !ipadRecorderView.isHidden {
                    self.camPreview.center = CGPoint(x:100, y:self.scrollableTxtView.bounds.height - 80)
                } else {
                    self.camPreview.center = CGPoint(x:100, y:self.scrollableTxtView.bounds.height)
                }
            } else {
                ipadRecorderView.isHidden = true
                self.recorderViewOutlet.isHidden = false
                self.recorderViewHeightConstraint.constant = 120.0
            }
        } else {
            if !ipadRecorderView.isHidden {
                self.camPreview.center = CGPoint(x:100, y:self.scrollableTxtView.bounds.height - 80)
            } else {
                self.camPreview.center = CGPoint(x:100, y:self.scrollableTxtView.bounds.height)
            }
            
            isVoicePressed = true
            if audioPlayer != nil {
                audioPlayer.pause()
            }
            self.isPlayOn = false
            if ( UI_USER_INTERFACE_IDIOM() == .pad) {
                ipadRecorderView.isHidden = true
                self.playBtnOutletiPad.setImage(#imageLiteral(resourceName: "btn_play_off"), for: .normal)
                self.playBtnOutletiPad.isSelected = false
            } else {
                ipadRecorderView.isHidden = true
                self.recorderViewOutlet.isHidden = true
                self.recorderViewHeightConstraint.constant = 0.0
                self.playBtnOutlet.setImage(#imageLiteral(resourceName: "btn_play_off"), for: .normal)
                self.playBtnOutlet.isSelected = false
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
            MBProgressHUD.hide(for: self.view, animated: true)
        }
    }
    
    @IBAction func refreshTimerBtn(_ sender: UIButton) {
        seconds = 00
        self.audioTimerLbl.text = timeString(time: TimeInterval(seconds))
    }
    
    @IBAction func nextSongAction(_ sender: UIButton) {
        DispatchQueue.main.async {
            self.seconds = 00
            self.audioTimerLbl.text = self.timeString(time: TimeInterval(self.seconds))
            self.previousSongBtnOutlet.isHidden = false
            if self.playlistDataIndex < self.playlistData?.count ?? 0 {
                let lastDataIdx = (self.playlistData?.count ?? 0) - 2
                if self.playlistDataIndex == lastDataIdx {
                    self.nextSongBtnOutlet.isHidden = true
                    self.playlistDataIndex += 1
                    
                    if self.playlistData![self.playlistDataIndex]["documentAttrText"] == nil {
                       self.scrollableTxtView.text = self.playlistData?[self.playlistDataIndex]["documentDescription"] as? String ?? ""
                    } else {
                        let attrStr = self.playlistData![self.playlistDataIndex]["documentAttrText"] as! NSAttributedString
                        self.scrollableViewFontSize = self.playlistData![self.playlistDataIndex]["promptDocumentTextSize"] as? Int
                        self.showAttrText(textView: self.scrollableTxtView, attributedText: attrStr, withSize: self.scrollableViewFontSize!)
                        
                        self.scrollableTxtView.textColor = .white
                    }
                    self.scrollRate = self.playlistData![self.playlistDataIndex]["promptDocumentSpeed"]! as! Int
                    self.scrollRateLbl.text = "\(self.scrollRate!)"
                    self.SongTitleLbl.text = self.playlistData?[self.playlistDataIndex]["documentName"] as? String
                } else {
                    self.playlistDataIndex += 1
                    self.previousSongBtnOutlet.isHidden = false
                    if self.playlistData![self.playlistDataIndex]["documentAttrText"] == nil {
                       self.scrollableTxtView.text = self.playlistData?[self.playlistDataIndex]["documentDescription"] as? String ?? ""
                    } else {
                        let attrStr = self.playlistData![self.playlistDataIndex]["documentAttrText"] as! NSAttributedString
                        self.scrollableViewFontSize = self.playlistData![self.playlistDataIndex]["promptDocumentTextSize"] as? Int
                        self.showAttrText(textView: self.scrollableTxtView, attributedText: attrStr, withSize: self.scrollableViewFontSize!)
                        
                        self.scrollableTxtView.textColor = .white
                    }
                    self.scrollRate = self.playlistData![self.playlistDataIndex]["promptDocumentSpeed"]! as! Int
                    self.scrollRateLbl.text = "\(self.scrollRate!)"
                    self.SongTitleLbl.text = self.playlistData?[self.playlistDataIndex]["documentName"] as? String
                }
            } else {
                self.nextSongBtnOutlet.isHidden = true
            }
        }
    }
    
    @IBAction func previousSongAction(_ sender: UIButton) {
        DispatchQueue.main.async {
            self.seconds = 00
            self.audioTimerLbl.text = self.timeString(time: TimeInterval(self.seconds))
            self.nextSongBtnOutlet.isHidden = false
            if self.playlistDataIndex < 1 {
                self.previousSongBtnOutlet.isHidden = true
            } else {
                if self.playlistDataIndex == 1 {
                    self.previousSongBtnOutlet.isHidden = true
                    self.playlistDataIndex -= 1
                    if self.playlistData![self.playlistDataIndex]["documentAttrText"] == nil {
                       self.scrollableTxtView.text = self.playlistData?[self.playlistDataIndex]["documentDescription"] as? String ?? ""
                    } else {
                        let attrStr = self.playlistData![self.playlistDataIndex]["documentAttrText"] as! NSAttributedString
                        self.scrollableViewFontSize = self.playlistData![self.playlistDataIndex]["promptDocumentTextSize"] as? Int
                        self.showAttrText(textView: self.scrollableTxtView, attributedText: attrStr, withSize: self.scrollableViewFontSize!)
                        
                        self.scrollableTxtView.textColor = .white
                    }
                    self.scrollRate = self.playlistData![self.playlistDataIndex]["promptDocumentSpeed"]! as! Int
                    self.scrollRateLbl.text = "\(self.scrollRate!)"
                    self.SongTitleLbl.text = self.playlistData?[self.playlistDataIndex]["documentName"] as? String
                } else {
                    self.playlistDataIndex -= 1
                    if self.playlistData![self.playlistDataIndex]["documentAttrText"] == nil {
                       self.scrollableTxtView.text = self.playlistData?[self.playlistDataIndex]["documentDescription"] as? String ?? ""
                    } else {
                        let attrStr = self.playlistData![self.playlistDataIndex]["documentAttrText"] as! NSAttributedString
                        self.scrollableViewFontSize = self.playlistData![self.playlistDataIndex]["promptDocumentTextSize"] as? Int
                        self.showAttrText(textView: self.scrollableTxtView, attributedText: attrStr, withSize: self.scrollableViewFontSize!)
                        
                        self.scrollableTxtView.textColor = .white
                    }
                    self.scrollRate = self.playlistData![self.playlistDataIndex]["promptDocumentSpeed"]! as! Int
                    self.scrollRateLbl.text = "\(self.scrollRate!)"
                    self.SongTitleLbl.text = self.playlistData?[self.playlistDataIndex]["documentName"] as? String
                }
            }
        }
    }
    
//    MARK:- BOTTOM BAR ACTION(S)
    @IBAction func decreaseFontBtn(_ sender: UIButton) {
        
        if self.scrollableViewFontSize == 8 {
            
        } else {
            if ckRecord != nil {
                scrollableTxtView.isScrollEnabled = false
                self.scrollableViewFontSize -= 1
                let textRange = scrollableTxtView.selectedRange
                let attrStr:NSMutableAttributedString = scrollableTxtView.attributedText.mutableCopy() as! NSMutableAttributedString

                attrStr.enumerateAttributes(in: NSMakeRange(0, attrStr.length), options: NSAttributedString.EnumerationOptions.reverse) { (attributes, range, stop) in
                    let mutableAttributes = attributes
                    var currentFont:UIFont = mutableAttributes[NSAttributedString.Key("NSFont")] as! UIFont
                    currentFont = currentFont.withSize(CGFloat(scrollableViewFontSize))
                    attrStr.addAttribute(.font, value: currentFont, range: range)
                }
                
                self.scrollableTxtView.attributedText = attrStr
                self.scrollableTxtView.selectedRange = textRange
                self.scrollableTxtView.isScrollEnabled = true
            } else {
                self.scrollableViewFontSize -= 1
                self.scrollableTxtView.font = scrollableTxtView.font?.withSize(CGFloat(scrollableViewFontSize))
            }
            
        }
    }
    
    @IBAction func increaseFontBtn(_ sender: UIButton) {
        if ckRecord != nil {
            self.scrollableViewFontSize += 1
            scrollableTxtView.isScrollEnabled = false
            let textRange = scrollableTxtView.selectedRange
            let attrStr:NSMutableAttributedString = scrollableTxtView.attributedText.mutableCopy() as! NSMutableAttributedString

            attrStr.enumerateAttributes(in: NSMakeRange(0, attrStr.length), options: NSAttributedString.EnumerationOptions.reverse) { (attributes, range, stop) in
                let mutableAttributes = attributes
                var currentFont:UIFont = mutableAttributes[NSAttributedString.Key("NSFont")] as! UIFont
                currentFont = currentFont.withSize(CGFloat(scrollableViewFontSize))
                attrStr.addAttribute(.font, value: currentFont, range: range)
            }
            
            self.scrollableTxtView.attributedText = attrStr
            self.scrollableTxtView.selectedRange = textRange
            self.scrollableTxtView.isScrollEnabled = true
        } else {
            self.scrollableViewFontSize += 1
            self.scrollableTxtView.font = scrollableTxtView.font?.withSize(CGFloat(scrollableViewFontSize))
        }
    }
    
    @IBAction func startBtn(_ sender: UIButton) {
        self.startBtnOutlet.isHidden = true
        self.stopBtnOutlet.isHidden = false
        //MARK: video recording
        if self.isRecordMeActive == true{
            self.videoBtnOutlet.tintColor = UIColor.red
            self.isVideoRecording = true
            self.setUpVideoRecorder()
            self.startCapture()
        }
        self.scrollLoop()
        
        self.seconds = 00
        self.audioSeconds = 00
        self.audioTimerLbl.text = self.timeString(time: TimeInterval(self.seconds))
        if self.isTimeRunning == false {
            self.countTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateTimer), userInfo: nil, repeats: true)
            self.isTimeRunning = true
        }
        //MARK: audio recording
        if self.isAudioRecActive == true{
            if self.audioRecorder == nil  {
                self.startRecording()
                if ( UI_USER_INTERFACE_IDIOM() == .pad) {
                    if self.pauseBtnOutletiPad.isEnabled == true{
                        if self.isAudioRecActive == true {
                            self.currentTimeLbliPad.text = self.timeString(time: TimeInterval(self.audioSeconds))
                        }
                        if self.audioPlayer != nil {
                            self.audioPlayer.currentTime = 0.0
                            self.audioTrackSlideriPad.value = Float(self.audioPlayer.currentTime)
                            self.playBtnOutletiPad.isEnabled = false
                        }
                    }
                } else {
                    if self.pauseBtnOutlet.isEnabled == true{
                        if self.isAudioRecActive == true {
                            self.currentTimeLbl.text = self.timeString(time: TimeInterval(self.audioSeconds))
                        }
                        if self.audioPlayer != nil {
                            self.audioPlayer.currentTime = 0.0
                            self.audioTrackSlider.value = Float(self.audioPlayer.currentTime)
                            self.playBtnOutlet.isEnabled = false
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func stopBtn(_ sender: UIButton) {
        
        DispatchQueue.main.async {
            self.stopBtnOutlet.isHidden = true
            self.startBtnOutlet.isHidden = false
            self.countTimer.invalidate()
            self.isTimeRunning = false
            if self.isRecordMeActive == true{
                self.videoBtnOutlet.tintColor = UIColor.white
                self.isVideoRecording = false
                MBProgressHUD.showAdded(to: self.view, animated: true)
                self.stopRecording()
            }
            if self.isAudioRecActive == true{
                if self.audioRecorder != nil {
                    MBProgressHUD.showAdded(to: self.view, animated: true)
                    self.finishRecording(success: true)
                    if ( UI_USER_INTERFACE_IDIOM() == .pad) {
                        self.pauseBtnOutletiPad.setImage(#imageLiteral(resourceName: "iph_btn_record_ready"), for: .normal)
                    } else {
                        self.pauseBtnOutlet.setImage(#imageLiteral(resourceName: "iph_btn_record_ready"), for: .normal)
                    }
                    self.isRecordBtnEnable = false
                }
            }
            if self.isScrolling {
                self.stopScrolling()
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            MBProgressHUD.hide(for: self.view, animated: true)
        }
    }
    
    @IBAction func speedDownBtn(_ sender: UIButton) {
        if self.scrollRate == 1 {
            
        } else {
            self.scrollRate! -= 1
            self.scrollRateLbl.text = "\(scrollRate!)"
        }
    }
    
    @IBAction func speedUpBtn(_ sender: UIButton) {
        if self.scrollRate == 15 {
            
        } else {
            self.scrollRate! += 1
            self.scrollRateLbl.text = "\(scrollRate!)"
        }
    }
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        if audioPlayer != nil {
            audioPlayer.currentTime = TimeInterval(sender.value)
            if isPlayOn {
                audioPlayer.play()
            }
        }
    }

    //    MARK:- PLAY AUDIO RECORDING VIEW IBACTION(S)
    @IBAction func pauseBtn(_ sender: UIButton) {
        self.isRecordBtnEnable = !self.isRecordBtnEnable!
        if self.isRecordBtnEnable! == true {
            self.isAudioRecActive = true
            self.listRecordings()
            if ( UI_USER_INTERFACE_IDIOM() == .pad) {
                self.audioFilesBtnOutletiPad.setTitle(self.newRec, for: .normal)  // after duplicate
                self.pauseBtnOutletiPad.setImage(#imageLiteral(resourceName: "btn_record_on"), for: .normal)
            }
            else {
                self.audioFilesBtnOutlet.setTitle(self.newRec, for: .normal) // after duplicate
                self.pauseBtnOutlet.setImage(#imageLiteral(resourceName: "btn_record_on"), for: .normal)
            }
            if self.audioPlayer != nil {
                self.audioPlayer.stop()  // 24-1-20
                self.audioPlayer.currentTime = 0.0
                if ( UI_USER_INTERFACE_IDIOM() == .pad) {
                    self.audioTrackSlideriPad.value = Float(self.audioPlayer.currentTime)
                    self.playBtnOutletiPad.isEnabled = false
                } else {
                    self.audioTrackSlider.value = Float(self.audioPlayer.currentTime)
                    self.playBtnOutlet.isEnabled = false
                }
            }
        } else {
            self.isAudioRecActive = false
            if ( UI_USER_INTERFACE_IDIOM() == .pad) {
                self.audioFilesBtnOutletiPad.setTitle(self.recUrl?.lastPathComponent.deletingSuffix(".m4a") ?? "Audio Files", for: .normal)
                self.pauseBtnOutletiPad.setImage(#imageLiteral(resourceName: "btn_record_ready"), for: .normal)
                self.playBtnOutletiPad.isEnabled = true
            } else {
                self.audioFilesBtnOutlet.setTitle(self.recUrl?.lastPathComponent.deletingSuffix(".m4a") ?? "Audio Files", for: .normal)
                self.pauseBtnOutlet.setImage(#imageLiteral(resourceName: "iph_btn_record_ready"), for: .normal)
                self.playBtnOutlet.isEnabled = true
            }
            if self.audioRecorder != nil {
                self.finishRecording(success: true)
            }
        }
    }
      @IBAction func playBtn(_ sender: UIButton) {
        if recUrl != nil {
            
            sender.isSelected = !sender.isSelected
            if sender.isSelected == false {
                
                self.isPlayOn = false
                    audioPlayer.pause()
                
                    if ( UI_USER_INTERFACE_IDIOM() == .pad) {
                        self.playBtnOutletiPad.setImage(#imageLiteral(resourceName: "btn_play_off"), for: .normal)
                        self.pauseBtnOutletiPad.isEnabled = true
                    } else {
                        self.playBtnOutlet.setImage(#imageLiteral(resourceName: "btn_play_off"), for: .normal)
                        self.pauseBtnOutlet.isEnabled = true
                    }
            } else {
                self.isPlayOn = true
                if ( UI_USER_INTERFACE_IDIOM() == .pad) {
                    self.playBtnOutletiPad.setImage(#imageLiteral(resourceName: "btn_play_on"), for: .normal)
                    self.pauseBtnOutletiPad.isEnabled = false
                } else {
                    self.playBtnOutlet.setImage(#imageLiteral(resourceName: "btn_play_on"), for: .normal)
                    self.pauseBtnOutlet.isEnabled = false
                }
                if isRecPlaying {
                    audioPlayer?.play()
                    if ( UI_USER_INTERFACE_IDIOM() == .pad) {
                        audioTrackSlideriPad.maximumValue = Float(audioPlayer.duration)
                    } else {
                        audioTrackSlider.maximumValue = Float(audioPlayer.duration)
                    }
                } else {
                    self.isAudioRecActive = false
                    self.play(self.recUrl!, self.recordedData)
                    self.isRecPlaying = true
                }
            }
        } else {
            audioPlayer = nil
            if ( UI_USER_INTERFACE_IDIOM() == .pad) {
                self.playBtnOutletiPad.setImage(#imageLiteral(resourceName: "btn_play_off"), for: .normal)
            }
            else {
                self.playBtnOutlet.setImage(#imageLiteral(resourceName: "btn_play_off"), for: .normal)
            }
        }
    }
    
    @IBAction func audioFilesBtn(_ sender: UIButton) {
        let audioFilesVC = self.storyboard?.instantiateViewController(withIdentifier: "SettingsViewControllerID") as! SettingsViewController
        audioFilesVC.isAudioFiles = true
        audioFilesVC.delegate = self
        self.navigationController?.pushViewController(audioFilesVC, animated: true)
    }
    
    @IBAction func repostionViewAction(_ sender: UIButton) {
        UIView.animate(withDuration: 0.7, animations: {
            self.rePostionCamGesture(self.panGesture)
        }, completion: nil)
    }
}


//MARK:- VIDEO RECORDING,CAMERA AND DELEGATE METHOD(S)
extension PromptDocumentViewController : AVCaptureFileOutputRecordingDelegate {
    
    func setupPreview() {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = camPreview.bounds
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        camPreview.layer.addSublayer(previewLayer)
    }

    func setupSession() -> Bool {
        movieOutput.movieFragmentInterval = CMTime.invalid
        captureSession.sessionPreset = AVCaptureSession.Preset.high
        let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front)
        do {
            let input = try AVCaptureDeviceInput(device: camera!)
           
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                activeInput = input
            }
        } catch {
            print("Error setting device video input: \(error)")
            return false
        }

        let microphone = AVCaptureDevice.default(.builtInMicrophone , for: AVMediaType.audio  , position: .unspecified)
        do {
            let micInput = try AVCaptureDeviceInput(device: microphone!)
            if captureSession.canAddInput(micInput) {
                captureSession.addInput(micInput)
            }
        } catch {
            print("Error setting device audio input: \(error)")
            return false
        }
        // Movie output
        if captureSession.canAddOutput(movieOutput) {
            captureSession.addOutput(movieOutput)
            captureSession.startRunning()
        }
        
        return true
    }
    
//  MARK: Camera Session
    func startSession() {
        if !captureSession.isRunning {
//            videoQueue().async {
                self.captureSession.startRunning()
//            }
        }
    }
    
    func stopSession() {
        if captureSession.isRunning {
            videoQueue().async {
                self.captureSession.stopRunning()
            }
        }
    }
    
    func videoQueue() -> DispatchQueue {
        return DispatchQueue.main
    }
    //MARK: orientation
//    func setVideoOrientation() -> AVCaptureVideoOrientation{
//        videoConnection = movieOutput.connection(with: .video)
//
//        if (videoConnection!.isVideoOrientationSupported) {
//            print("connection!.isVideoOrientationSupported")
//            if let capOr = AVCaptureVideoOrientation(rawValue: UIDevice.current.orientation.rawValue) {
//                print("connection!.videoOrientation = \(capOr.rawValue)")
//                currentOrientation = capOr
//                videoConnection!.videoOrientation = currentOrientation!
//            } else {
//                currentOrientation = .portrait
//                videoConnection!.videoOrientation = currentOrientation!
//            }
//        } else {
//            currentOrientation = .portrait
//        }
//        return currentOrientation!
//    }
    
    @objc func startCapture() {
        startRecordingVideo()
    }
    
    func tempURL() -> URL? {
        let directory = NSTemporaryDirectory() as NSString
        
        if directory != "" {
            let path = directory.appendingPathComponent(NSUUID().uuidString + ".mp4")
            return URL(fileURLWithPath: path)
        }
        return nil
    }
    
//    func settingVideoOrientation() {
//        var orientation: AVCaptureVideoOrientation
//        switch UIDevice.current.orientation {
//        case .portrait:
//            orientation = .portrait
//        case .landscapeLeft:
//            orientation = .landscapeRight
//        case .landscapeRight:
//            orientation = .landscapeLeft
//        case .portraitUpsideDown:
//            orientation = .portraitUpsideDown
//        case .unknown:
//            orientation = .portrait
////                    case .faceDown:
////                    orientation = .portrait
//        case .faceUp:
//            if self.view.frame.width > self.view.frame.height {
//                if isVideoRecording {
//                    orientation = .landscapeLeft
//                } else {
//                    orientation = .portrait
//                }
//            } else {
//                orientation = .portrait
//            }
//        case .faceDown:
//            orientation = .portrait
//        }
//
//        currentOrientation = orientation
//
//        if !ipadRecorderView.isHidden {
//            self.camPreview.center = self.camPreview.center
//        } else {
//            self.camPreview.center = self.camPreview.center
//        }
//
//        previewLayer.videoGravity = .resizeAspectFill
//        if currentOrientation != nil{
//            previewLayer.connection?.videoOrientation = currentOrientation!
//        } else {
//            previewLayer.connection?.videoOrientation = .portrait
//        }
//    }
    
    func startRecordingVideo() {
        if movieOutput.isRecording == false {
            let connection = movieOutput.connection(with: .video)  // 18-1-20
//            if ( UI_USER_INTERFACE_IDIOM() == .pad) {
//                self.settingVideoOrientation()
//            } else {
//            }
            
            //                if (connection?.isVideoStabilizationSupported)! {
            ////                    connection?.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.auto
            //                }
            
            let device = activeInput.device
            
            if (device.isSmoothAutoFocusSupported) {
                
                do {
                    try device.lockForConfiguration()
                    device.isSmoothAutoFocusEnabled = false
                    device.unlockForConfiguration()
                } catch {
                    print("Error setting configuration: \(error)")
                }
            }
            
            //EDIT2: And I forgot this
            outputURL = tempURL()
            movieOutput.startRecording(to: outputURL, recordingDelegate: self)
        }
        else {
            stopRecording()
        }
    }
    
    func stopRecording() {
        if movieOutput.isRecording == true {
            movieOutput.stopRecording()
        }
    }
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {
        
    }
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if (error != nil) {
            print("Error recording movie: \(error!.localizedDescription)")
        } else {
            DispatchQueue.main.async {
                self.showMe()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                let alertController = UIAlertController(title: "Video Recording", message: "Your recording has been saved to the photo roll. To view, go to the photos app on your device", preferredStyle: .alert)
                
                let okAction = UIAlertAction(title: "OK", style: .cancel) { (alertAction) in
                }

                alertController.addAction(okAction)
                self.present(alertController, animated: true, completion: nil)
                let videoRecorded = self.outputURL! as URL
                UISaveVideoAtPathToSavedPhotosAlbum(outputFileURL.path, nil, nil, nil)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
                MBProgressHUD.hide(for: self.view, animated: true)
            }
        }
    }
    
//    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
//           coordinator.animate(alongsideTransition: nil) { _ in UIView.setAnimationsEnabled(true) }
//           UIView.setAnimationsEnabled(false)
//           super.viewWillTransition(to: size, with: coordinator)
//           print("VIEW WILL TRANSITION")
//           if let videoOrientation = AVCaptureVideoOrientation(rawValue: UIDevice.current.orientation.rawValue) {
//               print("videoOrientation updated = \(videoOrientation.rawValue)")
//
//            currentOrientation = videoOrientation
//            videoConnection?.videoOrientation = currentOrientation!
//            previewLayer?.connection?.videoOrientation = currentOrientation!
//           }
//        if isShowMeActive == true{
//            if movieOutput.isRecording == false {
//                showMe()
//            }
//        }
//    }
}

extension PromptDocumentViewController: PromptSongDelegate, VideoOptViewControllerDelegate , SettingsViewControllerDelegate {
    
    func playRec(recUrl: URL, recData: Data) {
        self.recUrl = recUrl
        self.recordedData = recData
        do {
            if recData != nil {
                self.audioPlayer = try AVAudioPlayer(data: self.recordedData)
            } else {
                self.audioPlayer = try AVAudioPlayer(contentsOf: self.recUrl!)
            }
            audioPlayer.prepareToPlay()
            audioPlayer.volume = 10.0
        } catch let err {
            print(err.localizedDescription)
        }
        if ( UI_USER_INTERFACE_IDIOM() == .pad) {
            self.audioFilesBtnOutletiPad.setTitle(recUrl.lastPathComponent.deletingSuffix(".m4a"), for: .normal)
            self.playBtnOutletiPad.isEnabled = true
            if self.isPlayOn {
                self.play(recUrl, self.recordedData)
            } else {
            }
        } else {
            self.audioFilesBtnOutlet.setTitle(recUrl.lastPathComponent.deletingSuffix(".m4a"), for: .normal)
            self.playBtnOutlet.isEnabled = true
            if self.isPlayOn {
                self.playBtnOutlet.setImage(#imageLiteral(resourceName: "btn_play_on"), for: .normal)
                self.play(recUrl, self.recordedData)
            } else {
            }
        }
    }
    
    func selectPromptRecord(promptRecord: CKRecord, indexValue: Int?) {
//        can be used later
    }
    
 
    func featureSelected(cameraSel: Bool?, videoRecSel: Bool?) {
        isShowMeActive = cameraSel
        isRecordMeActive = videoRecSel
        hideCamView(showCamera: isShowMeActive ?? false)
    }
    
    func selectSongFromSortedList(song: [String : Any], indexValue: Int?) {
        
    }
}
//MARK:- AUDIO RECORDER CONTROLLER
extension PromptDocumentViewController: AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    func fileManager(_ fileManager: FileManager, shouldMoveItemAt srcURL: URL, to dstURL: URL) -> Bool {

        print("should move \(srcURL) to \(dstURL)")
        return true
    }
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("Error while recording audio \(error!.localizedDescription)")
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
   
        print("finish playing")
        /**
         if audioPlayer != nil {
             audioPlayer.pause()
         }
         self.isPlayOn = false
         if ( UI_USER_INTERFACE_IDIOM() == .pad) {
             self.playBtnOutletiPad.setImage(#imageLiteral(resourceName: "btn_play_off"), for: .normal)
             self.playBtnOutletiPad.isSelected = false
         } else {
             self.playBtnOutlet.setImage(#imageLiteral(resourceName: "btn_play_off"), for: .normal)
             self.playBtnOutlet.isSelected = false
         }
         */
        
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("Error while playing audio \(error!.localizedDescription)")
    }
    
}

extension String {
    func deletingSuffix(_ suffix: String) -> String {
        guard self.hasSuffix(suffix) else { return self }
        return String(self.dropLast(suffix.count))
    }
}
