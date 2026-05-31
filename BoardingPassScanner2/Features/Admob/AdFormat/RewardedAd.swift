//
//  RewardedAd.swift
//  PluginAdmob
//
//  Created by Peter Popovec on 08/03/2026.
//

import GoogleMobileAds

class RewardedAdViewModel: NSObject, FullScreenContentDelegate {
    static let shared = RewardedAdViewModel()
    
    private var rewardedAd: RewardedAd?
    private var lastReward: AdReward?
    
    func loadAd(id: String) async {
        do {
            rewardedAd = try await RewardedAd.load(
                with: id, request: Request())
            rewardedAd?.fullScreenContentDelegate = self
            print("Ad with id: \(id) loaded.")
            NewEvents.shared.fireEvent(type: .onAdLoaded, adUnitId: id)
        } catch {
            print("Failed to load interstitial ad with error: \(error.localizedDescription)")
            NewEvents.shared.fireEvent(type: .onAdLoadFailed, adUnitId: id)
        }
    }
    
    func showAd() {
        guard let rewardedAd = rewardedAd else {
            return print("Ad wasn't ready.")
        }
        
        rewardedAd.present(from: nil) {
            //UserDidEarnRewardHandler
            let reward = rewardedAd.adReward
            print("Reward amount: \(reward.amount)")
            self.lastReward = reward
        }
    }
}

// MARK: From FullScreenContentDelegate
extension RewardedAdViewModel {
    func adWillDismissFullScreenContent(_ ad: any FullScreenPresentingAd) {
    }
    
    func adDidDismissFullScreenContent(_ ad: any FullScreenPresentingAd) {
        if let rewardedAd, let reward = lastReward {
            let rewardString = "\(reward.amount.intValue) \(reward.type)" // Example "10 coins"
            NewEvents.shared.fireEvent(type: .onAdRewardGranted, adUnitId: rewardedAd.adUnitID, extraString: rewardString)
        }
        
        lastReward = nil
    }
}
