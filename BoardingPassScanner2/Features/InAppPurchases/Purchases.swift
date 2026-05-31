//
//  Purchases.swift
//  Barcoder
//
//  Created by Peter Popovec on 03/08/2025.
//

import StoreKit
import SwiftUI
import Combine

@MainActor
/// Manages in-app purchases using StoreKit 2.
/// Handles product fetching, purchase initiation, restoring, and listening for transaction updates.
final class StoreManager: ObservableObject {
    static let shared = StoreManager()
    
    static let productID_UnlockPro: String = "com.shaffex.boardingpassscanner.unlockpro"

    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []

    private let productIDs = [productID_UnlockPro]
    private var isPurchaseInProgress: Bool = false

    private init() {
        observeTransactionUpdates()
        Task {
            await fetchProducts()
        }
    }

    // MARK: - Transaction Observation

    private func observeTransactionUpdates() {
        Task.detached { [weak self] in
            for await update in StoreKit.Transaction.updates {
                await self?.handleTransaction(update)
            }
        }
    }

    private func handleTransaction(_ result: VerificationResult<StoreKit.Transaction>) async {
        switch result {
        case .verified(let transaction):
            print("STOREMANAGER: Transaction update: \(transaction.productID)")
            if let date = transaction.revocationDate {
                print("STOREMANAGER: Revoked at \(date)")
                self.onProductRevoked(transaction.productID)
            } else {
                await transaction.finish()
                self.onProductOwned(transaction.productID)
            }

        case .unverified(let transaction, let error):
            print("STOREMANAGER: Unverified transaction: \(transaction.productID), error: \(error)")
        }
    }

    // MARK: - Public API

    func fetchProducts() async {
        do {
            products = try await Product.products(for: productIDs)
            await updatePurchasedProducts()
        } catch {
            print("STOREMANAGER: Failed to fetch products: \(error)")
        }
    }

    func purchase(_ product: Product) async {
        guard !isPurchaseInProgress else {
            print("STOREMANAGER: Another purchase is already in progress")
            return
        }
        isPurchaseInProgress = true
        do {
            let result = try await product.purchase()
            if case .success(let verification) = result,
               case .verified(let transaction) = verification {
                await transaction.finish()
                onProductOwned(transaction.productID)
            }
            isPurchaseInProgress = false
        } catch {
            print("STOREMANAGER: Purchase failed: \(error)")
            isPurchaseInProgress = false
        }
    }

    func restorePurchases(showAlert: Bool = false) async {
        print("STOREMANAGER: Restoring purchases")
        await updatePurchasedProducts(showAlert: showAlert)
    }

    func updatePurchasedProducts(showAlert: Bool = false) async {
        print("STOREMANAGER: Updating entitlements")

        var activeIDs: Set<String> = []
        var anyChanges = false

        // Check all transactions (including family shared ones)
        for await result in Transaction.all {
            switch result {
            case .verified(let transaction):
                // Skip if transaction is revoked
                if let _ = transaction.revocationDate {
                    print("STOREMANAGER: Skipping revoked transaction: \(transaction.productID)")
                    continue
                }
                
                // Only consider our product IDs
                if productIDs.contains(transaction.productID) {
                    activeIDs.insert(transaction.productID)
                    print("STOREMANAGER: Found active transaction: \(transaction.productID), ownershipType: \(transaction.ownershipType)")
                }

            case .unverified(let transaction, let error):
                print("STOREMANAGER: Unverified transaction \(transaction.productID), error: \(error)")
            }
        }

        let revoked = purchasedProductIDs.subtracting(activeIDs)
        for id in revoked {
            onProductRevoked(id)
            anyChanges = true
        }

        purchasedProductIDs = activeIDs
        for id in activeIDs {
            onProductOwned(id)
            anyChanges = true
        }

        if !anyChanges {
            print("STOREMANAGER: No changes, resetting flags")
            resetOwnedFlags()
            
            if !purchasedProductIDs.contains(StoreManager.productID_UnlockPro) {
                SxEnvironmentObject.shared.setValue(false, forKey: "FEATURE_UNLOCK_PRO")
            }
        }
        
        if showAlert {
            if purchasedProductIDs.isEmpty {
                PluginActions.shared.runAction("presentAlert:alertNothingToRestore")
            } else {
                PluginActions.shared.runAction("presentAlert:alertPurchasesRestored")
            }
        }
    }

    // MARK: - Helpers

    //@MainActor
    private func resetOwnedFlags() {
        for key in SxEnvironmentObject.shared.allValues.keys where key.hasPrefix("OWNED_") {
            SxEnvironmentObject.shared.setValue(nil, forKey: key)
        }
    }

    // MARK: - Ownership Hooks

    //@MainActor
    func onProductOwned(_ productID: String) {
        print("STOREMANAGER: onProductOwned: \(productID)")
        purchasedProductIDs.insert(productID)
        SxEnvironmentObject.shared.setValue(true, forKey: "OWNED_\(productID)")
        
        if productID == StoreManager.productID_UnlockPro {
            SxEnvironmentObject.shared.setValue(true, forKey: "FEATURE_UNLOCK_PRO")
        }
    }

    //@MainActor
    func onProductRevoked(_ productID: String) {
        print("STOREMANAGER: onProductRevoked: \(productID)")
        purchasedProductIDs.remove(productID)
        SxEnvironmentObject.shared.setValue(false, forKey: "OWNED_\(productID)")
        
        // Handle feature flag invalidation based on which product was revoked
        if productID == StoreManager.productID_UnlockPro {
            // If unlockPro was revoked
            SxEnvironmentObject.shared.setValue(false, forKey: "FEATURE_UNLOCK_PRO")
            print("STOREMANAGER: Revoked pro unlock feature")

        }
    }
}

struct PurchaseView: View {
    @ObservedObject private var store = StoreManager.shared
    let productId: String
    
    var body: some View {
        VStack {
            if let product = store.products.first(where: { $0.id == productId} ) {
                //if !store.purchasedProductIDs.contains(productId) {
                    Button("Buy \(product.displayName) for \(product.displayPrice)") {
                        Task {
                            await store.purchase(product)
                        }
                    }
                //}
            }

//            Button("Restore Purchases") {
//                Task {
//                    await store.restorePurchases()
//                }
//            }
//            .padding(.top)
        }
//        .onAppear {
//            Task {
//                await store.fetchProducts()
//            }
//        }
    }
}

import MagicUiFramework
struct SxView_PurchaseView: SxViewProtocol {
    @DynamicNode var node: MagicNode

    var productId: String? {
        node.getAttribute("productId")
    }
    
    var body: some View {
        if let productId {
            PurchaseView(productId: productId)
        }
    }
}

// actions
struct SxAction_purchaseProduct: SxActionProtocol {
    var node: MagicNode?

    //private var store = StoreManager()

    func execute(_ actionString: String) {
        Task {
            await StoreManager.shared.fetchProducts()
            if let product = StoreManager.shared.products.first(where: { $0.id == actionString} ) {
                await StoreManager.shared.purchase(product)
            }
        }
    }
}

// actions
struct SxAction_restorePurchases: SxActionProtocol {
    var node: MagicNode?

    //private var store = StoreManager.shared

    func execute(_ actionString: String) {
        Task {
            await StoreManager.shared.restorePurchases(showAlert: true)
        }
    }
}
