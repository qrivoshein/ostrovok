import SwiftUI

struct ExpandedNotchView: View {
    var viewModel: NotchViewModel

    var body: some View {
        NowPlayingWidget(viewModel: viewModel)
            .padding(.horizontal, 16)
            .padding(.top, viewModel.notchSize.height + 6)
            .padding(.bottom, 14)
    }
}
