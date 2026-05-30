//
//  BoardingPassDetailView.swift
//  BoardingPassScanner2
//
//  Created by Peter Popovec on 24/05/2026.
//

import SwiftUI
internal import PassKit
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
    @State private var passForegroundColor: Color = .white
    @State private var passBackgroundColor: Color = Color(red: 0.10, green: 0.22, blue: 0.45)
    @State private var passLabelColor: Color = Color(red: 0.85, green: 0.88, blue: 0.95)
    @State private var passSemanticsEnabled: Bool = false
    @State private var showFieldsEditor = false
    @State private var showYearInfo = false
    @State private var departureTimeOverride: Date? = nil

    @AppStorage("passFieldsConfigJSON") private var passFieldsConfigJSON: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 26) {
                barcodeCard
                BoardingPassCard(record: record)
                tripDetails
                // KOKOCE: remove || true
                if isUpcomingBoardingPass || true {
                    if debugMode {
                        walletDebugPanel
                    }
                    customizePanel
                    walletTimingPanel
                    walletButton
                }
                actionButtons
                decodedDataButton
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 34)
        }
        .background(screenBackground.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(colorScheme == .dark ? .dark : .light, for: .navigationBar)
        .onAppear {
            refreshDebugMode()
            if #unavailable(iOS 26) { passSemanticsEnabled = false }
        }
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
        .sheet(isPresented: $showFieldsEditor) {
            PassFieldsEditorView(
                config: passFieldsConfigBinding,
                record: record,
                foregroundColor: passForegroundColor,
                backgroundColor: passBackgroundColor,
                labelColor: passLabelColor,
                semantics: passSemanticsEnabled,
                departureTimeOverride: departureTimeOverride
            )
        }
    }

    private var tripDetails: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                detailBlock(title: "DATE", value: dateText)
                Spacer()
                detailBlock(title: "DAY", value: dayText)
                Spacer()
                yearDetailBlock
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(panelBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(panelStroke, lineWidth: 1)
        }
        .sheet(isPresented: $showYearInfo) {
            VStack(alignment: .leading, spacing: 14) {
                Label("About the flight year", systemImage: "calendar.badge.exclamationmark")
                    .font(.headline.weight(.semibold))

                Text("BCBP barcodes encode the flight date as a **Julian day** (day of the year, e.g. 131 = May 11) but do **not** include the year.")
                    .font(.subheadline)

                Text("The app picks the most likely year automatically — correct for recent boarding passes. If you scanned an older pass, tap **‹** or **›** to set the right year.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .presentationDetents([.fraction(0.38)])
            .presentationDragIndicator(.visible)
        }
    }

    private var yearDetailBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text("YEAR")
                    .font(.system(.caption, design: .monospaced, weight: .bold))
                    .tracking(3)
                    .foregroundStyle(.secondary)
                Button {
                    showYearInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 4) {
                Button {
                    adjustYear(-1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(primaryText)
                        .frame(width: 26, height: 26)
                        .background(panelStroke.opacity(0.8), in: Circle())
                }
                .buttonStyle(.plain)

                Text(String(currentFlightYear))
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(primaryText)
                    .monospacedDigit()

                Button {
                    adjustYear(1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(primaryText)
                        .frame(width: 26, height: 26)
                        .background(panelStroke.opacity(0.8), in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var barcodeCard: some View {
        BarcodeCard(record: record)
    }

    private var customizePanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Customize", systemImage: "paintpalette")
                .font(.headline.weight(.semibold))
                .foregroundStyle(primaryText)

            HStack {
                Text("Foreground")
                    .font(.subheadline)
                    .foregroundStyle(primaryText)
                Spacer()
                ColorPicker("", selection: $passForegroundColor, supportsOpacity: false)
                    .labelsHidden()
            }

            HStack {
                Text("Background")
                    .font(.subheadline)
                    .foregroundStyle(primaryText)
                Spacer()
                ColorPicker("", selection: $passBackgroundColor, supportsOpacity: false)
                    .labelsHidden()
            }

            HStack {
                Text("Label")
                    .font(.subheadline)
                    .foregroundStyle(primaryText)
                Spacer()
                ColorPicker("", selection: $passLabelColor, supportsOpacity: false)
                    .labelsHidden()
            }

            if #available(iOS 26, *) {
                Toggle(isOn: $passSemanticsEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Semantics")
                            .font(.subheadline)
                            .foregroundStyle(primaryText)
                        Text("Enable live Apple tracking")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Button {
                Haptics.tap()
                showFieldsEditor = true
            } label: {
                HStack {
                    Label("Customize pass fields", systemImage: "list.bullet.rectangle")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(passSemanticsEnabled ? .secondary : primaryText)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
            .disabled(passSemanticsEnabled)

        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(panelBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(panelStroke, lineWidth: 1)
        }
    }

    private var walletTimingPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Lock Screen Timing", systemImage: "lock.iphone")
                .font(.headline.weight(.semibold))
                .foregroundStyle(primaryText)

            Text("We'll try to detect the departure time from your flight number automatically. You can override it here — this determines when the boarding pass is automatically shown on your lock screen.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Departure time")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(primaryText)
                    if departureTimeOverride != nil {
                        Text("MANUAL OVERRIDE")
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(.orange.opacity(0.14), in: Capsule())
                    } else {
                        Text("Auto-detected")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    DatePicker("", selection: departureTimeBinding, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .datePickerStyle(.compact)

                    if departureTimeOverride != nil {
                        Button("Reset to auto") {
                            Haptics.tap()
                            departureTimeOverride = nil
                        }
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.orange)
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(panelBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(panelStroke, lineWidth: 1)
        }
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

            await Action_addPass.presentForRecord(
                record,
                departureTime: departureTimeOverride,
                foregroundColor: passForegroundColor.passKitRgbString,
                backgroundColor: passBackgroundColor.passKitRgbString,
                labelColor: passLabelColor.passKitRgbString,
                semantics: passSemanticsEnabled,
                logoText: passFieldsConfig.logoText,
                fieldsJSON: passFieldsConfig.jsonString(for: record, departureTimeOverride: departureTimeOverride)
            )
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

            Text(Action_addPass.requestDebugDescription(
                for: record,
                departureTime: departureTimeOverride,
                foregroundColor: passForegroundColor.passKitRgbString,
                backgroundColor: passBackgroundColor.passKitRgbString,
                labelColor: passLabelColor.passKitRgbString,
                semantics: passSemanticsEnabled,
                logoText: passFieldsConfig.logoText,
                fieldsJSON: passFieldsConfig.jsonString(for: record, departureTimeOverride: departureTimeOverride)
            ))
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

    private var passFieldsConfig: PassFieldsConfig {
        guard let data = passFieldsConfigJSON.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(PassFieldsConfig.self, from: data) else {
            return .default
        }
        return decoded
    }

    private var passFieldsConfigBinding: Binding<PassFieldsConfig> {
        Binding(
            get: { passFieldsConfig },
            set: { newValue in
                if let data = try? JSONEncoder().encode(newValue),
                   let json = String(data: data, encoding: .utf8) {
                    passFieldsConfigJSON = json
                }
            }
        )
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

    private var departureTimeBinding: Binding<Date> {
        Binding(
            get: { departureTimeOverride ?? (record.flightDate == .distantPast ? .now : record.flightDate) },
            set: { departureTimeOverride = $0 }
        )
    }

    private var currentFlightYear: Int {
        if record.flightDateYear > 0 { return record.flightDateYear }
        let date = record.flightDate
        guard date != .distantPast else { return Calendar.current.component(.year, from: .now) }
        return Calendar.current.component(.year, from: date)
    }

    private func adjustYear(_ delta: Int) {
        Haptics.tap()
        let newYear = currentFlightYear + delta
        guard newYear >= 2000, newYear <= 2100 else { return }
        BoardingPassStore.shared.updateFlightYear(newYear, for: record)
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

extension Color {
    var passKitRgbString: String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let r = Int((red * 255).rounded())
        let g = Int((green * 255).rounded())
        let b = Int((blue * 255).rounded())
        return "rgb(\(r),\(g),\(b))"
    }
}
