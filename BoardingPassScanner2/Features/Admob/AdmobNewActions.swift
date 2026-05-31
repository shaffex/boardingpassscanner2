//
//  NewActions.swift
//  PluginAdmob
//
//  Created by Peter Popovec on 01/03/2026.
//

import MagicUiFramework

struct TemplatePluginAction: SxActionProtocol {
    var node: MagicNode?
    
    func execute(_ actionString: String) {
        print("Action print executed with param: \(actionString)")
    }
}

// loadAd
// showAd
// loadAndShowAd

struct Action_loadInterstitialAd: SxActionProtocol {
    var node: MagicNode?
    
    func execute(_ actionString: String) {
        Task {
            await InterstitialAdViewModel.shared.loadAd(id: actionString)
        }
    }
}

struct Action_showInterstitialAd: SxActionProtocol {
    var node: MagicNode?
    
    func execute(_ actionString: String) {
        InterstitialAdViewModel.shared.showAd()
    }
}

struct Action_loadAndShowInterstitialAd: SxActionProtocol {
    var node: MagicNode?
    
    func execute(_ actionString: String) {
        Task { @MainActor in
            await InterstitialAdViewModel.shared.loadAd(id: actionString)
            InterstitialAdViewModel.shared.showAd()
        }
    }
}

// RewardedAd
struct Action_loadRewardedAd: SxActionProtocol {
    var node: MagicNode?
    
    func execute(_ actionString: String) {
        Task {
            await RewardedAdViewModel.shared.loadAd(id: actionString)
        }
    }
}

struct Action_showRewardedAd: SxActionProtocol {
    var node: MagicNode?
    
    func execute(_ actionString: String) {
        RewardedAdViewModel.shared.showAd()
    }
}

struct Action_loadAndShowRewardedAd: SxActionProtocol {
    var node: MagicNode?
    
    func execute(_ actionString: String) {
        Task { @MainActor in
            await RewardedAdViewModel.shared.loadAd(id: actionString)
            RewardedAdViewModel.shared.showAd()
        }
    }
}
