import SwiftUI

struct SortMenuButton: View {
    @Binding var sortOrder: WallpaperSortOrder

    var body: some View {
        Menu {
            ForEach(WallpaperSortOrder.allCases, id: \.self) { order in
                Button {
                    sortOrder = order
                } label: {
                    HStack {
                        Text(order.localizedName)
                        if sortOrder == order {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 10, weight: .medium))
                Text(L10n.sort)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(.white.opacity(0.45))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.white.opacity(0.05), in: Capsule())
            .overlay { Capsule().stroke(.white.opacity(0.06), lineWidth: 1) }
        }
        .menuStyle(.borderlessButton)
    }
}
