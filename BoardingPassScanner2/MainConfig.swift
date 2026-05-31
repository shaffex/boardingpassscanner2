//
//  MainConfig.swift
//  BoardingPassScanner2
//
//  Created by Peter Popovec on 31/05/2026.
//

struct MainConfig {
    
    
    
#if DEBUG
    static let adUnitID_Banner = "ca-app-pub-3940256099942544/2934735716" // this is test id
    static let adUnitID_Interstitial = "ca-app-pub-3940256099942544/4411468910" // this is test id
    
    // Show Add to Apple wallet even for Past passes
    static let TESTING_MODE = true
    
    // Show test passes from DEBUG_TestPAsses.xml
    static let TESTING_MODE_SHOW_TESTPASSES = true
    
    // Show debug request what are we passing to API call
    static let TESTING_MODE_SHOW_WALLET_DEBUG_REQUEST = false
    
    // Disable ADS
    static let TESTING_MODE_NOADS = false
#else
    static let adUnitID_Banner = "ca-app-pub-8228478698443038/7381360240" // BPS2_SMART_BANNER
    static let adUnitID_Interstitial = "ca-app-pub-8228478698443038/4450733121" // BPS2_INTERSTITIAL
    static let TESTING_MODE = false
    static let TESTING_MODE_SHOW_TESTPASSES = false
    static let TESTING_MODE_SHOW_WALLET_DEBUG_REQUEST = false
    
    static let TESTING_MODE_NOADS = false
#endif
}
