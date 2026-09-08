import SwiftUI

struct StatTile: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.opacity(0.15))
                    .frame(width: 46, height: 46)
                Image(systemName: icon)
                    .font(.title3.bold())
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2.bold().monospacedDigit())
                    .contentTransition(.numericText())
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(14)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
    }
}
