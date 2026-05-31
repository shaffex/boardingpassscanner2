//
//  BannerView.swift
//  PluginAdmob
//
//  Created by Peter Popovec on 01/03/2026.
//

import SwiftUI
import GoogleMobileAds

private struct BannerViewContainer: UIViewRepresentable {
    typealias UIViewType = BannerView
    let adUnitID: String
    let adSize: AdSize
    @Binding var isAdLoaded: Bool
    
    init(adUnitID: String, adSize: AdSize, isAdLoaded: Binding<Bool>) {
        self.adUnitID = adUnitID
        self.adSize = adSize
        self._isAdLoaded = isAdLoaded
    }
    
    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: adSize)
        banner.adUnitID = adUnitID
        banner.load(Request())
        banner.delegate = context.coordinator
        return banner
      }

    func updateUIView(_ uiView: BannerView, context: Context) {}
    
    func makeCoordinator() -> BannerCoordinator {
        return BannerCoordinator(self)
    }
    
    class BannerCoordinator: NSObject, BannerViewDelegate {

        let parent: BannerViewContainer

        init(_ parent: BannerViewContainer) {
          self.parent = parent
        }

        // MARK: - GADBannerViewDelegate methods

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            parent.isAdLoaded = true
            print("DID RECEIVE AD.")
            //NewEvents.shared.fireEvent()
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            parent.isAdLoaded = false
            print("FAILED TO RECEIVE AD: \(error.localizedDescription)")
            
            //NewEvents.shared.fireEvent()
        }
      }
}

struct MyBannerView: View {
    let adUnitID: String
    let adSize: AdSize
    @State private var isAdLoaded = true

//    @State private var adSize: AdSize = largeAnchoredAdaptiveBanner(width: UIScreen.main.bounds.width)

    var body: some View {
//        let adSize: AdSize = largeAnchoredAdaptiveBanner(width: UIScreen.main.bounds.width)
        //let adSize: AdSize = adSizeFor(cgSize: CGSize(width: 100, height: 50))
        if isAdLoaded {
            BannerViewContainer(adUnitID: adUnitID, adSize: adSize, isAdLoaded: $isAdLoaded)
                .frame(width: adSize.size.width, height: adSize.size.height)
//                .onGeometryChange(for: CGFloat.self, of: \.size.width) { newWidth in
//                    adSize = largeAnchoredAdaptiveBanner(width: newWidth)
//                }
                .border(.red, width: 5)
//                .onAppear() {
//                    adSize = largeAnchoredAdaptiveBanner(width: UIScreen.main.bounds.width)
//                }
        }
    }
}
