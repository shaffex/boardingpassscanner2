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

    @State private var showDecodedSheet = false
    @State private var showDeleteAlert = false
    @State private var showRawData = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 26) {
                    BoardingPassCard(record: record)
                    tripDetails
                    barcodeCard
                    walletButton
                    actionButtons
                    rawDataPanel
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 34)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showDecodedSheet = true
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(.white.opacity(0.1), in: Circle())
                        .overlay {
                            Circle().stroke(.white.opacity(0.12), lineWidth: 1)
                        }
                }
            }
        }
        .alert("Warning", isPresented: $showDeleteAlert) {
            Button("No", role: .cancel) {}
            Button("Yes", role: .destructive) {
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
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
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
                    Text(boardingPassName)
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
        AddToWalletButton(addPassButtonStyle: .black) {
            Action_addPass.presentForRecord(record)
        }
        .frame(maxWidth: .infinity, minHeight: 56, maxHeight: 56)
        .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var actionButtons: some View {
        HStack(spacing: 14) {
            ShareLink(item: record.text) {
                Label("Share", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(DetailActionButtonStyle())

            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(DetailActionButtonStyle(foregroundColor: .red))
        }
    }

    private var rawDataPanel: some View {
        DisclosureGroup(isExpanded: $showRawData) {
            Text(record.text)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .padding(.top, 12)
        } label: {
            Label("Raw IATA BCBP data", systemImage: "info.circle")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
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

    private var passengerInitial: String {
        String(record.passengerGivenName.prefix(1))
    }

    private var boardingPassName: String {
        [record.passengerSurname, passengerInitial]
            .filter { !$0.isEmpty }
            .joined(separator: "/")
    }

    private func detailBlock(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(.caption, design: .monospaced, weight: .bold))
                .tracking(3)
                .foregroundStyle(.secondary)
            Text(displayValue(value))
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private func displayValue(_ value: String) -> String {
        value.isEmpty ? "--" : value
    }
}

private struct DetailActionButtonStyle: ButtonStyle {
    var foregroundColor: Color = .white

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(foregroundColor)
            .frame(height: 58)
            .background(.white.opacity(configuration.isPressed ? 0.16 : 0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            }
    }
}

