import SwiftUI

struct NoteRow: View {
    let note: Note

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "doc.text.fill")
                .font(.subheadline)
                .foregroundStyle(.purple.opacity(0.7))
                .frame(width: 18)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(note.title)
                    .font(.subheadline)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(note.modificationDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if note.openTaskCount > 0 {
                        Label("\(note.openTaskCount)", systemImage: "checkmark.circle")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }

                    ForEach(note.tags.prefix(2), id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(.purple.opacity(0.1))
                            .foregroundStyle(.purple)
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()
        }
    }
}
