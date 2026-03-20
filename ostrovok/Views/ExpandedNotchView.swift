import SwiftUI

struct ExpandedNotchView: View {
    var viewModel: NotchViewModel

    var body: some View {
        HStack(spacing: 12) {
            NowPlayingWidget(viewModel: viewModel)
        }
        .padding(.horizontal, 20)
        .padding(.top, viewModel.notchSize.height + 4)
        .padding(.bottom, 12)
    }
}
