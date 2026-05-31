//
//  AdmobConstants.swift
//  BoardingPassScanner2
//
//  Created by Peter Popovec on 31/05/2026.
//

import MagicUiFramework
import GoogleMobileAds

struct AdmobConstants {
//    ca-app-pub-3940256099942544/2435281174
    static let bannerAdTestUnitId: String = "ca-app-pub-3940256099942544/2934735716"
}

struct PluginAdmob: MagicUiPlugin {
    static func initialise() {
        // for test ads
        //MobileAds.shared.requestConfiguration.testDeviceIdentifiers = ["2077ef9a63d2b398840261c8221a0c9b"];
        
        MobileAds.shared.start()
        
        // views
        MagicUiView.installViewPlugin(name: "admobbanner", plugin: AdmobBanner.self)
        
        // actions
        MagicUiView.installActionPlugin(name: "loadInterstitialAd", plugin: Action_loadInterstitialAd.self)
        MagicUiView.installActionPlugin(name: "showInterstitialAd", plugin: Action_showInterstitialAd.self)
        MagicUiView.installActionPlugin(name: "loadAndShowInterstitialAd", plugin: Action_loadAndShowInterstitialAd.self)
        
        MagicUiView.installActionPlugin(name: "loadRewardedAd", plugin: Action_loadRewardedAd.self)
        MagicUiView.installActionPlugin(name: "showRewardedAd", plugin: Action_showRewardedAd.self)
        MagicUiView.installActionPlugin(name: "loadAndShowRewardedAd", plugin: Action_loadAndShowRewardedAd.self)
    }
}
