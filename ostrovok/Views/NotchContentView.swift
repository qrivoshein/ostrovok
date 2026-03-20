import SwiftUI

struct NotchContentView: View {
    var viewModel: NotchViewModel

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                NotchShape(
                    width: viewModel.currentWidth,
                    height: viewModel.currentHeight
                )
                .fill(.black)
                .frame(
                    width: viewModel.currentWidth + 40,
                    height: viewModel.currentHeight
                )

                if viewModel.isExpanded {
                    ExpandedNotchView(viewModel: viewModel)
                        .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                } else {
                    CollapsedNotchView(viewModel: viewModel)
                        .transition(.opacity)
                }
            }
            .animation(
                .spring(response: 0.3, dampingFraction: 0.75),
                value: viewModel.state
            )

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
