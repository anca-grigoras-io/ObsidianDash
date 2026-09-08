import SwiftUI

struct DashboardCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline.bold())
                    .foregroundStyle(color)
                Text(title)
                    .font(.headline)
                Spacer()
            }
            content()
        }
        .padding(16)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
    }
}
