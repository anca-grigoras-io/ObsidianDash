import SwiftUI

struct VaultOnboardingView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 36) {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 110, height: 110)
                    .shadow(color: .purple.opacity(0.4), radius: 20, y: 8)

                Image(systemName: "brain.head.profile")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 14) {
                Text("Welcome to ObsidianDash")
                    .font(.largeTitle.bold())

                Text("Connect your Obsidian vault to see beautiful dashboards of your notes, tasks, projects, and events — all in one place.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 420)
            }

            VStack(spacing: 12) {
                Button {
                    Task { await appState.vaultService.selectVault() }
                } label: {
                    Label("Select Obsidian Vault", systemImage: "folder.badge.plus")
                        .font(.headline)
                        .frame(width: 260)
                        .padding(.vertical, 2)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.purple)

                Text("Choose the root folder of your Obsidian vault")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}
