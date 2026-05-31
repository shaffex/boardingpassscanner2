//
//  ConsentManager.swift
//  BoardingPassScanner2
//

import UIKit
import UserMessagingPlatform
import GoogleMobileAds

@MainActor
final class ConsentManager {
    static let shared = ConsentManager()

    private init() {}

    func requestConsentAndStartAds() async {
        do {
            try await requestConsentInfoUpdate()
            try await loadAndPresentFormIfRequired()
        } catch {
            print("UMP: \(error.localizedDescription)")
        }
        if UMPConsentInformation.sharedInstance.canRequestAds {
            await MobileAds.shared.start()
        }
    }

    private func requestConsentInfoUpdate() async throws {
        let parameters = UMPRequestParameters()
        parameters.tagForUnderAgeOfConsent = false
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            UMPConsentInformation.sharedInstance.requestConsentInfoUpdate(with: parameters) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    private func loadAndPresentFormIfRequired() async throws {
        guard let rootVC = rootViewController() else { return }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            UMPConsentForm.loadAndPresentIfRequired(from: rootVC) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    private func rootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
    }
}
