//
//  BoardingPassDetailView.swift
//  BoardingPassScanner2
//
//  Created by Peter Popovec on 24/05/2026.
//

import SwiftUI
import PassKit
import MagicUiFramework

struct BoardingPassDetailView: View {
    let record: BoardingPassRecord

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var debugMode = false
    @State private var showDecodedSheet = false
    @State private var showDeleteAlert = false
    @State private var isAddingToWallet = false
    @State private var showWalletSpinner = false

    var body: some View {
        ZStack {
            screenBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 26) {
                    barcodeCard
                    BoardingPassCard(record: record)
                    tripDetails
                    if isUpcomingBoardingPass {
                        if debugMode {
                            walletDebugPanel
                        }
                        walletButton
                    }
                    actionButtons
                    decodedDataButton
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 34)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(colorScheme == .dark ? .dark : .light, for: .navigationBar)
        .onAppear(perform: refreshDebugMode)
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            refreshDebugMode()
        }
        .alert("Warning", isPresented: $showDeleteAlert) {
            Button("No", role: .cancel) {}
            Button("Yes", role: .destructive) {
                Haptics.success()
                BoardingPassStore.shared.delete(record)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this boarding pass?\n\nPlease note, this action is irreversible.")
        }
        .sheet(isPresented: $showDecodedSheet) {
            NavigationStack {
                BoardingPassDecodedView(record: record)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showDecodedSheet = false }
                        }
                    }
            }
        }
    }

    private var tripDetails: some View {
        HStack {
            detailBlock(title: "DEPARTURE", value: departureTime)
            Spacer()
            detailBlock(title: "DATE", value: dateText)
            Spacer()
            detailBlock(title: "DAY", value: dayText)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(panelBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(panelStroke, lineWidth: 1)
        }
    }

    private var barcodeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("BOARDING PASS")
                        .font(.system(.caption, design: .monospaced, weight: .bold))
                        .tracking(3)
                        .foregroundStyle(.black.opacity(0.55))
                    Text(displayValue(record.name))
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                Spacer()

                Text(record.type.isEmpty ? "CODE" : record.type.uppercased())
                    .font(.system(.caption, design: .monospaced, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .frame(height: 34)
                    .background(.black, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            MagicUiView(string: "<body><barcode barcodeType=\"\(record.type)\">\(record.text)</barcode></body>")
                .frame(maxWidth: .infinity, minHeight: 132)
                .background(.white)

            Text(record.text)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.black.opacity(0.58))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(22)
        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var walletButton: some View {
        ZStack {
            AddToWalletButton(addPassButtonStyle: .black, isEnabled: !isAddingToWallet) {
                addToWallet()
            }
            .allowsHitTesting(!isAddingToWallet)
            .opacity(isAddingToWallet ? 0.55 : 1)

            if showWalletSpinner {
                ProgressView()
                    .tint(.white)
                    .controlSize(.regular)
                    .padding(10)
                    .background(.black.opacity(0.5), in: Circle())
            }
        }
        .frame(maxWidth: .infinity, minHeight: 56, maxHeight: 56)
        .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func addToWallet() {
        guard !isAddingToWallet else { return }

        isAddingToWallet = true
        showWalletSpinner = false

        Task {
            let spinnerTask = Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    showWalletSpinner = true
                }
            }

            await Action_addPass.presentForRecord(record)
            spinnerTask.cancel()

            await MainActor.run {
                isAddingToWallet = false
                showWalletSpinner = false
            }
        }
    }

    private var walletDebugPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("DEBUG: Apple Wallet request", systemImage: "ladybug")
                .font(.headline.weight(.semibold))
                .foregroundStyle(primaryText)

            Text(Action_addPass.requestDebugDescription(for: record))
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(panelBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(panelStroke, lineWidth: 1)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 14) {
            ShareLink(item: record.text) {
                Label("Share", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(DetailActionButtonStyle())
            .hapticTap()

            Button(role: .destructive) {
                Haptics.warning()
                showDeleteAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(DetailActionButtonStyle(foregroundColor: .red))
        }
    }

    private var decodedDataButton: some View {
        Button {
            Haptics.tap()
            showDecodedSheet = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "info.circle")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text("Decoded IATA BCBP data")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(primaryText)

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(panelBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(panelStroke, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private func refreshDebugMode() {
        debugMode = MagicUiBrisge.isDebugModeEnabled
    }

    private var isUpcomingBoardingPass: Bool {
        Calendar.current.startOfDay(for: record.flightDate) >= Calendar.current.startOfDay(for: .now)
    }

    private var screenBackground: Color {
        colorScheme == .dark ? .black : Color(uiColor: .systemGroupedBackground)
    }

    private var panelBackground: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : .white
    }

    private var panelStroke: Color {
        colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08)
    }

    private var primaryText: Color {
        colorScheme == .dark ? .white : .black
    }

    private var departureTime: String {
        record.flightDate.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
    }

    private var dateText: String {
        record.flightDate.formatted(.dateTime.day().month(.abbreviated))
    }

    private var dayText: String {
        record.flightDate.formatted(.dateTime.weekday(.abbreviated))
    }

    private func detailBlock(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(.caption, design: .monospaced, weight: .bold))
                .tracking(3)
                .foregroundStyle(.secondary)
            Text(displayValue(value))
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private func displayValue(_ value: String) -> String {
        value.isEmpty ? "--" : value
    }
}

private struct DetailActionButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme

    var foregroundColor: Color = .primary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(foregroundColor)
            .frame(height: 58)
            .background(buttonBackground(isPressed: configuration.isPressed), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(buttonStroke, lineWidth: 1)
            }
    }

    private func buttonBackground(isPressed: Bool) -> Color {
        if colorScheme == .dark {
            return Color.white.opacity(isPressed ? 0.16 : 0.08)
        }

        return Color.white.opacity(isPressed ? 0.72 : 1)
    }

    private var buttonStroke: Color {
        colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08)
    }
}

