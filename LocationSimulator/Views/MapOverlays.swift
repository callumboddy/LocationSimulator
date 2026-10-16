//
//  MapOverlays.swift
//  LocationSimulator
//
//  Created by Callum Boddy on 02.04.26.
//

import SwiftUI

/// Spinner overlay shown during location changes.
struct SpinnerOverlay: View {
    let isVisible: Bool

    var body: some View {
        if isVisible {
            VStack {
                HStack {
                    Spacer()
                    ProgressView()
                        .controlSize(.small)
                        .padding(10)
                        .glassEffect(.regular, in: .rect(cornerRadius: 12))
                }
                Spacer()
            }
            .padding(10)
        }
    }
}

/// Movement controls overlay (direction ring + move button) in the lower-left.
struct MovementControlsOverlay: View {
    let isVisible: Bool
    let isHighlighted: Bool
    let onMove: () -> Void
    let onToggleAutoMove: () -> Void

    var body: some View {
        if isVisible {
            VStack {
                Spacer()
                HStack {
                    Button(action: onMove) {
                        Image(systemName: isHighlighted ? "location.fill" : "location")
                            .font(.title2)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.glass)
                    .onLongPressGesture {
                        onToggleAutoMove()
                    }
                    .padding(10)
                    Spacer()
                }
            }
        }
    }
}

/// Status bar overlay at the bottom showing distance and play/pause state.
struct StatusOverlay: View {
    let totalDistanceKM: Double
    let playPauseState: PlayPauseState
    let showError: Bool
    let onErrorTap: () -> Void

    enum PlayPauseState {
        case hidden
        case playing
        case paused
    }

    var body: some View {
        VStack {
            Spacer()
            HStack {
                HStack(spacing: 8) {
                    Text(String(format: "%.2f km", totalDistanceKM))
                        .font(.caption)
                        .monospacedDigit()

                    if playPauseState != .hidden {
                        Image(
                            systemName: playPauseState == .paused
                                ? "play.fill" : "pause.fill"
                        )
                        .foregroundStyle(.secondary)
                    }

                    if showError {
                        Button(action: onErrorTap) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.yellow)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .glassEffect(.regular, in: .capsule)

                Spacer()
            }
            .padding(.leading, 10)
            .padding(.bottom, 10)
        }
    }
}
