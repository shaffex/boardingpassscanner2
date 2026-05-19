//
//  Action_showBanner.swift
//  BoardingPassScanner2
//
//  Created by Peter Popovec on 18/05/2026.
//

import MagicUiFramework

// showBanner:type:error;text:aaaaa

struct Action_showBanner: SxActionProtocol {
    let node: MagicNode?
    
    func bannerType(_ str: String) -> String {
        actionParts(str).first?
            .replacingOccurrences(of: "type:", with: "") ?? ""
    }
    
    func bannerText(_ str: String) -> String {
        guard actionParts(str).count > 1 else {
            return str
        }
        
        return actionParts(str)[1]
            .replacingOccurrences(of: "text:", with: "")
    }
    
    private func actionParts(_ str: String) -> [String] {
        str.split(separator: ";", maxSplits: 1, omittingEmptySubsequences: false)
            .map(String.init)
    }
    
    func execute(_ actionString: String) {
        let text = bannerText(actionString)
    }
}
