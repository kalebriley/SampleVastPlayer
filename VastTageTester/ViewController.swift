//
//  ViewController.swift
//  VastTageTester
//
//  Created by Kaleb Riley on 8/8/19.
//  Copyright © 2019 tyko9. All rights reserved.
//

import AVFoundation
import GoogleInteractiveMediaAds
import UIKit

class ViewController: UIViewController, IMAAdsLoaderDelegate, IMAAdsManagerDelegate {
    
    static let kTestAppContentUrl_MP4 = "https://storage.googleapis.com/gvabox/media/samples/stock.mp4"
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var videoView: UIView!
    var contentPlayer: AVPlayer?
    var playerLayer: AVPlayerLayer?
    @IBOutlet weak var companionView: UIView!
    
    var contentPlayhead: IMAAVPlayerContentPlayhead?
    var adsLoader: IMAAdsLoader!
    var adsManager: IMAAdsManager!
    var slot: IMACompanionAdSlot!
    
    static let kTestAppAdTagUrl = "https://aas.radio-stg.com/ad/vast?station_category=foo&station_id=3&station_type=interactive&breakDuration=300&timeSinceAd=1000000&station_genre=test&udid=1&station_market=Test&platform=apigateway&station_callsign=REWIND_TESTBED";
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        playButton.layer.zPosition = CGFloat.greatestFiniteMagnitude
        
        setUpContentPlayer()
        setUpAdsLoader()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        playerLayer?.frame = self.videoView.layer.bounds
    }
    
    @IBAction func onPlayButtonTouch(_ sender: AnyObject) {
        //contentPlayer.play()
        requestAds()
        //playButton.isHidden = true
    }
    
    func setUpContentPlayer() {
        // Load AVPlayer with path to our content.
        guard let contentURL = URL(string: ViewController.kTestAppContentUrl_MP4) else {
            print("ERROR: please use a valid URL for the content URL")
            return
        }
        contentPlayer = AVPlayer(url: contentURL)
        
        // Create a player layer for the player.
  //      playerLayer = AVPlayerLayer(player: contentPlayer)
        
        // Size, position, and display the AVPlayer.
//        playerLayer?.frame = videoView.layer.bounds
//        videoView.layer.addSublayer(playerLayer!)
        slot = IMACompanionAdSlot(view: companionView, width: 300, height: 250)
        
        
        // Set up our content playhead and contentComplete callback.
        contentPlayhead = IMAAVPlayerContentPlayhead(avPlayer: contentPlayer)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ViewController.contentDidFinishPlaying(_:)),
            name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
            object: contentPlayer?.currentItem);
    }
    
    @objc func contentDidFinishPlaying(_ notification: Notification) {
        // Make sure we don't call contentComplete as a result of an ad completing.
        if (notification.object as! AVPlayerItem) == contentPlayer?.currentItem {
            adsLoader.contentComplete()
        }
    }
    
    func setUpAdsLoader() {
        adsLoader = IMAAdsLoader(settings: nil)
        adsLoader.delegate = self
    }
    
    func requestAds() {
        // Create ad display container for ad rendering.
        let adDisplayContainer = IMAAdDisplayContainer(adContainer: videoView, companionSlots: [slot])
        // Create an ad request with our ad tag, display container, and optional user context.
        let request = IMAAdsRequest(
            adTagUrl: ViewController.kTestAppAdTagUrl,
            adDisplayContainer: adDisplayContainer,
            contentPlayhead: contentPlayhead,
            userContext: nil)
        request?.vastLoadTimeout = 100000
        
        adsLoader.requestAds(with: request)
    }
    
    // MARK: - IMAAdsLoaderDelegate
    
    func adsLoader(_ loader: IMAAdsLoader!, adsLoadedWith adsLoadedData: IMAAdsLoadedData!) {
        // Grab the instance of the IMAAdsManager and set ourselves as the delegate.
        adsManager = adsLoadedData.adsManager
        adsManager.delegate = self
        
        // Create ads rendering settings and tell the SDK to use the in-app browser.
        let adsRenderingSettings = IMAAdsRenderingSettings()
        adsRenderingSettings.webOpenerPresentingController = self
        adsRenderingSettings.webOpenerDelegate = self
        
        // Initialize the ads manager.
        adsManager.initialize(with: adsRenderingSettings)
    }
    
    func adsLoader(_ loader: IMAAdsLoader!, failedWith adErrorData: IMAAdLoadingErrorData!) {
        print("Error loading ads: \(adErrorData.adError.message)")
        contentPlayer?.play()
    }
    
    // MARK: - IMAAdsManagerDelegate
    
    func adsManager(_ adsManager: IMAAdsManager!, didReceive event: IMAAdEvent!) {
        if event.type == IMAAdEventType.LOADED {
            // When the SDK notifies us that ads have been loaded, play them.
            adsManager.start()
            videoView.bringSubviewToFront(companionView)
        }
    }
    
    func adsManager(_ adsManager: IMAAdsManager!, didReceive error: IMAAdError!) {
        // Something went wrong with the ads manager after ads were loaded. Log the error and play the
        // content.
        print("AdsManager error: \(error.message)")
        contentPlayer?.play()
    }
    
    func adsManagerDidRequestContentPause(_ adsManager: IMAAdsManager!) {
        // The SDK is going to play ads, so pause the content.
        contentPlayer?.pause()
    }
    
    func adsManagerDidRequestContentResume(_ adsManager: IMAAdsManager!) {
        // The SDK is done playing ads (at least for now), so resume the content.
        contentPlayer?.play()
    }
}

extension ViewController: IMAWebOpenerDelegate {
    func webOpenerWillOpenExternalBrowser(_ webOpener: NSObject!) {
        print("ad clicked")
    }
}

