//
//  NewDICT.swift
//  PluginAdmob
//
//  Created by Peter Popovec on 07/03/2026.
//

extension String {

    var dict: [String: String] {
        Dictionary(
            uniqueKeysWithValues: self
                .split(separator: ";")
                .compactMap { pair -> (String, String)? in
                    let parts = pair.split(separator: ":")
                    guard parts.count == 2 else { return nil }
                    return (String(parts[0]), String(parts[1]))
                }
        )
    }

}

