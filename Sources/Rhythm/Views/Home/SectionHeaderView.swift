import SwiftUI

struct SectionHeaderView: View {
    let title: String
    var showAllAction: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)

            Spacer()

            if let showAllAction {
                Button(action: showAllAction) {
                    Text("Показать все")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.appAccentPink)
                }
            }
        }
        .padding(.horizontal, 16)
    }
}
