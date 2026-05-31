//
//  BarcodeCard.swift
//  BoardingPassScanner2
//

import SwiftUI

struct BarcodeCard: View {
    let record: BoardingPassRecord

    @AppStorage("showBarcodeText")   private var showBarcodeText   = true
    @AppStorage("showSeatOnBarcode") private var showSeatOnBarcode = true

    private var formattedSeat: String {
        record.seatNumber.replacingOccurrences(of: "^0+(?=\\d)", with: "", options: .regularExpression)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                Text(displayValue(record.name))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Spacer()

                if showSeatOnBarcode {
                    Text(formattedSeat.isEmpty ? (record.type.isEmpty ? "CODE" : record.type.uppercased()) : formattedSeat.uppercased())
                        .font(.system(.caption, design: .monospaced, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .frame(height: 34)
                        .background(.black, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }

            Color.clear
                .frame(maxWidth: .infinity, minHeight: 132)
                .overlay {
                    SxView_BarCode(
                        barCodeType: record.type,
                        barcodeText: record.text,
                        foregroundColor: .black,
                        backgroundColor: .white
                    )
                }
                .clipped()

            if showBarcodeText {
                Text(record.text)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.black.opacity(0.58))
                    .lineLimit(2)
                    .truncationMode(.middle)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func displayValue(_ value: String) -> String {
        value.isEmpty ? "--" : value
    }
}
