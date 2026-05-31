//
//  InterstitialAd.swift
//  PluginAdmob
//
//  Created by Peter Popovec on 01/03/2026.
//

import GoogleMobileAds

class InterstitialAdViewModel: NSObject, FullScreenContentDelegate {
    static let shared = InterstitialAdViewModel()
    
    private var interstitialAd: InterstitialAd?
    
    func loadAd(id: String) async {
        do {
            interstitialAd = try await InterstitialAd.load(
                with: id, request: Request())
            interstitialAd?.fullScreenContentDelegate = self
            print("Ad with id: \(id) loaded.")
            NewEvents.shared.fireEvent(type: .onAdLoaded, adUnitId: id)
        } catch {
            print("Failed to load interstitial ad with error: \(error.localizedDescription)")
            NewEvents.shared.fireEvent(type: .onAdLoadFailed, adUnitId: id)
        }
    }
    
    func showAd() {
      guard let interstitialAd = interstitialAd else {
          return print("Ad wasn't ready.")
      }

      interstitialAd.present(from: nil)
    }
}

// MARK: From FullScreenContentDelegate
extension InterstitialAdViewModel {
    func adWillDismissFullScreenContent(_ ad: any FullScreenPresentingAd) {
    }
    
    func adDidDismissFullScreenContent(_ ad: any FullScreenPresentingAd) {
    }
}
