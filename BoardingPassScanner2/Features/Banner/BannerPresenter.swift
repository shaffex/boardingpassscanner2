//
//  BannerPresenter.swift
//  BoardingPassScanner2
//
//  Created by OpenAI on 27/05/2026.
//

import SwiftUI
import Combine

struct AppBanner: Identifiable, Equatable {
    enum Style: String {
        case success
        case info
        case error

        var iconName: String {
            switch self {
            case .success:
                "checkmark.circle.fill"
            case .info:
                "info.circle.fill"
            case .error:
                "exclamationmark.triangle.fill"
            }
        }

        var tint: Color {
            switch self {
            case .success:
                Color.green
            case .info:
                Color.blue
            case .error:
                Color.red
            }
        }
    }

    let id = UUID()
    let style: Style
    let title: String
    let message: String
}

@MainActor
final class BannerPresenter: ObservableObject {
    static let shared = BannerPresenter()

    @Published private(set) var banner: AppBanner?
    private var hideTask: Task<Void, Never>?

    private init() {}

    func show(style: AppBanner.Style, title: String, message: String, duration: TimeInterval = 3.0) {
        hideTask?.cancel()

        withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
            banner = AppBanner(style: style, title: title, message: message)
        }

        hideTask = Task { [weak self] in
            let nanoseconds = UInt64(duration * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanoseconds)
            guard !Task.isCancelled else { return }
            self?.hide()
        }
    }

    func hide() {
        hideTask?.cancel()
        hideTask = nil

        withAnimation(.spring(response: 0.32, dampingFraction: 0.92)) {
            banner = nil
        }
    }
}

struct AppBannerOverlay: View {
    @ObservedObject var presenter: BannerPresenter

    var body: some View {
        VStack {
            if let banner = presenter.banner {
                AppBannerView(banner: banner) {
                    presenter.hide()
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(1)
            }

            Spacer(minLength: 0)
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.86), value: presenter.banner)
        .allowsHitTesting(presenter.banner != nil)
    }
}

private struct AppBannerView: View {
    @Environment(\.colorScheme) private var colorScheme

    let banner: AppBanner
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: banner.style.iconName)
                .font(.system(size: 23, weight: .semibold))
                .foregroundStyle(banner.style.tint)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(banner.title)
                    .font(.headline)
                    .foregroundStyle(primaryText)
                    .lineLimit(1)

                Text(banner.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .background(closeButtonBackground, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 14)
        .background(background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.32 : 0.12), radius: 18, x: 0, y: 10)
    }

    private var primaryText: Color {
        colorScheme == .dark ? .white : .black
    }

    private var background: Color {
        colorScheme == .dark ? Color(uiColor: .secondarySystemBackground) : .white
    }

    private var closeButtonBackground: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05)
    }

    private var borderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08)
    }
}
