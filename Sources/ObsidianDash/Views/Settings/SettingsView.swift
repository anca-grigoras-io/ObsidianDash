import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState

    private var svc: VaultService { appState.vaultService }

    var body: some View {
        Form {
            Section("Vault") {
                if let url = svc.vaultURL {
                    LabeledContent("Location") {
                        HStack {
                            Image(systemName: "folder.fill").foregroundStyle(.purple)
                            Text(url.lastPathComponent)
                                .lineLimit(1)
                        }
                    }

                    LabeledContent("Notes") {
                        Text("\(svc.notes.count)")
                            .foregroundStyle(.secondary)
                    }

                    if let date = svc.lastScanDate {
                        LabeledContent("Last Synced") {
                            Text(date.formatted(date: .abbreviated, time: .shortened))
                                .foregroundStyle(.secondary)
                        }
                    }

                    HStack {
                        Button("Change Vault…") {
                            Task { await svc.selectVault() }
                        }
                        Button("Refresh Now") {
                            Task { await svc.scanVault() }
                        }
                        .disabled(svc.isLoading)
                        if svc.isLoading {
                            ProgressView().controlSize(.small)
                        }
                    }
                    .buttonStyle(.borderless)
                } else {
                    Button("Select Vault…") {
                        Task { await svc.selectVault() }
                    }
                }
            }

            Section("About") {
                LabeledContent("Version", value: "1.0.0")
                LabeledContent("Built with", value: "SwiftUI + Swift Charts")
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 320)
        .navigationTitle("Settings")
    }
}
