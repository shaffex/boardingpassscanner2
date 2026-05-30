//
//  PassFieldsEditorView.swift
//  BoardingPassScanner2
//

import SwiftUI
internal import PassKit

// MARK: - Main View

struct PassFieldsEditorView: View {
    @Binding var config: PassFieldsConfig
    let record: BoardingPassRecord
    let foregroundColor: Color
    let backgroundColor: Color
    let labelColor: Color
    let semantics: Bool
    var departureTimeOverride: Date? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var logoText: String
    @State private var headerFields: [PassFieldEntry]
    @State private var primaryFields: [PassFieldEntry]
    @State private var secondaryFields: [PassFieldEntry]
    @State private var auxiliaryFields: [PassFieldEntry]
    @State private var backFields: [PassFieldEntry]
    @State private var isAddingToWallet = false
    @State private var showWalletSpinner = false

    init(
        config: Binding<PassFieldsConfig>,
        record: BoardingPassRecord,
        foregroundColor: Color = .white,
        backgroundColor: Color = Color(red: 0.10, green: 0.22, blue: 0.45),
        labelColor: Color = Color(red: 0.85, green: 0.88, blue: 0.95),
        semantics: Bool = false,
        departureTimeOverride: Date? = nil
    ) {
        self._config = config
        self.record = record
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
        self.labelColor = labelColor
        self.semantics = semantics
        self.departureTimeOverride = departureTimeOverride
        let storedLogo = config.wrappedValue.logoText
        let fallbackLogo = record.airlineName.isEmpty ? record.operatingCarrier : record.airlineName
        self._logoText = State(initialValue: storedLogo.isEmpty ? fallbackLogo : storedLogo)
        self._headerFields    = State(initialValue: Self.visible(config.wrappedValue.headerFields))
        self._primaryFields   = State(initialValue: Self.editablePrimary(config.wrappedValue, record: record))
        self._secondaryFields = State(initialValue: Self.visible(config.wrappedValue.secondaryFields))
        self._auxiliaryFields = State(initialValue: Self.visible(config.wrappedValue.auxiliaryFields))
        self._backFields      = State(initialValue: Self.visible(config.wrappedValue.backFields))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    passCard
                    backCard
                    resetButton
                    walletButton
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Pass layout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onChange(of: logoText)        { _, _ in save() }
        .onChange(of: primaryFields)   { _, _ in save() }
        .onChange(of: headerFields)    { _, _ in save() }
        .onChange(of: auxiliaryFields) { _, _ in save() }
        .onChange(of: secondaryFields) { _, _ in save() }
        .onChange(of: backFields)      { _, _ in save() }
        .onAppear {
            removeDuplicateFieldsFromEditor()
            save()
        }
    }

    // MARK: - Pass Card

    private var passCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Logo + header zone
            HStack(alignment: .center, spacing: 10) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(.white.opacity(0.25))
                    .frame(width: 44, height: 32)
                    .overlay {
                        Image(systemName: "airplane")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                    }
                VStack(alignment: .leading, spacing: 1) {
                    TextField("Airline", text: $logoText)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .tint(.white)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .lineLimit(1)
                    Text("Boarding pass")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.45))
                }
                Spacer(minLength: 8)
                headerSlot.frame(maxWidth: 120)
            }

            Divider().overlay(.white.opacity(0.18))

            // Primary — editable city name, read-only airport code badge
            zoneBox(title: "PRIMARY", tint: .cyan) {
                HStack(alignment: .center, spacing: 10) {
                    if primaryFields.count > 0 {
                        primaryChip(entry: $primaryFields[0], airportCode: record.fromAirport)
                    }
                    Image(systemName: "airplane")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.5))
                    if primaryFields.count > 1 {
                        primaryChip(entry: $primaryFields[1], airportCode: record.toAirport)
                    }
                }
            }

            // Auxiliary — editable + draggable
            zoneBox(title: "AUXILIARY", tint: .green) {
                ChipRow(
                    fields: $auxiliaryFields,
                    record: record,
                    tint: .green,
                    capacity: PassZoneCapacity.auxiliary,
                    availableAttributesForNewField: availableAttributesForNewField,
                    availableAttributesForEntry: availableAttributes(for:),
                    onDrop: { entry, idx in drop(entry, to: .auxiliary, at: idx) },
                    onDelete: { id in removeField(id, from: .auxiliary) },
                    onAdd: { attr in auxiliaryFields.append(Self.newEntry(attr)) },
                    departureTimeOverride: departureTimeOverride
                )
            }

            // Secondary — editable + draggable
            zoneBox(title: "SECONDARY", tint: .orange) {
                ChipRow(
                    fields: $secondaryFields,
                    record: record,
                    tint: .orange,
                    capacity: PassZoneCapacity.secondary,
                    availableAttributesForNewField: availableAttributesForNewField,
                    availableAttributesForEntry: availableAttributes(for:),
                    onDrop: { entry, idx in drop(entry, to: .secondary, at: idx) },
                    onDelete: { id in removeField(id, from: .secondary) },
                    onAdd: { attr in secondaryFields.append(Self.newEntry(attr)) },
                    departureTimeOverride: departureTimeOverride
                )
            }
        }
        .padding(16)
        .background(Color(red: 0.08, green: 0.23, blue: 0.44), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(alignment: .leading)  { notch(x: -9) }
        .overlay(alignment: .trailing) { notch(x:  9) }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 20, x: 0, y: 10)
    }

    @ViewBuilder
    private var headerSlot: some View {
        if headerFields.isEmpty {
            Menu {
                ForEach(PassFieldAttribute.menuSources) { attr in
                    Button(attr.title) { Haptics.tap(); headerFields.append(Self.newEntry(attr)) }
                        .disabled(!availableAttributesForNewField.contains(attr))
                }
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "plus").font(.subheadline.weight(.semibold))
                    Text("Add").font(.caption2.weight(.semibold))
                }
                .foregroundStyle(.white.opacity(0.65))
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .strokeBorder(.white.opacity(0.25), style: StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                }
            }
        } else {
            ForEach($headerFields) { $entry in
                EditableChip(
                    entry: $entry,
                    record: record,
                    tint: .blue,
                    availableAttributes: availableAttributes(for: entry),
                    departureTimeOverride: departureTimeOverride,
                    onDelete: { removeField(entry.id, from: .header) }
                )
                    .draggable(entry)
                    .dropDestination(for: PassFieldEntry.self) { items, _ in
                        guard let dropped = items.first else { return false }
                        return drop(dropped, to: .header, at: 0)
                    }
            }
        }
    }

    private func zoneBox<C: View>(title: String, tint: Color, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Circle().fill(tint).frame(width: 7, height: 7)
                Text(title).font(.caption2.weight(.bold)).foregroundStyle(.white.opacity(0.75))
                Spacer()
            }
            content()
        }
        .padding(10)
        .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(tint.opacity(0.35), lineWidth: 1)
        }
    }

    private func primaryChip(entry: Binding<PassFieldEntry>, airportCode: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            TextField("Label", text: entry.label)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.62))
                .tint(.white)
                .textFieldStyle(.plain)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .lineLimit(1)
            if !airportCode.isEmpty {
                Text(airportCode)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(.white.opacity(0.45))
                    .lineLimit(1)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 78, alignment: .leading)
        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
    }

    private func notch(x: CGFloat) -> some View {
        VStack {
            Spacer()
            Circle()
                .fill(Color(uiColor: .systemGroupedBackground))
                .frame(width: 18, height: 18)
                .offset(x: x)
            Spacer()
        }
    }

    private var airlineTitle: String {
        if !record.airlineName.isEmpty { return record.airlineName }
        if !record.operatingCarrier.isEmpty { return record.operatingCarrier }
        return "Airline"
    }

    // MARK: - Back Card

    private var backCard: some View {
        VStack(spacing: 0) {
            HStack {
                Label {
                    Text("Back of pass").font(.subheadline.weight(.semibold))
                } icon: {
                    Image(systemName: "rectangle.stack").foregroundStyle(.purple)
                }
                Spacer()
                backAddMenu
            }
            .padding(14)

            ForEach(Array(backFields.enumerated()), id: \.element.id) { index, entry in
                Divider().padding(.horizontal, 14)
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.label.isEmpty ? entry.attribute.title : entry.label)
                            .font(.subheadline.weight(.semibold))
                        Text(fieldValue(entry))
                            .font(.callout).foregroundStyle(.secondary).lineLimit(1)
                    }
                    Spacer()
                    Button(role: .destructive) {
                        Haptics.warning()
                        backFields.removeAll { $0.id == entry.id }
                        save()
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(.red.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
        }
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    @ViewBuilder
    private var backAddMenu: some View {
        Menu {
            ForEach(PassFieldAttribute.menuSources) { attr in
                Button(attr.title) {
                    Haptics.tap()
                    backFields.append(Self.newEntry(attr))
                }
                .disabled(!availableAttributesForNewField.contains(attr))
            }
        } label: {
            Label("Add", systemImage: "plus.circle").font(.subheadline.weight(.medium))
        }
    }

    // MARK: - Reset

    private var resetButton: some View {
        Button(role: .destructive) {
            Haptics.warning()
            withAnimation {
                logoText        = record.airlineName.isEmpty ? record.operatingCarrier : record.airlineName
                headerFields    = Self.visible(PassFieldsConfig.default.headerFields)
                primaryFields   = Self.editablePrimary(.default, record: record)
                auxiliaryFields = Self.visible(PassFieldsConfig.default.auxiliaryFields)
                secondaryFields = Self.visible(PassFieldsConfig.default.secondaryFields)
                backFields      = Self.visible(PassFieldsConfig.default.backFields)
            }
            save()
        } label: {
            Label("Reset to defaults", systemImage: "arrow.uturn.backward")
                .frame(maxWidth: .infinity).padding(14)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .foregroundStyle(.red)
    }

    // MARK: - Wallet Button

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
        save()
        isAddingToWallet = true
        showWalletSpinner = false
        Task {
            let spinnerTask = Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                guard !Task.isCancelled else { return }
                await MainActor.run { showWalletSpinner = true }
            }
            await Action_addPass.presentCustomForRecord(
                record,
                departureTime: departureTimeOverride,
                foregroundColor: foregroundColor.passKitRgbString,
                backgroundColor: backgroundColor.passKitRgbString,
                labelColor: labelColor.passKitRgbString,
                semantics: semantics,
                logoText: config.logoText,
                fieldsJSON: config.jsonString(for: record, departureTimeOverride: departureTimeOverride)
            )
            spinnerTask.cancel()
            await MainActor.run {
                isAddingToWallet = false
                showWalletSpinner = false
            }
        }
    }

    // MARK: - Drop Handler

    private enum DropZone { case header, auxiliary, secondary }

    @discardableResult
    private func drop(_ entry: PassFieldEntry, to zone: DropZone, at target: Int) -> Bool {
        let id = entry.id

        // Determine source zone before touching anything
        let srcZone: DropZone?
        let srcIdx: Int?
        if let i = headerFields.firstIndex(where: { $0.id == id }) {
            srcZone = .header;    srcIdx = i
        } else if let i = auxiliaryFields.firstIndex(where: { $0.id == id }) {
            srcZone = .auxiliary; srcIdx = i
        } else if let i = secondaryFields.firstIndex(where: { $0.id == id }) {
            srcZone = .secondary; srcIdx = i
        } else {
            srcZone = nil; srcIdx = nil
        }

        // Capacity check before any mutation (cross-zone adds 1 to target count)
        let capacity: Int
        switch zone {
        case .header:    capacity = PassZoneCapacity.header
        case .auxiliary: capacity = PassZoneCapacity.auxiliary
        case .secondary: capacity = PassZoneCapacity.secondary
        }
        let targetCount: Int
        switch zone {
        case .header:    targetCount = headerFields.count
        case .auxiliary: targetCount = auxiliaryFields.count
        case .secondary: targetCount = secondaryFields.count
        }
        let crossZone = srcZone != zone
        guard !crossZone || targetCount < capacity else { return false }

        // Now remove from source
        switch srcZone {
        case .header:    headerFields.remove(at: srcIdx!)
        case .auxiliary: auxiliaryFields.remove(at: srcIdx!)
        case .secondary: secondaryFields.remove(at: srcIdx!)
        case nil: break
        }

        // Adjust index when reordering within same zone
        var insertAt = target
        if let si = srcIdx, srcZone == zone, si < target { insertAt = max(0, target - 1) }

        switch zone {
        case .header:
            headerFields.insert(entry, at: min(insertAt, headerFields.count))
        case .auxiliary:
            auxiliaryFields.insert(entry, at: min(insertAt, auxiliaryFields.count))
        case .secondary:
            secondaryFields.insert(entry, at: min(insertAt, secondaryFields.count))
        }

        save()
        return true
    }

    private func removeField(_ id: UUID, from zone: DropZone) {
        Haptics.warning()
        switch zone {
        case .header:    headerFields.removeAll    { $0.id == id }
        case .auxiliary: auxiliaryFields.removeAll { $0.id == id }
        case .secondary: secondaryFields.removeAll { $0.id == id }
        }
        save()
    }

    // MARK: - Persistence

    private func save() {
        var usedAttributes = Set<PassFieldAttribute>()
        let uniquePrimaryFields = Self.unique(
            Self.capped(primaryFields, capacity: PassZoneCapacity.primary),
            usedAttributes: &usedAttributes
        )

        config = PassFieldsConfig(
            logoText: logoText,
            headerFields: Self.unique(
                Self.capped(headerFields, capacity: PassZoneCapacity.header),
                usedAttributes: &usedAttributes
            ),
            primaryFields: uniquePrimaryFields,
            secondaryFields: Self.unique(
                Self.capped(secondaryFields, capacity: PassZoneCapacity.secondary),
                usedAttributes: &usedAttributes
            ),
            auxiliaryFields: Self.unique(
                Self.capped(auxiliaryFields, capacity: PassZoneCapacity.auxiliary),
                usedAttributes: &usedAttributes
            ),
            backFields: Self.unique(
                backFields.map { var v = $0; v.isVisible = true; return v },
                usedAttributes: &usedAttributes
            )
        )
    }

    private func removeDuplicateFieldsFromEditor() {
        var usedAttributes = Set<PassFieldAttribute>()
        headerFields = Self.unique(
            Self.capped(headerFields, capacity: PassZoneCapacity.header),
            usedAttributes: &usedAttributes
        )
        secondaryFields = Self.unique(
            Self.capped(secondaryFields, capacity: PassZoneCapacity.secondary),
            usedAttributes: &usedAttributes
        )
        auxiliaryFields = Self.unique(
            Self.capped(auxiliaryFields, capacity: PassZoneCapacity.auxiliary),
            usedAttributes: &usedAttributes
        )
        backFields = Self.unique(
            backFields.map { var v = $0; v.isVisible = true; return v },
            usedAttributes: &usedAttributes
        )
    }

    private static func capped(_ arr: [PassFieldEntry], capacity: Int) -> [PassFieldEntry] {
        Array(arr.prefix(capacity)).map { var v = $0; v.isVisible = true; return v }
    }

    private static func unique(
        _ fields: [PassFieldEntry],
        usedAttributes: inout Set<PassFieldAttribute>
    ) -> [PassFieldEntry] {
        fields.compactMap { entry in
            guard entry.isVisible, entry.attribute != .none else { return nil }
            if entry.attribute == .custom { return entry }
            guard usedAttributes.insert(entry.attribute).inserted else { return nil }
            return entry
        }
    }

    private static func visible(_ arr: [PassFieldEntry]) -> [PassFieldEntry] {
        arr.filter { $0.isVisible && $0.attribute != .none }
    }

    private static func editablePrimary(_ cfg: PassFieldsConfig, record: BoardingPassRecord) -> [PassFieldEntry] {
        let stored = cfg.primaryFields.filter { $0.isVisible && $0.attribute != .none }
        if stored.count == PassZoneCapacity.primary { return stored }
        let fromCity = record.fromAirportCity.isEmpty ? record.fromAirport : record.fromAirportCity
        let toCity   = record.toAirportCity.isEmpty   ? record.toAirport   : record.toAirportCity
        return [
            PassFieldEntry(attribute: .custom, label: "FROM", customValue: fromCity),
            PassFieldEntry(attribute: .custom, label: "TO",   customValue: toCity)
        ]
    }

    private static func newEntry(_ attribute: PassFieldAttribute) -> PassFieldEntry {
        attribute == .custom ? PassFieldEntry(attribute: .custom, label: "NOTE") : PassFieldEntry(attribute: attribute)
    }

    private var availableAttributesForNewField: [PassFieldAttribute] {
        PassFieldAttribute.menuSources.filter { !usedAttributes.contains($0) }
    }

    private func availableAttributes(for entry: PassFieldEntry) -> [PassFieldAttribute] {
        PassFieldAttribute.menuSources.filter { $0 == entry.attribute || !usedAttributes(excluding: entry.id).contains($0) }
    }

    private var usedAttributes: Set<PassFieldAttribute> {
        usedAttributes(excluding: nil)
    }

    private func usedAttributes(excluding excludedID: UUID?) -> Set<PassFieldAttribute> {
        Set(allVisibleFields.compactMap { entry in
            guard entry.id != excludedID, entry.attribute != .none, entry.attribute != .custom else { return nil }
            return entry.attribute
        })
    }

    private var allVisibleFields: [PassFieldEntry] {
        (headerFields + primaryFields + secondaryFields + auxiliaryFields + backFields)
            .filter { $0.isVisible && $0.attribute != .none }
    }

    private func fieldValue(_ entry: PassFieldEntry) -> String {
        let json = PassFieldsConfig(headerFields: [], primaryFields: [entry], secondaryFields: [], auxiliaryFields: [], backFields: []).resolved(for: record, departureTimeOverride: departureTimeOverride)
        if let arr = json["primaryFields"] as? [[String: String]], let v = arr.first?["value"], !v.isEmpty { return v }
        return entry.attribute == .custom ? (entry.customValue.isEmpty ? "--" : entry.customValue) : "--"
    }
}

// MARK: - Chip Row

private struct ChipRow: View {
    @Binding var fields: [PassFieldEntry]
    let record: BoardingPassRecord
    let tint: Color
    let capacity: Int
    let availableAttributesForNewField: [PassFieldAttribute]
    let availableAttributesForEntry: (PassFieldEntry) -> [PassFieldAttribute]
    let onDrop: (PassFieldEntry, Int) -> Bool
    let onDelete: (UUID) -> Void
    let onAdd: (PassFieldAttribute) -> Void
    var departureTimeOverride: Date? = nil

    var body: some View {
        GeometryReader { geo in
            let w = slotW(geo.size.width)
            HStack(spacing: 8) {
                ForEach($fields) { $entry in
                    let idx = fields.firstIndex(where: { $0.id == entry.id }) ?? 0
                    EditableChip(
                        entry: $entry,
                        record: record,
                        tint: tint,
                        availableAttributes: availableAttributesForEntry(entry),
                        departureTimeOverride: departureTimeOverride,
                        onDelete: { onDelete(entry.id) }
                    )
                        .frame(width: w, height: 66)
                        .draggable(entry)
                        .dropDestination(for: PassFieldEntry.self) { items, _ in
                            guard let dropped = items.first else { return false }
                            return onDrop(dropped, idx)
                        }
                }
                if fields.count < capacity {
                    Menu {
                        ForEach(PassFieldAttribute.menuSources) { attr in
                            Button(attr.title) { Haptics.tap(); onAdd(attr) }
                                .disabled(!availableAttributesForNewField.contains(attr))
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "plus").font(.subheadline.weight(.semibold))
                            Text("Add").font(.caption2.weight(.semibold))
                        }
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(width: w, height: 66)
                        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .strokeBorder(.white.opacity(0.22), style: StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                        }
                    }
                    .dropDestination(for: PassFieldEntry.self) { items, _ in
                        guard let dropped = items.first else { return false }
                        return onDrop(dropped, fields.count)
                    }
                }
            }
        }
        .frame(height: 66)
        .dropDestination(for: PassFieldEntry.self) { items, _ in
            guard let dropped = items.first else { return false }
            return onDrop(dropped, fields.count)
        }
    }

    private func slotW(_ total: CGFloat) -> CGFloat {
        (total - 8 * CGFloat(capacity - 1)) / CGFloat(capacity)
    }
}

// MARK: - Editable Chip

private struct EditableChip: View {
    @Binding var entry: PassFieldEntry
    let record: BoardingPassRecord
    let tint: Color
    let availableAttributes: [PassFieldAttribute]
    var departureTimeOverride: Date? = nil
    var onDelete: (() -> Void)? = nil

    @FocusState private var labelFocused: Bool
    @FocusState private var valueFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // ── Label — always a TextField so iOS tap-to-focus works natively ──
            TextField("Label", text: $entry.label)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(labelFocused ? 0.9 : 0.62))
                .tint(.white)
                .textFieldStyle(.plain)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .onSubmit { labelFocused = false }
                .lineLimit(1)
                .focused($labelFocused)

            // ── Value ──
            if entry.attribute == .custom {
                // Custom — always a TextField
                TextField(entry.customValue.isEmpty ? "Tap to type…" : "", text: $entry.customValue)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(entry.customValue.isEmpty ? .white.opacity(0.38) : .white)
                    .tint(.white)
                    .textFieldStyle(.plain)
                    .submitLabel(.done)
                    .onSubmit { valueFocused = false }
                    .lineLimit(1)
                    .focused($valueFocused)
            } else {
                // Data-backed — menu to swap the source attribute
                Menu {
                    ForEach(PassFieldAttribute.menuSources) { attr in
                        Button(attr.title) {
                            let oldLabel = entry.attribute.defaultLabel
                            entry.attribute = attr
                            if entry.label.isEmpty || entry.label == oldLabel {
                                entry.label = attr == .custom ? "NOTE" : attr.defaultLabel
                            }
                            entry.isVisible = true
                        }
                        .disabled(!availableAttributes.contains(attr))
                    }
                } label: {
                    Text(previewValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(
            (labelFocused || valueFocused ? tint : Color.white)
                .opacity(labelFocused || valueFocused ? 0.25 : 0.14),
            in: RoundedRectangle(cornerRadius: 9, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(
                    (labelFocused || valueFocused ? tint : Color.white)
                        .opacity(labelFocused || valueFocused ? 0.65 : 0.2),
                    lineWidth: labelFocused || valueFocused ? 1.5 : 1
                )
        }
        .overlay(alignment: .topTrailing) {
            if let onDelete {
                Button {
                    Haptics.warning()
                    onDelete()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .black.opacity(0.55))
                        .font(.system(size: 15, weight: .bold))
                }
                .buttonStyle(.plain)
                .offset(x: 5, y: -5)
            }
        }
        .animation(.spring(response: 0.2), value: labelFocused)
        .animation(.spring(response: 0.2), value: valueFocused)
        .onAppear { entry.isVisible = true }
    }

    private var previewValue: String {
        let json = PassFieldsConfig(headerFields: [], primaryFields: [entry], secondaryFields: [], auxiliaryFields: [], backFields: []).resolved(for: record, departureTimeOverride: departureTimeOverride)
        if let arr = json["primaryFields"] as? [[String: String]], let v = arr.first?["value"], !v.isEmpty { return v }
        return "--"
    }
}

// MARK: - Shared

private extension PassFieldAttribute {
    // Custom first, then all other sources alphabetically by display order
    static var menuSources: [PassFieldAttribute] {
        [.custom] + allCases.filter { $0 != .none && $0 != .custom && $0 != .flightCode && $0 != .passengerSurname && $0 != .passengerGivenName }
    }

    static var availableFieldSources: [PassFieldAttribute] {
        allCases.filter { $0 != .none && $0 != .flightCode && $0 != .passengerSurname && $0 != .passengerGivenName }
    }
}
