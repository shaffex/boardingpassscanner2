//
//  AdmobBanner.swift
//  BoardingPassScanner2
//
//  Created by Peter Popovec on 31/05/2026.
//

import MagicUiFramework
import SwiftUI
import GoogleMobileAds

struct AdmobBanner: SxViewProtocol {
    @DynamicNode var node: MagicNode
    
    // adSize="320x50"
    
    var adSize: AdSize {
        let params = node.getAttribute("adSize") ?? ""
        
        // is it custom?
        let dict = params.dict
        if let width=dict["width"]?.convertToDouble(), let height=dict["height"]?.convertToDouble() {
            return adSizeFor(cgSize: CGSize(width: width, height: height))
        }
        
        if params == "320x50" {
            return AdSizeBanner
        }
        if params == "320x100" {
            return AdSizeLargeBanner
        }
        if params == "300x250" {
            return AdSizeMediumRectangle
        }
        if params == "AdSizeFullBanner" {
            return AdSizeFullBanner
        }
        if params == "AdSizeLeaderboard" {
            return AdSizeLeaderboard
        }

        //return currentOrientationAnchoredAdaptiveBanner(width: UIScreen.main.bounds.width)
        //return inlineAdaptiveBanner(width: UIScreen.main.bounds.width, maxHeight: 90.0)
        return largeAnchoredAdaptiveBanner(width: UIScreen.main.bounds.width)
    }
    
    var body: some View {
        MyBannerView(adUnitID: node.getAttribute("adUnitID") ?? AdmobConstants.bannerAdTestUnitId, adSize: adSize)
    }
}
