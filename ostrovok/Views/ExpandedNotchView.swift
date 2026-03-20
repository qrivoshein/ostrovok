import SwiftUI

struct ExpandedNotchView: View {
    var viewModel: NotchViewModel

    var body: some View {
        NowPlayingWidget(viewModel: viewModel)
            .padding(.horizontal, 18)
            .padding(.top, viewModel.notchSize.height + 8)
            .padding(.bottom, 16)
    }
}
